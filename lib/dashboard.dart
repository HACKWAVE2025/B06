import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_page.dart';
import 'daily_tasks.dart';
import 'eco_sort_game.dart';
import 'leaderboard_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? name;
  String? role;
  double points = 0.0;
  bool loading = true;

  final Color primaryGreen = Colors.greenAccent.shade400;
  final Color backgroundColor = const Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          name = data['name'] ?? 'User';
          role = data['role'] ?? 'Unknown';
          final pointsValue = data['points'] ?? 0;
          points = pointsValue is double ? pointsValue : pointsValue.toDouble();
          loading = false;
        });
      } else {
        setState(() {
          name = 'User';
          role = 'Unknown';
          points = 0.0;
          loading = false;
        });
      }
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 4,
        automaticallyImplyLeading: false,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUserData,
            tooltip: "Refresh",
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            Text(
              "Welcome, ${name ?? user?.email ?? 'User'}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Points Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryGreen.withOpacity(0.2),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.star_rounded, color: primaryGreen, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Eco Points",
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        points.toStringAsFixed(2),
                        style: TextStyle(
                          color: primaryGreen,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Role-based Buttons
            if (role == "child") _buildChildDashboard()
            else if (role == "adult") _buildAdultDashboard()
            else
              const Text(
                "No specific role assigned.",
                style: TextStyle(color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Activities",
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 20),
        _buildActionButton("Play GamEco", Icons.videogame_asset_outlined, primaryGreen, onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EcoSortGamePage(
                onRoundFinished: (score) async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    await FirebaseFirestore.instance.collection('users').doc(uid).update({
                      'points': FieldValue.increment(score.toDouble()),
                      'totalActivities': FieldValue.increment(1),
                    });
                    _loadUserData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('You earned $score Eco Points!')),
                    );
                  }
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        _buildActionButton("Leaderboard", Icons.leaderboard_outlined, Colors.orangeAccent, onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardPage()));
        }),
      ],
    );
  }

  Widget _buildAdultDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Tools",
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 20),
        _buildActionButton("Daily Tasks", Icons.task_alt_outlined, primaryGreen, onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyTasks()));
        }),
        const SizedBox(height: 16),
        _buildActionButton("Leaderboard", Icons.leaderboard_outlined, Colors.orangeAccent, onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardPage()));
        }),
      ],
    );
  }

  Widget _buildActionButton(
      String label,
      IconData icon,
      Color color, {
        required VoidCallback onPressed,
      }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 6,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
