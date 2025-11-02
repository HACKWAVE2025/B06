import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskDetailPage extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;

  const TaskDetailPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  File? _image;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isPermissionGranted = false;
  bool _isVerifying = false;
  bool _isVerified = false;
  bool _submitted = false;

  final Color primaryGreen = Colors.greenAccent.shade400;

  final String cloudName = 'dgiqmo1t1';
  final String uploadPreset = 'flutter_unsigned';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController =
            CameraController(cameras.first, ResolutionPreset.medium);
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
          _isPermissionGranted = true;
        });
      }
    } else {
      setState(() {
        _isPermissionGranted = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isCameraInitialized || _cameraController == null) return;

    final image = await _cameraController!.takePicture();
    await _cameraController!.dispose();

    setState(() {
      _isCameraInitialized = false;
      _image = File(image.path);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Photo captured successfully! 📸"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _retakePhoto() async {
    setState(() {
      _image = null;
      _isCameraInitialized = false;
      _isVerified = false;
      _submitted = false;
    });
    await _initializeCamera();
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    final url =
    Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(resBody);
      return data['secure_url'];
    } else {
      debugPrint('❌ Cloudinary upload failed: $resBody');
      return null;
    }
  }

  Future<void> _submitTask() async {
    if (_image == null) return;

    setState(() {
      _isVerifying = true;
      _submitted = true;
    });

    final imageUrl = await _uploadToCloudinary(_image!);
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Image upload failed."),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isVerifying = false);
      return;
    }

    // Send to backend AI verification
    final body = jsonEncode({
      "prompt":
      "You are an AI that verifies photo evidence for a task called '${widget.title}'. "
          "Understand the meaning of the task from its name. Then analyze the image and check if the person seems to be performing that task. "
          "Return only 'true' if the activity in the image clearly matches the task, otherwise return 'false'. "
          "Do not explain or include any extra text.",
      "imageUrl": imageUrl,
    });

    debugPrint("📤 Sending to Gemini Backend:\n$body");

    final response = await http.post(
      Uri.parse("https://ai-backend-server.vercel.app/api/gemini"),
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    final responseBody = json.decode(response.body);
    debugPrint("🧠 Full API Response: $responseBody");

    final resultValue = responseBody["result"] ??
        responseBody["caption"] ??
        responseBody["response"] ??
        responseBody["output"] ??
        responseBody["message"] ??
        responseBody.toString();

    debugPrint("🧠 AI Verification Response: $resultValue");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("AI Response: $resultValue"),
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 2),
      ),
    );

    final isValid = resultValue.toString().toLowerCase().contains("true");

    // ✅ Get current user's UID from Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? "guest_user"; // fallback if not logged in

    if (isValid) {
      setState(() => _isVerified = true);

      // ✅ Get current user's UID
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? "guest_user";

      // 🔹 Store completed task in Firestore
      await FirebaseFirestore.instance.collection('tasks').add({
        "uid": uid,
        "task_name": widget.title,
        "status": "completed",
        "points": 10,
        "image_url": imageUrl,
        "timestamp": FieldValue.serverTimestamp(),
      });

      // 🔹 Update user's total points
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userSnapshot = await userDocRef.get();

      int currentPoints = 0;
      if (userSnapshot.exists) {
        final data = userSnapshot.data()!;
        currentPoints = (data['points'] ?? 0) as int;
      }

      final newPoints = currentPoints + 10;

      await userDocRef.set({'points': newPoints}, SetOptions(merge: true));

      // 🔹 Show Eco Points update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Task verified! Eco Points: $newPoints 🌿"),
          backgroundColor: Colors.green,
        ),
      );

      // 🔹 Go back to DailyTasks page
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context, true);
      });
    }
    else {
      // 🔹 Store pending task
      await FirebaseFirestore.instance.collection('tasks').add({
        "uid": uid,
        "task_name": widget.title,
        "status": "pending",
        "points": 0,
        "image_url": imageUrl,
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Verification failed. Please retake a valid photo."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    setState(() => _isVerifying = false);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(widget.icon, color: primaryGreen, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                widget.description,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 30),

              // Preview or Image
              Center(
                child: Container(
                  width: 280,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryGreen, width: 1.5),
                  ),
                  child: _image != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _image!,
                      fit: BoxFit.cover,
                    ),
                  )
                      : _isCameraInitialized
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CameraPreview(_cameraController!),
                  )
                      : const Center(
                    child: CircularProgressIndicator(
                        color: Colors.greenAccent),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              if (!_submitted)
                Center(
                  child: _image == null
                      ? ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt,
                        color: Colors.black87),
                    label: const Text("Capture Photo",
                        style: TextStyle(color: Colors.black87)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: _isCameraInitialized ? _capturePhoto : null,
                  )
                      : ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, color: Colors.black87),
                    label: const Text("Retake Photo",
                        style: TextStyle(color: Colors.black87)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: _retakePhoto,
                  ),
                )
              else
                Center(
                  child: _isVerifying
                      ? const Text(
                    "⏳ Verifying your submission...",
                    style: TextStyle(color: Colors.white70),
                  )
                      : _isVerified
                      ? const Text(
                    "✅ Task verified successfully!",
                    style: TextStyle(color: Colors.greenAccent),
                  )
                      : const Text(
                    "🕒 Task under verification...",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),

              const SizedBox(height: 20),

              if (!_submitted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _image == null ? null : _submitTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      disabledBackgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Submit Task",
                      style: TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
