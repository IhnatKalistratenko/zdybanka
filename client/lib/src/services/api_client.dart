import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef ApiDelay = Future<void> Function(Duration duration);

class ApiException implements Exception {
  final String message;
  final String code;
  final Object? details;
  final int? statusCode;
  final String? requestId;
  final bool isRetryable;
  final Object? cause;

  const ApiException({
    required this.message,
    this.code = 'unknown',
    this.details,
    this.statusCode,
    this.requestId,
    this.isRetryable = false,
    this.cause,
  });

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}

class ApiError {
  final String error;
  final String? code;
  final Object? details;
  final String? requestId;
  const ApiError({
    required this.error,
    this.code,
    this.details,
    this.requestId,
  });
  factory ApiError.fromBody(String body) {
    try {
      final value = jsonDecode(body);
      if (value is Map) {
        return ApiError(
          error: value['error'] is String
              ? value['error'] as String
              : value['message'] is String
              ? value['message'] as String
              : 'Request failed.',
          code: value['code'] is String ? value['code'] : null,
          details: value['details'],
          requestId: value['requestId'] is String ? value['requestId'] : null,
        );
      }
    } catch (_) {
      /* malformed backend error: use a safe fallback */
    }
    return const ApiError(error: 'Request failed.');
  }
}

class ApiRequestOptions {
  final Duration? timeout;
  final Completer<void>? cancellation;
  final String? idempotencyKey;
  final bool idempotencySupported;
  final bool disableIdempotency;
  final bool retrySafe;
  const ApiRequestOptions({
    this.timeout,
    this.cancellation,
    this.idempotencyKey,
    this.idempotencySupported = false,
    this.disableIdempotency = false,
    this.retrySafe = false,
  });
}

class DegradedModeManager extends ChangeNotifier {
  DegradedModeManager({this.failureThreshold = 3});
  final int failureThreshold;
  int _failures = 0;
  bool _isDegraded = false;
  bool get isDegraded => _isDegraded;
  void recordFailure() {
    _failures++;
    if (_failures >= failureThreshold && !_isDegraded) {
      _isDegraded = true;
      notifyListeners();
    }
  }

  void recordSuccess() {
    _failures = 0;
    if (_isDegraded) {
      _isDegraded = false;
      notifyListeners();
    }
  }
}

class ApiClient {
  ApiClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
    this.maxRetries = 3,
    this.initialBackoff = const Duration(milliseconds: 500),
    this.maxBackoff = const Duration(seconds: 5),
    this.maxRetryAfter = const Duration(seconds: 30),
    ApiDelay? delay,
    DateTime Function()? now,
    Random? random,
    DegradedModeManager? degradedMode,
  }) : _client = client ?? http.Client(),
       _delay = delay ?? ((d) => Future<void>.delayed(d)),
       _now = now ?? DateTime.now,
       _random = random ?? Random.secure(),
       degradedMode = degradedMode ?? DegradedModeManager();

  final http.Client _client;
  final ApiDelay _delay;
  final DateTime Function() _now;
  final Random _random;
  final Duration timeout;
  final int maxRetries;
  final Duration initialBackoff, maxBackoff, maxRetryAfter;
  final DegradedModeManager degradedMode;
  final ValueNotifier<ApiException?> lastError = ValueNotifier(null);
  String? lastRequestId;
  bool _closed = false;

  void clearReportedError(ApiException error) {
    if (identical(lastError.value, error)) lastError.value = null;
  }

  dynamic decodeJson(String source, {String? requestId}) {
    try {
      return jsonDecode(source);
    } on FormatException catch (error) {
      final apiError = ApiException(
        message: 'The server returned invalid JSON.',
        code: 'invalid_json',
        requestId: requestId ?? lastRequestId,
        cause: error,
      );
      _publishError(apiError);
      throw apiError;
    }
  }

  Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    ApiRequestOptions options = const ApiRequestOptions(),
  }) => _send('GET', uri, headers: headers, options: options);
  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    ApiRequestOptions options = const ApiRequestOptions(),
  }) => _send(
    'POST',
    uri,
    headers: headers,
    body: body,
    encoding: encoding,
    options: options,
  );
  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    ApiRequestOptions options = const ApiRequestOptions(),
  }) => _send(
    'PUT',
    uri,
    headers: headers,
    body: body,
    encoding: encoding,
    options: options,
  );
  Future<http.Response> patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    ApiRequestOptions options = const ApiRequestOptions(),
  }) => _send(
    'PATCH',
    uri,
    headers: headers,
    body: body,
    encoding: encoding,
    options: options,
  );
  Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    ApiRequestOptions options = const ApiRequestOptions(),
  }) => _send(
    'DELETE',
    uri,
    headers: headers,
    body: body,
    encoding: encoding,
    options: options,
  );

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    required ApiRequestOptions options,
  }) async {
    if (_closed)
      throw const ApiException(
        message: 'HTTP client is closed.',
        code: 'closed',
      );
    final safeMethod = method == 'GET' || method == 'PUT' || method == 'DELETE';
    final key = method == 'POST' && !options.disableIdempotency
        ? (options.idempotencyKey ?? _uuid())
        : options.idempotencyKey;
    final canRetry =
        safeMethod ||
        options.retrySafe ||
        (method == 'POST' && key != null && options.idempotencySupported);
    final requestBody = body is String
        ? body
        : body is List<int>
        ? List<int>.from(body)
        : body;
    String? attemptId;
    for (var attempt = 0; ; attempt++) {
      _checkCancelled(options.cancellation, attemptId);
      attemptId = _uuid();
      lastRequestId = attemptId;
      final abort = Completer<void>();
      final timer = Timer(options.timeout ?? timeout, () {
        if (!abort.isCompleted) abort.complete();
      });
      final cancelSub = options.cancellation?.future.then((_) {
        if (!abort.isCompleted) abort.complete();
      });
      try {
        final request = http.AbortableRequest(
          method,
          uri,
          abortTrigger: abort.future,
        );
        request.headers.addAll(headers ?? {});
        request.headers['X-Request-Id'] = attemptId;
        if (key != null) request.headers['Idempotency-Key'] = key;
        if (requestBody != null) {
          request.body = requestBody is String
              ? requestBody
              : utf8.decode(requestBody as List<int>);
          if (encoding != null && requestBody is String)
            request.encoding = encoding;
        }
        final future = _client.send(request);
        // send() completes at headers; stream.toBytes() is deliberately inside the same deadline.
        final streamed = await future;
        final bytes = await streamed.stream.toBytes();
        if (options.cancellation?.isCompleted ?? false)
          throw ApiException(
            message: 'Request cancelled.',
            code: 'cancelled',
            requestId: attemptId,
          );
        if (abort.isCompleted)
          throw ApiException(
            message: 'The request timed out.',
            code: 'timeout',
            requestId: attemptId,
            isRetryable: true,
          );
        final response = http.Response.bytes(
          bytes,
          streamed.statusCode,
          request: streamed.request,
          headers: streamed.headers,
          isRedirect: streamed.isRedirect,
          persistentConnection: streamed.persistentConnection,
          reasonPhrase: streamed.reasonPhrase,
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          degradedMode.recordSuccess();
          lastRequestId =
              _header(response.headers, 'x-request-id') ?? attemptId;
          return response;
        }
        final retryable = _retryableStatus(response.statusCode);
        if (retryable && canRetry && attempt < maxRetries) {
          final serverDelay =
              response.statusCode == 429 || response.statusCode == 503
              ? _retryAfter(response.headers['retry-after'])
              : null;
          final wait = serverDelay ?? _backoff(attempt);
          await _wait(wait, options.cancellation, attemptId);
          continue;
        }
        final backend = ApiError.fromBody(response.body);
        final responseId =
            _header(response.headers, 'x-request-id') ??
            backend.requestId ??
            attemptId;
        lastRequestId = responseId;
        if (retryable) degradedMode.recordFailure();
        throw ApiException(
          message: backend.error,
          code: backend.code ?? _statusCode(response.statusCode),
          details: backend.details,
          statusCode: response.statusCode,
          requestId: responseId,
          isRetryable: retryable,
          cause: response.body,
        );
      } on ApiException catch (error) {
        _publishError(error);
        rethrow;
      } catch (error) {
        if (options.cancellation?.isCompleted ?? false)
          throw ApiException(
            message: 'Request cancelled.',
            code: 'cancelled',
            requestId: attemptId,
            cause: error,
          );
        final timedOut = abort.isCompleted;
        final retryable = true;
        if (retryable && canRetry && attempt < maxRetries) {
          await _wait(_backoff(attempt), options.cancellation, attemptId);
          continue;
        }
        degradedMode.recordFailure();
        final apiError = ApiException(
          message: timedOut
              ? 'The request timed out.'
              : 'Unable to reach the server.',
          code: timedOut ? 'timeout' : 'network_error',
          requestId: attemptId,
          isRetryable: true,
          cause: error,
        );
        _publishError(apiError);
        throw apiError;
      } finally {
        timer.cancel();
        if (cancelSub != null) unawaited(cancelSub);
      }
    }
  }

  void _publishError(ApiException error) {
    if (error.code != 'cancelled' && error.code != 'closed') {
      lastError.value = error;
    }
  }

  void _checkCancelled(Completer<void>? c, String? id) {
    if (c?.isCompleted ?? false)
      throw ApiException(
        message: 'Request cancelled.',
        code: 'cancelled',
        requestId: id,
      );
  }

  Future<void> _wait(
    Duration duration,
    Completer<void>? cancellation,
    String? id,
  ) async {
    _checkCancelled(cancellation, id);
    final done = Completer<void>();
    final timer = _delay(duration).then((_) {
      if (!done.isCompleted) done.complete();
    });
    if (cancellation != null)
      cancellation.future.then((_) {
        if (!done.isCompleted)
          done.completeError(
            ApiException(
              message: 'Request cancelled.',
              code: 'cancelled',
              requestId: id,
            ),
          );
      });
    try {
      await done.future;
    } finally {
      unawaited(timer);
    }
  }

  Duration _backoff(int attempt) {
    final base = initialBackoff.inMilliseconds * (1 << attempt);
    final clipped = min(base, maxBackoff.inMilliseconds);
    return Duration(
      milliseconds: min(
        maxBackoff.inMilliseconds,
        (clipped * (0.75 + _random.nextDouble() * 0.5)).round(),
      ),
    );
  }

  Duration? _retryAfter(String? value) {
    if (value == null) return null;
    Duration? parsed;
    final seconds = int.tryParse(value.trim());
    if (seconds != null && seconds >= 0) parsed = Duration(seconds: seconds);
    parsed ??= () {
      try {
        final date = _parseHttpDate(value);
        if (date == null) return null;
        final difference = date.difference(_now().toUtc());
        return difference.isNegative ? Duration.zero : difference;
      } catch (_) {
        return null;
      }
    }();
    return parsed == null
        ? null
        : (parsed > maxRetryAfter ? maxRetryAfter : parsed);
  }

  DateTime? _parseHttpDate(String value) {
    final match = RegExp(
      r'^(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun), (\d{2}) ([A-Z][a-z]{2}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    const months = <String, int>{
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final month = months[match[2]];
    if (month == null) return null;
    return DateTime.utc(
      int.parse(match[3]!),
      month,
      int.parse(match[1]!),
      int.parse(match[4]!),
      int.parse(match[5]!),
      int.parse(match[6]!),
    );
  }

  bool _retryableStatus(int status) =>
      status == 408 ||
      status == 429 ||
      status == 500 ||
      status == 502 ||
      status == 503 ||
      status == 504;
  String _statusCode(int status) => status == 401
      ? 'unauthorized'
      : status == 403
      ? 'forbidden'
      : status == 404
      ? 'not_found'
      : status == 422
      ? 'validation_error'
      : 'http_error';
  String? _header(Map<String, String> headers, String name) {
    for (final e in headers.entries) {
      if (e.key.toLowerCase() == name) return e.value;
    }
    return null;
  }

  String _uuid() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
  }
}
