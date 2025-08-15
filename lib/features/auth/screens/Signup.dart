import 'package:flutter/material.dart';
import 'package:grow_up/core/utils/buttonStyle.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF8DBFE2),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            SizedBox(height: 50),
            Center(
              child: Text(
                "Sign up ",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),

            Image.asset("assets/icons/logo-1.png", width: 300),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(labelText: 'Enter your fullName'),
            ),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(labelText: 'Enter your email'),
            ),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(labelText: 'Enter your password'),
            ),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(labelText: 'Confirm  password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text("Sign up", style: TextStyle(color: Colors.white)),
              style: raisedButtonStyle,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("既にアカウントを持っている？"),
                TextButton(onPressed: () {}, child: Text("ログイン")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
