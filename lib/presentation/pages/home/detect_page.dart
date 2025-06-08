import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

class DetectPage extends StatefulWidget {
  const DetectPage({Key? key}) : super(key: key);

  @override
  State<DetectPage> createState() => _DetectPageState();
}

class _DetectPageState extends State<DetectPage> {
  late YOLOViewController _yoloController;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller YOLOView
    _yoloController = YOLOViewController();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pose Detection (YOLOView)'),
        actions: [
          // Tombol untuk mengganti kamera depan/belakang
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () {
              // Panggil fungsi switchCamera() dari controller YOLOView
              _yoloController.switchCamera();
            },
          ),
        ],
      ),
      body: YOLOView(
        controller: _yoloController,
        modelPath: 'assets/models/yolo11n-pose_float32.tflite',
        task: YOLOTask.pose, // Menggunakan mode pose estimation
        onResult: (List<YOLOResult> results) {
          // Callback hasil deteksi (opsional, bisa digunakan untuk debug atau log)
          // Contoh: cetak jumlah objek terdeteksi
          if (results.isNotEmpty) {
            debugPrint('Detected ${results.length} person(s) with pose');
          }
        },
      ),
    );
  }
}