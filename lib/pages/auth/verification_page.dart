import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:senior_care/pages/auth/auth_service.dart';
import 'package:senior_care/pages/wrapper.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPage();
}

class _VerificationPage extends State<VerificationPage> {
  final _auth = AuthService();
  late Timer timer;

  @override
  void initState() {
    super.initState();
    _auth.sendEmailVerification();
    timer = Timer.periodic(Duration(seconds: 5), (timer) {
      FirebaseAuth.instance.currentUser?.reload();
      if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
        timer.cancel();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Wrapper()
        ));
      }

    });
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Na podany adres email został wysłany link weryfikacyjny. Proszę kliknąć w link aby zweryfikować konto.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton(
                child: Text('Wyślij ponownie email'),
                onPressed: () async {
                  _auth.sendEmailVerification();
                },
              )
            ],
          ),
        )
      )
    );
  }
}
