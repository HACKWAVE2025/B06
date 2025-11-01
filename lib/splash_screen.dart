import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dashboard.dart';
import 'flashcards_screen.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FlashCardsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const orangeEco = Color(0xFFF29D38); // warm orange for "ECO"
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background crumpled-paper image
          Positioned.fill(
            child: Image.asset(
              'assets/background/green_bg.jpg', // <-- add this asset
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.20),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo (eco car/leaf)
                  Image.asset(
                    'assets/app_logo/download.png', // your logo from the screenshot
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),

                  // GAMECO (GAME white, ECO orange)
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'GAME',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                        TextSpan(
                          text: 'ECO',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: orangeEco,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Tagline
                  const Text(
                    'SMALL CLICKS BIG IMPACT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 1.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Subtle loading indicator at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}