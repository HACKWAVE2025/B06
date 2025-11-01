import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? name;
  String? role;
  int? points;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final walletDoc = await FirebaseFirestore.instance.collection('wallets').doc(user.uid).get();

      setState(() {
        name = doc.data()?['name'] ?? 'User';
        role = doc.data()?['role'] ?? 'Unknown';
        points = walletDoc.data()?['points'] ?? 0;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, ${name ?? user?.email ?? 'User'} 👋",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Role: ${role ?? 'Unknown'}"),
            const SizedBox(height: 8),
            Text("Points: ${points ?? 0}"),
            const SizedBox(height: 30),

            // Different UI for Child vs Adult
            if (role == "child") ...[
              const Text("🎮 Child Dashboard", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {},
                child: const Text("Play Eco Games"),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text("View Challenges"),
              ),
            ] else if (role == "adult") ...[
              const Text("🌿 Adult Dashboard", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {},
                child: const Text("View Eco Tips"),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text("Track Family Progress"),
              ),
            ] else ...[
              const Text("No specific role assigned."),
            ],
          ],
        ),
      ),
    );
  }
}
