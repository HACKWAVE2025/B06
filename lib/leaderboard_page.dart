import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0F0F0F);
    const cardColor = Color(0xFF1C1C1C);
    final accent = Colors.greenAccent.shade400;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Leaderboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('points', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No users yet!",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          final users = snapshot.data!.docs;
          final topThree = users.take(3).toList();
          final others = users.skip(3).toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ----- Top 3 Podium -----
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (topThree.length > 1)
                        _buildPodiumUser(
                          name: topThree[1]['name'] ?? 'Unknown',
                          points: (topThree[1]['points'] ?? 0).toDouble(),
                          rank: 2,
                          height: 100,
                          color: Colors.grey.shade400,
                        ),
                      if (topThree.isNotEmpty)
                        _buildPodiumUser(
                          name: topThree[0]['name'] ?? 'Unknown',
                          points: (topThree[0]['points'] ?? 0).toDouble(),
                          rank: 1,
                          height: 140,
                          color: Colors.amberAccent,
                        ),
                      if (topThree.length > 2)
                        _buildPodiumUser(
                          name: topThree[2]['name'] ?? 'Unknown',
                          points: (topThree[2]['points'] ?? 0).toDouble(),
                          rank: 3,
                          height: 80,
                          color: const Color(0xFFCD7F32),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ----- Other Users -----
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: others.length,
                  itemBuilder: (context, index) {
                    final user = others[index];
                    final name = user['name'] ?? 'Unknown';
                    final points = (user['points'] ?? 0).toDouble();

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withOpacity(0.3),
                            ),
                            child: Text(
                              "${index + 4}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            "${points.toStringAsFixed(2)} pts",
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🏆 Builds one of the top 3 podium positions
  Widget _buildPodiumUser({
    required String name,
    required double points,
    required int rank,
    required double height,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.9),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${points.toStringAsFixed(2)} pts",
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: height,
            width: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              "$rank",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
