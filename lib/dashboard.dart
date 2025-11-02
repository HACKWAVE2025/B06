import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_page.dart';
import 'daily_tasks.dart';
import 'eco_sort_game.dart'; // ✅ Import new page

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
  /// ✅ Loads user data from Firestore
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          name = userDoc.data()?['name'] ?? 'User';
          role = userDoc.data()?['role'] ?? 'Unknown';

          // Safely handle the 'points' value, ensuring it's always a double
          final pointsValue = userDoc.data()?['points'] ?? 0;

          // Check if it's a double or int and cast accordingly
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

  /// ✅ Logs out the user
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
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUserData, // 🔄 Manual refresh button
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
          ? const Center(
        child: CircularProgressIndicator(color: Colors.greenAccent),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👋 Greeting
            Text(
              "Welcome, ${name ?? user?.email ?? 'User'}",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 24),

            // ⭐ Eco Points Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: primaryGreen, size: 36),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Eco Points",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${points.toStringAsFixed(2)}", // Display points as a fixed 2 decimal places
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

            // 🧍‍♂️ Role-specific content
            if (role == "child") ...[
              Text(
                "🎮 Child Dashboard",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                "Play GamEco",
                Icons.videogame_asset,
                primaryGreen,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EcoSortGamePage(
                        onRoundFinished: (score) async {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            final double scoreAsDouble = score.toDouble();

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({
                              'points': FieldValue.increment(scoreAsDouble),
                              'totalActivities': FieldValue.increment(1),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('You earned $scoreAsDouble Eco Points! 🎉'),
                                backgroundColor: Colors.greenAccent,
                              ),
                            );

                            // Refresh dashboard to show new points
                            _loadUserData();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ] else if (role == "adult") ...[
              Text(
                "🌿 Adult Dashboard",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                "Daily Tasks",
                Icons.task_alt,
                primaryGreen,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DailyTasks(),
                    ),
                  );
                },
              ),
            ] else ...[
              const Text(
                "No specific role assigned.",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ✅ Reusable styled button
  Widget _buildActionButton(
      String label, IconData icon, Color color, {
        required VoidCallback onPressed,
      }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.black87),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
