import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:client/src/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _Transport extends http.BaseClient {
  _Transport(this.handler);
  final Future<http.StreamedResponse> Function(
    http.BaseRequest request,
    int call,
  )
  handler;
  final requests = <http.BaseRequest>[];
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    return handler(request, requests.length);
  }
}

http.StreamedResponse _response(
  int status, {
  Map<String, String> headers = const {},
  String body = '',
}) => http.StreamedResponse(
  Stream.value(utf8.encode(body)),
  status,
  headers: headers,
);

void main() {
  final uri = Uri.parse('https://example.test/resource');

  test(
    'successful request returns before timeout and attaches request ID',
    () async {
      final transport = _Transport((_, __) async => _response(200, body: 'ok'));
      final api = ApiClient(
        client: transport,
        timeout: const Duration(seconds: 1),
      );
      final response = await api.get(uri);
      expect(response.body, 'ok');
      expect(
        transport.requests.single.headers['X-Request-Id'],
        api.lastRequestId,
      );
      expect(api.lastRequestId, isNotEmpty);
    },
  );

  test(
    'POST keeps idempotency key across retry, while request IDs change',
    () async {
      final transport = _Transport(
        (_, call) async => _response(call == 1 ? 503 : 201),
      );
      final api = ApiClient(client: transport, delay: (_) async {});
      await api.post(
        uri,
        body: '{"x":1}',
        options: const ApiRequestOptions(idempotencySupported: true),
      );
      expect(transport.requests, hasLength(2));
      expect(transport.requests[0].headers['Idempotency-Key'], isNotEmpty);
      expect(
        transport.requests[0].headers['Idempotency-Key'],
        transport.requests[1].headers['Idempotency-Key'],
      );
      expect(
        (transport.requests[0] as http.Request).body,
        (transport.requests[1] as http.Request).body,
      );
      expect(
        transport.requests[0].headers['X-Request-Id'],
        isNot(transport.requests[1].headers['X-Request-Id']),
      );
    },
  );

  test('POST without declared backend idempotency is not retried and accepts explicit key', () async {
    final transport = _Transport((_, __) async => _response(503));
    final api = ApiClient(client: transport, delay: (_) async {});
    await expectLater(
      api.post(
        uri,
        options: const ApiRequestOptions(idempotencyKey: 'stable-key'),
      ),
      throwsA(isA<ApiException>()),
    );
    expect(transport.requests, hasLength(1));
    expect(transport.requests.single.headers['Idempotency-Key'], 'stable-key');
  });

  test('new logical POST calls receive different generated keys', () async {
    final transport = _Transport((_, __) async => _response(201));
    final api = ApiClient(client: transport);
    await api.post(uri);
    await api.post(uri);
    expect(transport.requests[0].headers['Idempotency-Key'], isNotEmpty);
    expect(
      transport.requests[0].headers['Idempotency-Key'],
      isNot(transport.requests[1].headers['Idempotency-Key']),
    );
  });

  test('request ID returned by server is retained', () async {
    final transport = _Transport(
      (_, __) async =>
          _response(200, headers: {'x-request-id': 'server-request-id'}),
    );
    final api = ApiClient(client: transport);
    await api.get(uri);
    expect(api.lastRequestId, 'server-request-id');
  });

  test('network failures retry GET and eventually succeed', () async {
    var calls = 0;
    final transport = _Transport((_, __) async {
      calls++;
      if (calls < 3) throw http.ClientException('offline');
      return _response(200);
    });
    final api = ApiClient(client: transport, delay: (_) async {});
    await api.get(uri);
    expect(calls, 3);
  });

  test(
    'permanent status is not retried and backend errors are decoded safely',
    () async {
      final transport = _Transport(
        (_, __) async => _response(
          422,
          body:
              '{"error":"Invalid","code":"BAD_INPUT","details":{"field":"x"}}',
        ),
      );
      final api = ApiClient(client: transport, delay: (_) async {});
      await expectLater(
        api.get(uri),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'BAD_INPUT')),
      );
      expect(transport.requests, hasLength(1));
    },
  );

  test(
    'retry-after seconds are capped and successful call clears degraded mode',
    () async {
      final waits = <Duration>[];
      var calls = 0;
      final transport = _Transport((_, __) async {
        calls++;
        return calls == 1
            ? _response(503, headers: {'retry-after': '999'})
            : _response(200);
      });
      final mode = DegradedModeManager(failureThreshold: 1);
      mode.recordFailure();
      final api = ApiClient(
        client: transport,
        maxRetryAfter: const Duration(milliseconds: 20),
        delay: (d) async {
          waits.add(d);
        },
        degradedMode: mode,
      );
      await api.get(uri);
      expect(waits.single, const Duration(milliseconds: 20));
      expect(mode.isDegraded, isFalse);
    },
  );

  test(
    'timeout while waiting for headers becomes timeout ApiException',
    () async {
      final transport = _Transport((request, _) async {
        final abort = (request as http.AbortableRequest).abortTrigger!;
        await abort;
        throw http.RequestAbortedException(request.url);
      });
      final api = ApiClient(
        client: transport,
        timeout: const Duration(milliseconds: 10),
        maxRetries: 0,
      );
      await expectLater(
        api.get(uri),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'timeout')),
      );
    },
  );

  test(
    'Retry-After HTTP-date is parsed and malformed values use backoff',
    () async {
      final waits = <Duration>[];
      var calls = 0;
      final transport = _Transport((_, __) async {
        calls++;
        return calls < 3
            ? _response(
                503,
                headers: {
                  'retry-after': calls == 1
                      ? 'Wed, 21 Oct 2026 07:28:10 GMT'
                      : 'not a date',
                },
              )
            : _response(200);
      });
      final api = ApiClient(
        client: transport,
        now: () => DateTime.utc(2026, 10, 21, 7, 28),
        maxRetryAfter: const Duration(seconds: 4),
        delay: (duration) async {
          waits.add(duration);
        },
        random: _FixedRandom(),
      );
      await api.get(uri);
      expect(waits.first, const Duration(seconds: 4));
      expect(waits.last, const Duration(milliseconds: 750));
    },
  );

  test('retry count is bounded to configured retries', () async {
    final transport = _Transport((_, __) async => _response(503));
    final api = ApiClient(client: transport, delay: (_) async {});
    await expectLater(api.get(uri), throwsA(isA<ApiException>()));
    expect(transport.requests, hasLength(4));
  });

  test('cancellation during backoff prevents another attempt', () async {
    final cancellation = Completer<void>();
    final delay = Completer<void>();
    final transport = _Transport((_, __) async => _response(503));
    final api = ApiClient(client: transport, delay: (_) => delay.future);
    final pending = api.get(
      uri,
      options: ApiRequestOptions(cancellation: cancellation),
    );
    await Future<void>.delayed(Duration.zero);
    cancellation.complete();
    await expectLater(
      pending,
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'cancelled')),
    );
    expect(transport.requests, hasLength(1));
    delay.complete();
  });

  test(
    'timeout while reading response body becomes timeout ApiException',
    () async {
      final transport = _Transport((request, _) async {
        final stream = StreamController<List<int>>();
        (request as http.AbortableRequest).abortTrigger!.then((_) {
          stream.addError(http.RequestAbortedException(request.url));
          unawaited(stream.close());
        });
        return http.StreamedResponse(stream.stream, 200);
      });
      final api = ApiClient(
        client: transport,
        timeout: const Duration(milliseconds: 10),
        maxRetries: 0,
      );
      await expectLater(
        api.get(uri),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'timeout')),
      );
    },
  );

  test('external cancellation is not classified as timeout', () async {
    final cancellation = Completer<void>();
    final transport = _Transport((request, _) async {
      await (request as http.AbortableRequest).abortTrigger!;
      throw http.RequestAbortedException(request.url);
    });
    final api = ApiClient(
      client: transport,
      timeout: const Duration(seconds: 1),
      maxRetries: 0,
    );
    final pending = api.get(
      uri,
      options: ApiRequestOptions(cancellation: cancellation),
    );
    cancellation.complete();
    await expectLater(
      pending,
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'cancelled')),
    );
  });
}

class _FixedRandom implements Random {
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}
