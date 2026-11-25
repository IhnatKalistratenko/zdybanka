import 'dart:async';

import 'package:client/src/services/api_client.dart';
import 'package:client/src/config/http_config.dart';
import 'package:flutter/material.dart';

String apiErrorMessage(
  Object error, {
  String fallback = 'The operation failed. Please try again later.',
}) {
  if (error is! ApiException) return fallback;
  if (error.code == 'timeout' || error.code == 'network_error') {
    return 'Could not connect to the server. Please try again later.';
  }
  if (error.statusCode == 429) {
    return 'Too many requests. Please try again later.';
  }
  if (error.statusCode == 401)
    return 'Your session has expired. Please sign in again.';
  if (error.statusCode == 403)
    return 'You are not allowed to perform this action.';
  if (error.statusCode == 404) return 'The requested item could not be found.';
  if (error.statusCode != null && error.statusCode! >= 500) {
    return 'A server error occurred. Please try again later.';
  }

  final message = error.message.trim();
  final isSafe =
      message.isNotEmpty &&
      message.length <= 180 &&
      !message.contains('\n') &&
      !message.contains('\r') &&
      !message.contains('Exception') &&
      !message.contains(' at ') &&
      !message.contains('http://') &&
      !message.contains('https://') &&
      !message.contains('Bearer ');
  if (isSafe && message != 'Request failed.') return message;
  if (error.statusCode == 400 || error.statusCode == 422) {
    return 'Check your information and try again.';
  }
  return fallback;
}

void dismissGlobalApiErrorWhenHandled(Object? error) {
  if (error is ApiException) {
    final reportedError = apiClient.lastError.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Some legacy services wrap ApiException before presenting it locally.
      if (identical(apiClient.lastError.value, reportedError)) {
        apiClient.lastError.value = null;
      }
    });
  }
}

class ApiStatusBanners extends StatefulWidget {
  const ApiStatusBanners({required this.child, super.key});

  final Widget child;

  @override
  State<ApiStatusBanners> createState() => _ApiStatusBannersState();
}

class _ApiStatusBannersState extends State<ApiStatusBanners> {
  ApiException? _error;
  Timer? _errorTimer;

  @override
  void initState() {
    super.initState();
    _error = apiClient.lastError.value;
    apiClient.lastError.addListener(_onErrorChanged);
    apiClient.degradedMode.addListener(_onDegradedModeChanged);
    _scheduleErrorDismissal(_error);
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    apiClient.lastError.removeListener(_onErrorChanged);
    apiClient.degradedMode.removeListener(_onDegradedModeChanged);
    super.dispose();
  }

  void _onErrorChanged() {
    final nextError = apiClient.lastError.value;
    if (identical(_error, nextError)) return;
    _errorTimer?.cancel();
    setState(() => _error = nextError);
    _scheduleErrorDismissal(nextError);
  }

  void _onDegradedModeChanged() {
    if (mounted) setState(() {});
  }

  void _scheduleErrorDismissal(ApiException? error) {
    if (error == null) return;
    _errorTimer = Timer(const Duration(seconds: 6), () {
      apiClient.clearReportedError(error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final degraded = apiClient.degradedMode.isDegraded;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (degraded)
              const _StatusBanner(
                message: 'The server is temporarily unavailable. Some actions are paused.',
                icon: Icons.cloud_off,
                color: Color(0xFF9A6700),
                background: Color(0xFFFFF4CE),
              ),
            if (_error != null)
              _StatusBanner(
                message: apiErrorMessage(_error!),
                icon: Icons.error_outline,
                color: const Color(0xFFB42318),
                background: const Color(0xFFFFE9E7),
                onDismiss: () => apiClient.clearReportedError(_error!),
              ),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.icon,
    required this.color,
    required this.background,
    this.onDismiss,
  });

  final String message;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Material(
        color: background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              if (onDismiss != null)
                Semantics(
                  label: 'Dismiss message',
                  button: true,
                  child: IconButton(
                    tooltip: null,
                    onPressed: onDismiss,
                    icon: Icon(Icons.close, color: color, size: 18),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DegradedModeBuilder extends StatelessWidget {
  const DegradedModeBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, bool isDegraded) builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: apiClient.degradedMode,
      builder: (context, _) =>
          builder(context, apiClient.degradedMode.isDegraded),
    );
  }
}
