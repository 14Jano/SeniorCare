import 'package:senior_care/components/square_tiles.dart';
import 'package:senior_care/pages/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:senior_care/pages/auth/forgot_password.dart';
import 'package:senior_care/pages/auth/signin_page.dart';
import 'package:senior_care/pages/auth/verification_page.dart';
import 'package:senior_care/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();

  final _email = TextEditingController();
  final _password = TextEditingController();
  bool isLoading = false;
  bool isPasswordHidden = true;

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
              obscureText: isPasswordHidden,
              controller: _password,
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return ForgotPassword();
                      }));
                    },
                    child: Text('Nie pamiętasz hasła?',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              )],
              ),
            ),
            isLoading ? const Center(child: CircularProgressIndicator(),):
            const SizedBox(height: 30),
            TextButton(
              child: const Text("Zaloguj się"),
              onPressed: _login,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SquareTile(
                  imagePath: 'assets/google.png',
                  onTap: () => AuthService().signInWithGoogle(),
                ),
              ],
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

  _login() async {
    setState(() {
      isLoading = true;
    });
    String? result = await _auth.loginUserWithEmailAndPassword(
      email: _email.text, 
      password: _password.text
      );
      setState(() {
      isLoading = false;
      });
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Proszę zweryfikować swój adres email."),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VerificationPage()),
        );
      }
      else if (result == "Admin"){
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminScreen()
        ),
      );
      }else if (result == "User") {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => UserScreen()
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Logowanie nie powiodło się: $result"),
          ),
        );
      }
  }
}