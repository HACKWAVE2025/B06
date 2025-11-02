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
        "Collect and recycle plastic waste from your home or surroundings. Sort it into recyclable bins to reduce pollution."
      },
      {
        "title": "Plant a sapling",
        "icon": Icons.local_florist,
        "description":
        "Plant a small tree or sapling near your home, garden, or park. Water it regularly to help it grow."
      },
      {
        "title": "Avoid single-use plastics",
        "icon": Icons.no_drinks,
        "description":
        "Say no to plastic straws, bags, and bottles today. Carry your own reusable alternatives instead."
      },
      {
        "title": "Use public transport or walk",
        "icon": Icons.directions_walk,
        "description":
        "Reduce your carbon footprint by walking, cycling, or taking public transport instead of private vehicles."
      },
      {
        "title": "Save electricity at home",
        "icon": Icons.lightbulb_outline,
        "description":
        "Turn off unnecessary lights and appliances when not in use. Unplug devices to save energy."
      },
      {
        "title": "Educate a friend about sustainability",
        "icon": Icons.groups,
        "description":
        "Spread awareness about eco-friendly habits and inspire others to take action toward a sustainable future."
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
                  leading: Icon(task["icon"],
                      color: isCompleted ? Colors.white : primaryGreen, size: 32),
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
                          content:
                          Text("${task['title']} marked as completed 🎉"),
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