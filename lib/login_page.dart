import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dashboard.dart';

class LoginPage extends StatefulWidget {
  final String role;
  const LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool isLogin = true;
  bool loading = false;

  Future<void> _signInWithEmail() async {
    try {
      setState(() => loading = true);
      UserCredential userCredential;

      if (isLogin) {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        if (_passwordController.text.trim() != _confirmController.text.trim()) {
          _showError("Passwords do not match");
          return;
        }

        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': widget.role,
        });

        await FirebaseFirestore.instance.collection('wallets').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'points': 0,
        });
      }

      _navigateToDashboard();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Error occurred");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => loading = true);

      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 👇 Always show account picker
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
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
        // Check if user data already exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          _showError("Welcome back, ${user.displayName ?? 'User'}!");
        } else {
          // Create new user record
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'role': widget.role,
          });

          await FirebaseFirestore.instance.collection('wallets').doc(user.uid).set({
            'uid': user.uid,
            'points': 0,
          });
          _showError("Account created successfully!");
        }
      }

      _navigateToDashboard();
    } on FirebaseAuthException catch (e) {
      // Handle known Firebase auth errors
      if (e.code == 'account-exists-with-different-credential') {
        _showError(
          "An account already exists with this email using a different sign-in method.",
        );
      } else {
        _showError(e.message ?? "Google sign-in failed.");
      }
    } catch (e) {
      _showError("Google sign-in failed: $e");
    } finally {
      setState(() => loading = false);
    }
  }


  void _navigateToDashboard() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard()));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? "Login" : "Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (!isLogin)
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
                TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
                if (!isLogin)
                  TextField(controller: _confirmController, decoration: const InputDecoration(labelText: "Confirm Password"), obscureText: true),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: loading ? null : _signInWithEmail,
                  child: loading ? const CircularProgressIndicator() : Text(isLogin ? "Login" : "Sign Up"),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(isLogin ? "Create an account" : "Already have an account? Login"),
                ),
                const Divider(),
                ElevatedButton.icon(
                  onPressed: loading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text("Continue with Google"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
