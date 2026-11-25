import 'package:client/src/config/http_config.dart';
import 'package:client/src/services/api_client.dart';
import 'package:client/src/widgets/api_status_banners.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    apiClient.degradedMode.recordSuccess();
    apiClient.lastError.value = null;
  });

  testWidgets('degraded banner tracks the shared API state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            ApiStatusBanners(child: child ?? const SizedBox.shrink()),
        home: const Scaffold(body: Text('Page')),
      ),
    );

    apiClient.degradedMode
      ..recordFailure()
      ..recordFailure()
      ..recordFailure();
    await tester.pump();
    expect(
      find.text(
        'The server is temporarily unavailable. Some actions are paused.',
      ),
      findsOneWidget,
    );

    apiClient.degradedMode.recordSuccess();
    await tester.pump();
    expect(
      find.text(
        'The server is temporarily unavailable. Some actions are paused.',
      ),
      findsNothing,
    );
    expect(find.text('Page'), findsOneWidget);
  });

  testWidgets('HTTP error banner uses friendly text and expires', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            ApiStatusBanners(child: child ?? const SizedBox.shrink()),
        home: const Scaffold(body: Text('Page')),
      ),
    );
    apiClient.lastError.value = const ApiException(
      message: 'internal transport detail',
      code: 'network_error',
    );
    await tester.pump();

    expect(
      find.text('Could not connect to the server. Please try again later.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(
      find.text('Could not connect to the server. Please try again later.'),
      findsNothing,
    );
  });
}
