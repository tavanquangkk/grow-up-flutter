import 'package:flutter/material.dart';
import 'package:grow_up/features/auth/screens/Login.dart';
import 'package:grow_up/features/auth/screens/Signup.dart';

void main() {
  runApp(MaterialApp(home: MyApp(), debugShowCheckedModeBanner: false));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LoginScreen();
  }
}
