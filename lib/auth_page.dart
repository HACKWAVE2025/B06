import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  Future<void> _signInWithGoogle(BuildContext context, String role) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 👇 Force the account chooser to appear every time
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // user canceled

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Check if the user already exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // Existing user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Welcome back, ${user.displayName ?? 'User'}!")),
          );
        } else {
          // New user, create Firestore entry
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'role': role,
          });

          await FirebaseFirestore.instance.collection('wallets').doc(user.uid).set({
            'uid': user.uid,
            'points': 0,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created successfully!")),
          );
        }

        // Navigate to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Dashboard()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "An account already exists with this email using a different sign-in method.",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google sign-in failed: ${e.message}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Role")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Are you a?", style: TextStyle(fontSize: 22)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _signInWithGoogle(context, "child"),
                child: const Text("Child (13 - 18)"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(role: "adult"),
                    ),
                  );
                },
                child: const Text("Adult (18+)"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
