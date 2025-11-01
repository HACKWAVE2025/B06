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
    // Wait for 3 seconds before checking auth (for splash display)
    await Future.delayed(const Duration(seconds: 3));

    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return; // avoid navigation errors if widget disposed

    if (user != null) {
      // User is logged in → go to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Dashboard()),
      );
    } else {
      // User not logged in → go to FlashCardsScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FlashCardsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular logo placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 24),

            // App name text
            const Text(
              'GameEco',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'A Greener Way to Live 🌱',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),

            const CircularProgressIndicator(
              color: Colors.green,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
