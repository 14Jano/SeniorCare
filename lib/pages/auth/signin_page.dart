import 'package:flutter/material.dart';
import 'package:senior_care/pages/auth/auth_service.dart';
import 'package:senior_care/pages/auth/login_page.dart';
import 'package:senior_care/pages/home_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _auth = AuthService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _name.dispose();
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
            const Text("Rejestracja",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w500)),
            const SizedBox(
              height: 50,
            ),
            TextField(
              decoration: InputDecoration(
                hintText: "Wprowadź imię",
                labelText: "Imię",
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              controller: _name,
            ),
            const SizedBox(height: 20),
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
            ElevatedButton(
              onPressed: _signup,
              child: const Text("Zarejestruj się"),
            ),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Masz już konto? "),
              InkWell(
                onTap: () => goToLogin(context),
                child: const Text("Zaloguj się", style: TextStyle(color: Colors.red)),
              )
            ]),
            const Spacer()
          ],
        ),
      ),
    );
  }

  goToLogin(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

  goToHome(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

  _signup() async {
   await _auth.createUserWithEmailAndPassword(_email.text, _password.text);
    Navigator.pop(context);
  }
}