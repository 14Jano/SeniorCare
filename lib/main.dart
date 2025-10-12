import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:senior_care/pages/auth/signin_page.dart';
import 'package:senior_care/pages/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  final showHome = prefs.getBool('showHome') ?? false;

  runApp(MyApp(showHome: showHome));
}

class MyApp extends StatelessWidget {
  final bool showHome;
  
  const MyApp({
    Key? key,
    required this.showHome,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: showHome ? WelcomeScreen() : SignInPage(),
    );
  }
}
