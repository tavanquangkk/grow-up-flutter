import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_up/core/utils/router.dart';
import 'package:grow_up/features/auth/screens/Login.dart';
import 'package:grow_up/features/auth/screens/Register.dart';
import 'package:grow_up/features/home/HomePage.dart';
import 'package:grow_up/core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: goRouter.routerDelegate,
      routeInformationParser: goRouter.routeInformationParser,
      routeInformationProvider: goRouter.routeInformationProvider,

      title: 'Grow up',
      theme: ThemeData(primarySwatch: Colors.orange),
      // home: const AccoutScreen(),
    );
  }
}
