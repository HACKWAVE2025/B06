import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final Color primaryGreen = Colors.greenAccent.shade400;

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
    await _cameraController!.dispose(); // stop camera

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
    });
    await _initializeCamera(); // restart camera
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
              // 🌱 Task Header
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

              // 📜 Description
              Text(
                widget.description,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 30),

              // 📸 Camera Section
              Text(
                "Camera Preview",
                style: TextStyle(
                  color: primaryGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // ✅ SINGLE Camera Preview / Captured Image
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
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                      : _isPermissionGranted
                      ? (_isCameraInitialized
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: _cameraController!
                          .value.aspectRatio, // keeps natural ratio
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _cameraController!.value
                              .previewSize!.height,
                          height: _cameraController!
                              .value.previewSize!.width,
                          child:
                          CameraPreview(_cameraController!),
                        ),
                      ),
                    ),
                  )
                      : const Center(
                    child: CircularProgressIndicator(
                        color: Colors.greenAccent),
                  ))
                      : const Center(
                    child: Text(
                      "Camera permission not granted ⚠️",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🎯 Capture or Retake Button
              Center(
                child: _image == null
                    ? ElevatedButton.icon(
                  icon:
                  const Icon(Icons.camera_alt, color: Colors.black87),
                  label: const Text(
                    "Capture Photo",
                    style: TextStyle(color: Colors.black87),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: _isCameraInitialized ? _capturePhoto : null,
                )
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, color: Colors.black87),
                  label: const Text(
                    "Retake Photo",
                    style: TextStyle(color: Colors.black87),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: _retakePhoto,
                ),
              ),

              const SizedBox(height: 30),

              // ✅ Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _image == null
                      ? null
                      : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                        Text("Task submitted successfully! 🌿"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
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
