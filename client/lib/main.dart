import 'package:client/src/components/main_app.dart';
import 'package:client/src/pages/Authorization/login.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: "/app",
    routes:{
      "/authorization": (context) => LoginPage(),
      "/app": (context) => MainApp(),
      // "/initialization": (context) =>
    },
  ));
}



