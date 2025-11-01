import 'package:flutter/material.dart';
import 'auth_page.dart';

class FlashCardsScreen extends StatelessWidget {
  const FlashCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: [
          _buildCard(context, "Welcome to My App", "Let's get started!"),
          _buildCard(context, "Learn & Explore", "Your personalized dashboard awaits"),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                );
              },
              child: const Text("Continue to Login"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, String desc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(desc),
        ],
      ),
    );
  }
}
