import 'package:flutter/material.dart';
import 'package:senior_care/pages/auth/auth_service.dart';
import 'package:senior_care/pages/auth/login_page.dart';
import 'package:senior_care/pages/auth/verification_page.dart';
import 'package:senior_care/pages/home_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final AuthService _auth = AuthService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _selectedRole = "User";
  bool _isLoading = false;
  bool isPasswordHidden = true;

  void _signup() async {
    setState(() {
      _isLoading = true;
    });

   String? result = await _auth.createUserWithEmailAndPassword(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      role: _selectedRole,
    );
    setState(() {
      _isLoading = false;
    });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rejestracja zakończona sukcesem!")),
      );
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const VerificationPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Rejestracja nie powiodła się: $result")),
      );
    }
  }

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
                suffixIcon: IconButton(
                  onPressed: (){
                    setState(() {
                      isPasswordHidden = !isPasswordHidden;
                    });
                  },
                  icon: Icon(isPasswordHidden ? Icons.visibility_off : Icons.visibility),
                ),
              ),
              obscureText: isPasswordHidden,
              controller: _password,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: "Rola użytkownika",
                border: OutlineInputBorder()
              ),
              items: ["Admin", "User"].map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue!;
                });
              },
            ),
            _isLoading ? const Center(child: CircularProgressIndicator(),):
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

}