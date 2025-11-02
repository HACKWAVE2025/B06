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

  final Color darkGreen = const Color(0xFF203A2C);
  final Color lightBeige = const Color(0xFFF3EFEA);
  final Color accentGreen = const Color(0xFF6DAA7F);
  final Color accentYellow = const Color(0xFFE1B866);

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
          'points': 0.0, // Initialize points to 0'
        });

        await FirebaseFirestore.instance.collection('wallets').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'points': 0.0,
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
      await googleSignIn.signOut(); // Always show account picker
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: darkGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBeige,
      appBar: AppBar(
        backgroundColor: darkGreen,
        title: Text(
          isLogin ? "Login" : "Sign Up",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      isLogin ? "Welcome Back 🌿" : "Join GameCo 🌱",
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!isLogin)
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Name",
                          filled: true,
                          fillColor: lightBeige,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        filled: true,
                        fillColor: lightBeige,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        filled: true,
                        fillColor: lightBeige,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (!isLogin) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          filled: true,
                          fillColor: lightBeige,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: loading ? null : _signInWithEmail,
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isLogin ? "Login" : "Sign Up"),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(
                        isLogin
                            ? "Create an account"
                            : "Already have an account? Login",
                        style: TextStyle(color: darkGreen),
                      ),
                    ),
                    const Divider(height: 30, color: Colors.grey),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentYellow,
                        foregroundColor: darkGreen,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: loading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.login),
                      label: const Text("Continue with Google"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
