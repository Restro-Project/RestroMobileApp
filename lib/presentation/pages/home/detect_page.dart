import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:collection'; // For Queue
import 'dart:async'; // For Timer
import 'dart:math'; // For max
import 'package:flutter/services.dart' show rootBundle, WriteBuffer;
import 'dart:typed_data'; // For Float32List
import 'dart:convert'; // For jsonDecode

import 'pose_painter.dart';
import 'exercise_performance.dart';

class DetectPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final List<Map<String, dynamic>> plannedExercises; // {actionName: String, targetReps: int}
  final int maxDurationPerRep;

  const DetectPage({
    Key? key,
    required this.cameras,
    required this.plannedExercises,
    required this.maxDurationPerRep,
  }) : super(key: key);

  @override
  State<DetectPage> createState() => _DetectPageState();
}

class _DetectPageState extends State<DetectPage> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  Interpreter? _interpreter; // TFLite model
  List<double> _scalerMean = []; // Scaler mean values
  List<double> _scalerStd = []; // Scaler std values

  Queue<Float32List> _keypointSequenceBuffer = Queue<Float32List>();
  static const int SEQUENCE_LENGTH = 60; // Sesuai dengan model Anda
  static const int NUM_FEATURES = 33 * 2; // 33 landmarks * (x, y) coordinates
  static const double HOLD_DURATION_FOR_SUCCESS = 2.0;

  // Exercise tracking state
  List<ExercisePerformance> _sessionSummary = [];
  int _currentExerciseIndex = 0;
  ExercisePerformance? _currentExercisePerf; // Changed to nullable
  int _currentRepetitionAttempt = 0; // Tracks current attempt within an exercise

  double _repStartTime = 0.0;
  double? _inPerfectPoseStartTime;
  bool _isRepComplete = false;
  String _currentQualityLabel = "Tidak Terdeteksi";
  String _currentInstruction = "Bersiap...";
  String _predictedLabel = "..."; // Label hasil prediksi TFLite

  // UI rendering
  CustomPaint? _customPaint;
  Size? _cameraImageSize;
  InputImageRotation _cameraRotation = InputImageRotation.rotation0deg;

  Timer? _uiUpdateTimer; // Timer untuk memperbarui UI setiap ~100ms
  bool _isProcessingImage = false; // Flag to prevent multiple image processing simultaneously
  bool _assetsLoaded = false; // New flag to track asset loading status

  List<String> _actions = []; // Loaded from assets/actions.txt

  // **Tambahan untuk Mengubah Kamera**
  int _currentCameraIndex = 0; // 0 for back, 1 for front

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializePoseDetector();
    _loadAssets();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      print("No cameras found.");
      if (mounted) {
        _showErrorAndPop("Tidak ada kamera yang ditemukan.");
      }
      return;
    }

    // Pastikan _currentCameraIndex valid
    if (_currentCameraIndex >= widget.cameras.length) {
      _currentCameraIndex = 0; // Reset ke kamera pertama jika indeks tidak valid
    }

    _cameraController = CameraController(
      widget.cameras[_currentCameraIndex], // Ambil kamera berdasarkan indeks
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // **Tambahan: Tentukan format gambar secara eksplisit**
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;

      _cameraRotation = _inputImageRotationFromCameraDescription(widget.cameras[_currentCameraIndex]);

      // Hentikan stream gambar sebelumnya jika ada
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      _cameraController!.startImageStream(_processCameraImage);
      setState(() {});
    } catch (e) {
      print("Error initializing camera: $e");
      if (mounted) {
        _showErrorAndPop("Gagal menginisialisasi kamera: $e");
      }
    }
  }

  InputImageRotation _inputImageRotationFromCameraDescription(CameraDescription cameraDescription) {
    final int rotation = cameraDescription.sensorOrientation;
    if (rotation == 90) return InputImageRotation.rotation90deg;
    if (rotation == 180) return InputImageRotation.rotation180deg;
    if (rotation == 270) return InputImageRotation.rotation270deg;
    return InputImageRotation.rotation0deg;
  }

  void _initializePoseDetector() {
    _poseDetector = PoseDetector(options: PoseDetectorOptions(model: PoseDetectionModel.base));
  }

  Future<void> _loadAssets() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/cnn_best.tflite');
      print('✅ TFLite model loaded');

      final String actionsResponse = await rootBundle.loadString('assets/actions.txt');
      _actions = actionsResponse.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      print('✅ Actions loaded: $_actions');

      final String scalerResponse = await rootBundle.loadString('assets/scaler.json');
      final Map<String, dynamic> scalerData = jsonDecode(scalerResponse);

      // Pastikan kunci 'mean' ada dan bukan null
      if (scalerData['mean'] == null) {
        throw Exception("Kunci 'mean' tidak ditemukan di scaler.json atau bernilai null.");
      }
      _scalerMean = List<double>.from(scalerData['mean']);

      // Perbaikan di sini: gunakan 'scale' bukan 'std'
      if (scalerData['scale'] == null) {
        throw Exception("Kunci 'scale' tidak ditemukan di scaler.json atau bernilai null.");
      }
      _scalerStd = List<double>.from(scalerData['scale']);

      print('✅ Scaler parameters loaded');

      if (mounted) {
        setState(() {
          _assetsLoaded = true; // Set flag to true after assets are loaded
        });
      }

      // Start the first exercise only after assets are confirmed loaded
      _startNewExercise();
      _startUiUpdateTimer();

    } catch (e) {
      print('❌ Error loading assets: $e');
      if (mounted) {
        _showErrorAndPop("Error memuat aset: $e");
      }
    }
  }

  void _showErrorAndPop(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Pop current page
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startUiUpdateTimer() {
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update elapsed time and progress bar
        });
      }
    });
  }

  void _startNewExercise() {
    if (_currentExerciseIndex < widget.plannedExercises.length) {
      final exercisePlan = widget.plannedExercises[_currentExerciseIndex];
      _currentExercisePerf = ExercisePerformance(
        actionName: exercisePlan['actionName'],
        targetReps: exercisePlan['targetReps'],
      );
      _currentRepetitionAttempt = 1; // Start first attempt for this exercise
      _keypointSequenceBuffer.clear(); // Clear buffer for new exercise
      _resetRepetitionState();
      print("--- Memulai Gerakan ${_currentExerciseIndex + 1}: ${_currentExercisePerf!.actionName} (${_currentExercisePerf!.targetReps} repetisi) ---");
    } else {
      _finishSession();
    }
  }

  void _resetRepetitionState() {
    _repStartTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _inPerfectPoseStartTime = null;
    _isRepComplete = false;
    _currentQualityLabel = "Tidak Terdeteksi";
    _currentInstruction = "Bersiap...";
    _predictedLabel = "...";
    if (mounted) setState(() {});
  }

  void _completeRepetition(String resultType) {
    if (_isRepComplete) return; // Prevent double completion

    _currentExercisePerf!.recordAttempt(resultType); // Use null assertion operator
    _isRepComplete = true;
    _keypointSequenceBuffer.clear(); // Clear buffer for next rep/exercise

    if (resultType == "Sempurna") {
      _currentInstruction = "BERHASIL!";
    } else {
      _currentInstruction = "WAKTU HABIS!";
    }

    if (mounted) setState(() {});

    Future.delayed(const Duration(seconds: 2), () {
      if (_currentExercisePerf!.completedReps + _currentExercisePerf!.failedAttempts < _currentExercisePerf!.targetReps) {
        // Still has repetitions left for current exercise
        _currentRepetitionAttempt++;
        _resetRepetitionState();
        print("[REPETISI] Memulai percobaan ke-${_currentRepetitionAttempt} untuk '${_currentExercisePerf!.actionName}'.");
      } else {
        // Current exercise completed, move to next
        print("Latihan '${_currentExercisePerf!.actionName}' selesai. Berhasil: ${_currentExercisePerf!.completedReps}, Gagal: ${_currentExercisePerf!.failedAttempts}");
        _sessionSummary.add(_currentExercisePerf!); // Add completed exercise to session summary
        _currentExerciseIndex++;
        _startNewExercise();
      }
    });
  }

  Future<void> _toggleCamera() async {
    if (_cameraController == null || widget.cameras.length <= 1) {
      // Tidak ada kamera lain untuk diganti
      return;
    }

    // Hentikan stream gambar dan dispose controller lama
    await _cameraController!.stopImageStream();
    await _cameraController!.dispose();

    // Ubah indeks kamera ke kamera berikutnya (depan ke belakang, atau sebaliknya)
    _currentCameraIndex = (_currentCameraIndex + 1) % widget.cameras.length;

    // Inisialisasi ulang kamera dengan indeks yang baru
    await _initializeCamera();
  }

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    if (_isProcessingImage || _interpreter == null || _scalerMean.isEmpty || _scalerStd.isEmpty || _isRepComplete || !_assetsLoaded) {
      return;
    }
    _isProcessingImage = true;

    final inputImage = _inputImageFromCameraImage(cameraImage);
    if (inputImage == null) {
      _isProcessingImage = false;
      return;
    }

    try {
      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isNotEmpty) {
        final poseLandmarks = poses.first.landmarks.values.toList();
        _cameraImageSize = Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());

        // Process pose landmarks for TFLite inference
        final inputFeatures = _extractAndNormalizeKeypoints(poseLandmarks);
        if (inputFeatures != null) {
          _keypointSequenceBuffer.add(inputFeatures);
          if (_keypointSequenceBuffer.length > SEQUENCE_LENGTH) {
            _keypointSequenceBuffer.removeFirst();
          }

          if (_keypointSequenceBuffer.length == SEQUENCE_LENGTH) {
            // Prepare input for TFLite model
            var input = Float32List(SEQUENCE_LENGTH * NUM_FEATURES);
            int i = 0;
            for (var frame in _keypointSequenceBuffer) {
              for (var val in frame) {
                input[i++] = val;
              }
            }

            var output = List.filled(1 * _actions.length, 0.0).reshape([1, _actions.length]);
            _interpreter!.run(input.reshape([1, SEQUENCE_LENGTH, NUM_FEATURES]), output);

            double maxScore = -1.0;
            int predictedIndex = -1;
            for (int j = 0; j < _actions.length; j++) {
              if (output[0][j] > maxScore) {
                maxScore = output[0][j];
                predictedIndex = j;
              }
            }

            _predictedLabel = _actions[predictedIndex];

            // Logic for exercise progression
            _updateExerciseState(_predictedLabel, maxScore);
          }
        }

        if (mounted) {
          setState(() {
            _customPaint = CustomPaint(
              painter: PosePainter(
                poses,
                _cameraImageSize!,
                _cameraRotation,

              ),
            );
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _customPaint = null; // Clear painter if no poses are detected
            _currentQualityLabel = "Tidak Terdeteksi";
            _predictedLabel = "...";
          });
        }
        _inPerfectPoseStartTime = null; // Reset if pose is lost
      }
    } catch (e) {
      print("Error processing image: $e");
    } finally {
      _isProcessingImage = false;
    }
  }

  Float32List? _extractAndNormalizeKeypoints(List<PoseLandmark> landmarks) {
    if (landmarks.length != 33) return null; // Ensure all 33 landmarks are present

    var keypoints = Float32List(NUM_FEATURES);
    for (int i = 0; i < landmarks.length; i++) {
      keypoints[i * 2] = (landmarks[i].x - _scalerMean[i * 2]) / _scalerStd[i * 2];
      keypoints[i * 2 + 1] = (landmarks[i].y - _scalerMean[i * 2 + 1]) / _scalerStd[i * 2 + 1];
    }
    return keypoints;
  }

  void _updateExerciseState(String predictedAction, double confidence) {
    if (_currentExercisePerf == null || _isRepComplete) return;

    final targetAction = _currentExercisePerf!.actionName;
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

    if (predictedAction == targetAction && confidence > 0.8) { // Confident prediction for the target action
      if (_inPerfectPoseStartTime == null) {
        _inPerfectPoseStartTime = currentTime;
      }
      _currentQualityLabel = "Sempurna";
      _currentInstruction = "Tahan!";

      if (currentTime - _inPerfectPoseStartTime! >= HOLD_DURATION_FOR_SUCCESS) {
        _completeRepetition("Sempurna");
      }
    } else {
      _inPerfectPoseStartTime = null;
      _currentQualityLabel = "Belum Tepat";
      _currentInstruction = "Ikuti gerakan.";
    }

    // Check for timeout if not already complete
    if (!_isRepComplete && (currentTime - _repStartTime) > widget.maxDurationPerRep) {
      _completeRepetition("Waktu Habis");
    }
  }

  void _finishSession() {
    print("Sesi Latihan Selesai!");
    _uiUpdateTimer?.cancel();
    // Navigate to a summary page or show a dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sesi Latihan Selesai!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _sessionSummary.map((perf) =>
              Text('${perf.actionName}: ${perf.completedReps} Sempurna, ${perf.failedAttempts} Gagal')
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Pop DetectPage
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // **Revisi Penting di sini**
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // Memastikan format gambar adalah YUV420_888 atau NV21
    if (image.format.group != ImageFormatGroup.yuv420 && image.format.group != ImageFormatGroup.nv21) {
      print("Unsupported image format: ${image.format.group}");
      return null;
    }

    final CameraDescription currentCamera = widget.cameras[_currentCameraIndex];
    final InputImageRotation rotation = _inputImageRotationFromCameraDescription(currentCamera);

    // Untuk YUV420_888, kita perlu menggabungkan semua plane menjadi satu ByteBuffer
    // karena ML Kit InputImage.fromBytes() mengharapkan satu ByteBuffer.
    // Jika formatnya NV21, maka plane.first.bytes sudah cukup.
    // Anda bisa menguji `image.format.group` untuk menentukan bagaimana menggabungkan byte.

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21, // Asumsikan NV21 atau YUV420_888 yang kompatibel dengan NV21
        // Jika formatnya YUV420_888, bytesPerRow adalah bytesPerRow dari plane Y
        bytesPerRow: image.planes[0].bytesPerRow, // Ambil bytesPerRow dari plane Y (plane pertama)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized || !_assetsLoaded) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Memuat kamera dan model...'),
            ],
          ),
        ),
      );
    }

    final currentExercise = _currentExercisePerf!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteksi Gerakan'),
        actions: [
          if (widget.cameras.length > 1)
            IconButton(
              icon: Icon(Icons.flip_camera_ios),
              onPressed: _toggleCamera,
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),
          if (_customPaint != null) _customPaint!,
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gerakan: ${currentExercise.actionName}',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  Text(
                    'Repetisi: ${currentExercise.completedReps} / ${currentExercise.targetReps} (Percobaan: ${currentExercise.completedReps + currentExercise.failedAttempts})',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kualitas: $_currentQualityLabel',
                    style: TextStyle(
                      color: _currentQualityLabel == "Sempurna" ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Instruksi: $_currentInstruction',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'Label Prediksi: $_predictedLabel',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  if (!_isRepComplete)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(
                        value: min(1.0, (DateTime.now().millisecondsSinceEpoch / 1000.0 - _repStartTime) / widget.maxDurationPerRep),
                        backgroundColor: Colors.grey.shade700,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector?.close();
    _interpreter?.close();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }
}