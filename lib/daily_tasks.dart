import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_detail_page.dart';

class DailyTasks extends StatelessWidget {
  const DailyTasks({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Colors.greenAccent.shade400;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? "guest_user";

    final List<Map<String, dynamic>> tasks = [
      {
        "title": "Collect plastic waste",
        "icon": Icons.recycling,
        "description":
        "Collect plastic bottles or wrappers from your surroundings and dispose of them responsibly. Take a picture while doing it as proof."
      },
      {
        "title": "Show your reusable water bottle",
        "icon": Icons.water_drop,
        "description":
        "Use a reusable water bottle instead of single-use plastic ones. Take a photo showing your eco-friendly bottle."
      },
      {
        "title": "Carry your own shopping bag",
        "icon": Icons.shopping_bag,
        "description":
        "Bring your cloth or paper bag when shopping to avoid plastic bags. Capture a photo showing your reusable bag."
      },
      {
        "title": "Switch off unused lights",
        "icon": Icons.lightbulb_outline,
        "description":
        "Turn off unnecessary lights and fans when not needed. Take a quick photo to show your energy-saving effort."
      },
      {
        "title": "Use public transport or walk",
        "icon": Icons.directions_bus,
        "description":
        "Reduce your carbon footprint by walking, cycling, or using public transport. Take a photo showing yourself using or near public transport, or walking outdoors."
      },
      {
        "title": "Plant a sapling",
        "icon": Icons.local_florist,
        "description":
        "Plant a small tree or sapling and take a picture while planting or watering it."
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text("Daily Tasks", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('uid', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            );
          }

          final completedTasks = snapshot.data?.docs
              .where((doc) => doc['status'] == 'completed')
              .map((doc) => doc['task_name'] as String)
              .toSet() ??
              {};

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final isCompleted = completedTasks.contains(task["title"]);

              return Card(
                color: isCompleted ? Colors.green[800] : Colors.grey[850],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isCompleted ? primaryGreen : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: Icon(
                    task["icon"],
                    color: isCompleted ? Colors.white : primaryGreen,
                    size: 32,
                  ),
                  title: Text(
                    task["title"],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      decoration:
                      isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  trailing: isCompleted
                      ? const Icon(Icons.check_circle,
                      color: Colors.white, size: 22)
                      : const Icon(Icons.arrow_forward_ios,
                      color: Colors.white70, size: 18),
                  onTap: () async {
                    if (isCompleted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "✅ '${task['title']}' is already completed!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      return;
                    }

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailPage(
                          title: task["title"],
                          description: task["description"],
                          icon: task["icon"],
                        ),
                      ),
                    );

                    if (result == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "${task['title']} marked as completed 🎉"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
