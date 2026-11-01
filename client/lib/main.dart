import 'package:client/src/config/route_config.dart';
import 'package:client/src/pages/Authorization/login.dart';
import 'package:client/src/services/auth_session.dart';
import 'package:flutter/material.dart';

void main() {
  AuthSession.configure(onUnauthorized: () async {
    final currentPath = router.routeInformationProvider.value.uri.path;
    if (currentPath != LoginPage.pageRoute) {
      router.go(LoginPage.pageRoute);
    }
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp.router(

      routerConfig: router,
    );
  }
}



