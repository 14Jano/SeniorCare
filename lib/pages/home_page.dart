import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:senior_care/pages/auth/auth_service.dart';
import 'package:senior_care/pages/auth/login_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _auth = AuthService();
    return Scaffold(
      body: Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Witaj użytkowniku",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 20),
            TextButton(
              child: const Text("Wyloguj się"),
              onPressed: () async {
                await _auth.signOut();
                goToLogin(context);
              },
            )
          ],
        ),
      ),
    );
  }

  goToLogin(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
}