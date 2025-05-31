import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart'; // Perhatikan import ini

class DetectPage extends StatefulWidget {
  const DetectPage({Key? key}) : super(key: key);

  @override
  _DetectPageState createState() => _DetectPageState();
}

class _DetectPageState extends State<DetectPage> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isDetecting = false;
  List<dynamic>? _recognitions;
  late Interpreter _interpreter; // Interpreter untuk tflite_flutter

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras[1], ResolutionPreset.medium);
    await _cameraController.initialize();
    if (!mounted) return;
    setState(() {});
    _cameraController.startImageStream(_processCameraImage); // Mulai stream
  }

  Future<void> _loadModel() async {
    // Gunakan Interpreter dari tflite_flutter
    _interpreter = await Interpreter.fromAsset('assets/yolo11x-pose_float32.tflite');
    print("Model loaded successfully");
  }

  void _processCameraImage(CameraImage img) {
    if (_isDetecting) return;
    _isDetecting = true;
    _detectPose(img);
  }

  void _detectPose(CameraImage img) async {
    // Konversi CameraImage ke input tensor
    final input = _imageToByteList(img);

    // Siapkan output buffer (sesuaikan dengan output model Anda)
    final output = [List.filled(85, 0.0).reshape([1, 85])]; // Contoh shape, sesuaikan!

    // Jalankan inference
    _interpreter.run(input, output);

    // Proses output (ini bagian tersulit, sesuaikan dengan model YOLO Anda)
    final results = _processOutput(output);

    setState(() {
      _recognitions = results;
    });
    _isDetecting = false;
  }

  // Konversi CameraImage ke ByteBuffer
  ByteBuffer _imageToByteList(CameraImage image) {
    // Implementasi konversi sesuai kebutuhan model
    // Contoh sederhana (harus disesuaikan dengan preprocessing model YOLO):
    final rgbaBytes = _convertYUV420toRGBA(image);
    return Float32List.fromList(rgbaBytes.map((b) => b / 255.0).toList())
        .buffer;
  }

  // Contoh fungsi konversi YUV ke RGBA (sederhana)
  List<int> _convertYUV420toRGBA(CameraImage image) {
    // Implementasi aktual diperlukan di sini
    // Ini hanya placeholder!
    return List.filled(image.width * image.height * 4, 0);
  }

  // Proses output model (sesuaikan dengan arsitektur YOLO)
  List<dynamic> _processOutput(List<dynamic> output) {
    // Implementasi pengolahan output
    // Ini sangat tergantung pada model Anda!
    return [];
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _interpreter.close(); // Tutup interpreter
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return Container();
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return Scaffold(
      appBar: AppBar(title: Text('Deteksi Pose')),
      body: Stack(
        children: [
          Transform.scale(
            scale: _cameraController.value.aspectRatio / deviceRatio,
            child: Center(
              child: AspectRatio(
                aspectRatio: _cameraController.value.aspectRatio,
                child: CameraPreview(_cameraController),
              ),
            ),
          ),
          _buildResults(size),
        ],
      ),
    );
  }

  Widget _buildResults(Size size) {
    if (_recognitions == null || _cameraController.value.isRecordingVideo) {
      return Container();
    }

    final scale = size.width / _cameraController.value.previewSize!.height!;
    return Stack(
      children: _recognitions!.map((res) {
        return Positioned(
          left: res['rect']['x'] * scale,
          top: res['rect']['y'] * scale,
          width: res['rect']['w'] * scale,
          height: res['rect']['h'] * scale,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.red,
                width: 2,
              ),
            ),
            child: Text(
              '${res['detectedClass']} ${(res['confidenceInClass'] * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.red,
                background: Paint()..color = Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
