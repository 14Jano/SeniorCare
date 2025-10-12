import 'dart:developer';
import 'package:senior_care/pages/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:senior_care/pages/auth/signin_page.dart';
import 'package:senior_care/pages/home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();

  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _email.dispose();
    _password.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const Spacer(),
            const Text("Logowanie",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w500)),
            const SizedBox(height: 50),
            TextField(
              decoration: InputDecoration(
                hintText: "Wprowadź email",
                labelText: "Email",
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              controller: _email,
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: "Wprowadź hasło",
                labelText: "Hasło",
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              controller: _password,
            ),
            const SizedBox(height: 30),
            TextButton(
              child: const Text("Zaloguj się"),
              onPressed: _login,
            ),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Nie masz konta? "),
              InkWell(
                onTap: () => goToSignup(context),
                child:
                    const Text("Zarejestruj się", style: TextStyle(color: Colors.red)),
              )
            ]),
            const Spacer()
          ],
        ),
      ),
    );
  }

  goToSignup(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );

  goToHome(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

  _login() async {
    final user = await _auth.loginUserWithEmailAndPassword(_email.text, _password.text);

    if (user != null) {
      log("Zalogowano pomyślnie");
      goToHome(context);
    }
  }
}