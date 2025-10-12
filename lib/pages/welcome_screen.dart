import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:senior_care/pages/auth/signin_page.dart';
import 'package:senior_care/pages/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class WelcomeScreen extends StatefulWidget{
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}


// WYSTYLIZOWAC TE STRONY (ZDJECIA, TEKSTY, KOLORY)

class _WelcomeScreenState extends State<WelcomeScreen> {  
  final controller = PageController();
  bool isLastPage = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget BuildPage ({
    required Color color,
    required String urlImage,
    required String title,
    required String subtitle,
  }) =>
    Container(
      color: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            urlImage,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
          const SizedBox(height: 64),
          Text(
            title,
            style: const TextStyle(
              color: Colors.teal,
              fontSize: 32,
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Text(
              subtitle,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 18
              ),
            ),
          )
        ]
      )
    );

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: controller,
          onPageChanged: (index) {
            setState(() => isLastPage = index == 4);
          },
          children: [
            BuildPage(
              color: Colors.red,
              urlImage: 'assets/page1.jpg',
              title: 'Witamy w Senior Care',
              subtitle: 'Aplikacja wspierająca opiekunów osób starszych'
            ),
            BuildPage(
              color: Colors.green,
              urlImage: 'assets/page2.jpg',
              title: 'Druga strona',
              subtitle: 'Opis drugiej strony'
            ),
            BuildPage(
              color: Colors.blue,
              urlImage: 'assets/page3.jpg',
              title: 'Trzecia strona',
              subtitle: 'Opis trzeciej strony'
            ),
            BuildPage(
              color: Colors.yellow,
              urlImage: 'assets/page4.jpg',
              title: 'Czwarta strona',
              subtitle: 'Opis czwartej strony'
            ),
            BuildPage(
              color: Colors.orange,
              urlImage: 'assets/page5.jpg',
              title: 'Piąta strona',
              subtitle: 'Opis piątej strony'
            ),
          ]
        ),
      ),
      bottomSheet: isLastPage
      ? TextButton(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0)
            ),
            foregroundColor: Colors.white,
            backgroundColor: Colors.indigo,
            minimumSize: const Size.fromHeight(80)
          ),
          
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          prefs.setBool('showHome', true);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => SignInPage())
          );
        },
         child:  const Text(
          'Rozpocznij',
          style: TextStyle(fontSize: 24),
          ),
        )
      : Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => controller.jumpToPage(4),
               child: const Text('Pomiń')
            ),
            Center(
              child: SmoothPageIndicator(
                controller: controller,
                count: 5,
                effect: const WormEffect(
                  spacing: 16,
                  dotColor: Colors.black26,
                  activeDotColor: Colors.indigo
                ),
                onDotClicked: (index) => controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeIn),
              ),
            ),
            TextButton(
              onPressed: () => controller.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut),
              child: const Text('Dalej')
            ),
          ],
        ),
      ),
  );
}

