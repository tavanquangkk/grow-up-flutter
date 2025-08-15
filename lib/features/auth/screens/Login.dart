import 'package:flutter/material.dart';
import 'package:grow_up/core/utils/buttonStyle.dart';
import 'package:grow_up/features/auth/screens/Signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
                "Login",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),

            Image.asset("assets/icons/logo-1.png", width: 300),
            SizedBox(height: 10),

            TextFormField(
              decoration: InputDecoration(labelText: 'Enter your email'),
            ),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(labelText: 'Enter your password'),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text("Login", style: TextStyle(color: Colors.white)),
              style: raisedButtonStyle,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("アカウントを持っていません？"),
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (context) => Signup()));
                  },
                  child: Text("会員登録"),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text("Googleでログインする"),
            Icon(Icons.facebook),
          ],
        ),
      ),
    );
  }
}
