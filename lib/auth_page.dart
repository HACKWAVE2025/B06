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
            SnackBar(
                content:
                Text("Welcome back, ${user.displayName ?? 'User'}!")),
          );
        } else {
          // New user, create Firestore entry
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'role': role,
          });

          await FirebaseFirestore.instance
              .collection('wallets')
              .doc(user.uid)
              .set({
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

  // =================== UI ===================

  @override
  Widget build(BuildContext context) {
    const deepGreen = Color(0xFF27463A);
    const lightLime = Color(0xFFD6F0B2); // top gradient for Kid
    const midLime = Color(0xFF85C67E);   // bottom gradient for Kid
    const midGreen = Color(0xFF5FA06F);  // top gradient for Next-Gen
    const darkGreen = Color(0xFF3A7D57); // bottom gradient for Next-Gen

    return Scaffold(
      // keep an AppBar to respect your original structure, but hide it
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: deepGreen,
      body: SafeArea(
        child: Stack(
          children: [
            // Back button
            Positioned(
              top: 12,
              left: 12,
              child: _RoundBackButton(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Kid Mode
                  _ModeCard(
                    title: 'Kid Mode',
                    subtitle: 'Under 15',
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [lightLime, midLime],
                    ),
                    doodleAsset: 'assets/illustrations/rocket.png',
                    onPressed: () => _signInWithGoogle(context, "child"),
                  ),
                  const SizedBox(height: 18),

                  // Next-Gen Mode
                  _ModeCard(
                    title: 'Next-Gen Mode',
                    subtitle: '15 and above',
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [midGreen, darkGreen],
                    ),
                    // re-uses rocket if you don't have a sparkle asset yet
                    doodleAsset: 'assets/illustrations/rocket.png',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(role: "adult"),
                        ),
                      );
                    },
                    darkText: true,
                  ),

                  const Spacer(),

                  // Illustration at bottom
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Image.asset(
                        'assets/illustrations/bulb_people.png',
                        height: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.lightbulb,
                          color: Colors.white.withOpacity(0.85),
                          size: 140,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- widgets used in the page (kept inside the same file) ----------

class _RoundBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RoundBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEDE7E3),
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(12.0),
          child: Icon(Icons.arrow_back, color: Colors.black87, size: 26),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final String doodleAsset;
  final VoidCallback onPressed;
  final bool darkText; // for the darker second button

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.doodleAsset,
    required this.onPressed,
    this.darkText = false,
  });

  @override
  Widget build(BuildContext context) {
    final shadow = Colors.black.withOpacity(0.25);
    final titleColor = darkText ? const Color(0xFF0F2B1F) : const Color(0xFF153524);
    final subColor = darkText ? const Color(0xFF0F2B1F).withOpacity(0.8) : const Color(0xFF153524).withOpacity(0.8);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: subColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // small doodle on the right (optional)
                Image.asset(
                  doodleAsset,
                  width: 46,
                  height: 46,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.auto_awesome, size: 30, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}