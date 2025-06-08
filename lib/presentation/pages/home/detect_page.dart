import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:collection'; // For deque equivalent
import 'dart:ui' show Offset, Paint, Canvas, Rect, Size, TextPainter, TextSpan, Color; // Explicitly import Color

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // For loading assets
import 'package:image/image.dart' as im;
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class DetectPage extends StatefulWidget {
  const DetectPage({super.key});
  @override
  State<DetectPage> createState() => _DetectPageState();
}

/*──────────────────────────────────────────────────────────────────────────*/
class _DetectPageState extends State<DetectPage> with WidgetsBindingObserver {
  /* ─── runtime object ─────────────────────────────────────────────────── */
  late Interpreter _poseInterpreter;
  late Interpreter _cnnInterpreter;
  late List<int> _poseInShape; // [1,640,640,3]
  CameraController? _cam; // Changed to nullable
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIdx = 0; // 0 for back, 1 for front (or depends on availableCameras order)
  bool _isCameraInitialized = false;
  bool _busy = false;
  CameraLensDirection _currentCameraLensDirection = CameraLensDirection.back;


  /* deteksi pose terbaru */
  final _poses = ValueNotifier<List<_PoseDetect>>(<_PoseDetect>[]);

  // Actual resolution of the camera image stream (e.g., 480x640 or 1080x1920)
  // This will be used to correctly map model output back to camera preview
  Size? _cameraImageSize;

  // Scaler values for CNN input normalization
  List<double> _scalerMean = [];
  List<double> _scalerScale = [];

  // MODIFIED: Changed _sequenceLength from 1 to 60 to match Python code
  static const int _sequenceLength = 60;
  static const int _numFeatures = 17 * 2; // 17 keypoints * (x,y)
  final Queue<Float32List> _keypointSequenceBuffer = Queue<Float32List>();

  List<String> _actionLabels = [];
  String _currentPredictedAction = "Mengumpulkan data...";
  double _currentConfidence = 0.0;
  static const double _confidenceThresholdCnn = 0.5;

  /* ─── boot ───────────────────────────────────────────────────────────── */
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  Future<void> _boot() async {
    // 1. izin kamera
    if (!await Permission.camera.request().isGranted) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // 2. Load available cameras
    _availableCameras = await availableCameras();
    if (_availableCameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cameras found.')),
        );
        Navigator.pop(context);
      }
      return;
    }

    // Initialize camera with the selected lens direction
    _currentCameraLensDirection = CameraLensDirection.back;
    _selectedCameraIdx = _availableCameras.indexWhere((e) => e.lensDirection == _currentCameraLensDirection);
    if (_selectedCameraIdx == -1) {
      _selectedCameraIdx = 0; // Fallback to the first camera if back camera not found
      _currentCameraLensDirection = _availableCameras[_selectedCameraIdx].lensDirection;
    }

    await _initializeCamera(_availableCameras[_selectedCameraIdx]);

    // 3. interpreter tflite
    try {
      _poseInterpreter = await Interpreter.fromAsset(
        'assets/models/yolo11n-pose_float32.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      _poseInShape = _poseInterpreter.getInputTensor(0).shape; // [1,640,640,3]

      _cnnInterpreter = await Interpreter.fromAsset(
        'assets/models/cnn.tflite',
        options: InterpreterOptions()..threads = 2,
      );
    } catch (e) {
      print("Error loading TFLite models: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading TFLite models: $e')),
        );
      }
      return;
    }

    // 4. Load assets (actions.txt, scaler_mean.txt, scaler_scale.txt)
    try {
      String actionsContent = await rootBundle.loadString('assets/actions.txt');
      _actionLabels = actionsContent.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      print("Actions loaded: $_actionLabels");

      // Load scaler mean
      String scalerMeanContent = await rootBundle.loadString('assets/scaler_mean.txt');
      // Splitting by space and then trimming and parsing
      _scalerMean = scalerMeanContent.split(RegExp(r'\s+')).map((e) => double.tryParse(e.trim()) ?? 0.0).where((e) => e != 0.0).toList();
      // Adjusting _numFeatures based on actual loaded mean length if there's a discrepancy
      if (_scalerMean.length != _numFeatures) {
        print("Warning: scaler_mean.txt has incorrect number of features. Expected $_numFeatures, got ${_scalerMean.length}");
        // Fallback to zeros if mismatch, or you might want to throw an error
        _scalerMean = List.filled(_numFeatures, 0.0);
      }

      // Load scaler scale (standard deviation)
      String scalerScaleContent = await rootBundle.loadString('assets/scaler_scale.txt');
      // Splitting by space and then trimming and parsing
      _scalerScale = scalerScaleContent.split(RegExp(r'\s+')).map((e) => double.tryParse(e.trim()) ?? 1.0).where((e) => e != 1.0).toList();
      // Adjusting _numFeatures based on actual loaded scale length if there's a discrepancy
      if (_scalerScale.length != _numFeatures) {
        print("Warning: scaler_scale.txt has incorrect number of features. Expected $_numFeatures, got ${_scalerScale.length}");
        // Fallback to ones if mismatch, or you might want to throw an error
        _scalerScale = List.filled(_numFeatures, 1.0);
      }

    } catch (e) {
      print("Error loading assets: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assets: $e. Make sure models and actions.txt/scaler files are in assets/')),
        );
      }
      return;
    }

    // Initialize keypoint buffer with zeros
    for (int i = 0; i < _sequenceLength; i++) {
      _keypointSequenceBuffer.add(Float32List(_numFeatures));
    }
  }

  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    // Dispose of previous camera controller if it exists
    if (_cam != null && _cam!.value.isInitialized) { // Check if _cam is not null
      await _cam!.dispose(); // Use null-safe operator
    }

    _cam = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cam!.initialize(); // Use null-safe operator
      if (_cam!.value.previewSize == null) { // Use null-safe operator
        throw Exception("Camera preview size is null after initialization.");
      }
      _cameraImageSize = Size(
        _cam!.value.previewSize!.width, // Use null-safe operator
        _cam!.value.previewSize!.height, // Use null-safe operator
      );
      print("Camera initialized. Preview Size: $_cameraImageSize");

      // Start the image stream only after the camera is fully initialized and widget is mounted
      if (mounted) {
        await _cam!.startImageStream(_onFrame); // Use null-safe operator
      }
      setState(() {
        _isCameraInitialized = true;
        _currentCameraLensDirection = cameraDescription.lensDirection; // Update current lens direction
      });
    } catch (e) {
      print("Error initializing camera: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
        Navigator.pop(context); // Go back if camera fails to initialize
      }
      setState(() {
        _isCameraInitialized = false;
      });
      return;
    }
  }

  void _toggleCamera() async {
    if (_availableCameras.length < 2) return; // No other camera to switch to

    setState(() {
      _isCameraInitialized = false; // Set to false to show loading indicator
    });

    // Stop existing camera stream
    if (_cam != null && _cam!.value.isStreamingImages) { // Check for null
      await _cam!.stopImageStream(); // Use null-safe operator
    }
    await _cam?.dispose(); // Use null-safe operator

    // Toggle selected camera index
    _selectedCameraIdx = (_selectedCameraIdx + 1) % _availableCameras.length;
    final newCameraDescription = _availableCameras[_selectedCameraIdx];

    // Re-initialize camera with the new selection
    await _initializeCamera(newCameraDescription);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isCameraInitialized || _cam == null) return; // Check if _cam is null
    if (state == AppLifecycleState.inactive) {
      _cam!.stopImageStream(); // Use null-safe operator
    } else if (state == AppLifecycleState.resumed) {
      // Ensure the camera is not already streaming before starting it again
      if (!_cam!.value.isStreamingImages) { // Use null-safe operator
        _cam!.startImageStream(_onFrame); // Use null-safe operator
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poses.dispose();
    _cam?.dispose(); // Use null-safe operator
    _poseInterpreter.close();
    _cnnInterpreter.close();
    super.dispose();
  }

  /* ─── frame handler ──────────────────────────────────────────────────── */
  void _onFrame(CameraImage img) async {
    if (_busy) return;
    _busy = true;

    // Offload YUV to RGB conversion
    final rgbBytes = await compute(_yuv420toRgb, img);

    // a. RGB -> Image package
    final srcImg = im.Image.fromBytes(
      width: img.width,
      height: img.height,
      bytes: rgbBytes.buffer,
      order: im.ChannelOrder.rgb,
    );

    // b. letterbox (square) & resize → 640×640
    final inputSize = _poseInShape[1]; // 640
    final shorter = math.min(srcImg.width, srcImg.height);
    final cropped = im.copyCrop(
      srcImg,
      x: (srcImg.width - shorter) ~/ 2,
      y: (srcImg.height - shorter) ~/ 2,
      width: shorter,
      height: shorter,
    );
    final resized = im.copyResize(cropped,
        width: inputSize, height: inputSize, interpolation: im.Interpolation.linear);

    // c. NHWC float32 0-1
    final input = Float32List(1 * inputSize * inputSize * 3);
    int idx = 0;
    for (final px in resized) {
      input[idx++] = px.r / 255.0;
      input[idx++] = px.g / 255.0;
      input[idx++] = px.b / 255.0;
    }

    // d. run pose inference
    final reshapedInput = input.reshape([1, inputSize, inputSize, 3]);
    final poseOutputShape = _poseInterpreter.getOutputTensor(0).shape;
    // Example: [1, 56, 8400] for YOLOv8-pose
    // Here, 56 is the number of features per detection (bbox + keypoints)
    // 8400 is the number of potential detections (anchor points)

    // Initialize output buffer for pose model
    // The output tensor from TFLite interpreter for YOLOv8-pose is often
    // [1, num_features_per_detection, num_detections]
    // So, poseOutput[0] will be [num_features_per_detection, num_detections]
    var poseOutput = List.generate(
      poseOutputShape[0], // batch size (1)
          (i) => List.generate(
        poseOutputShape[1], // num_features_per_detection (56)
            (j) => List.filled(poseOutputShape[2], 0.0), // num_detections (8400)
      ),
    );

    try {
      _poseInterpreter.run(reshapedInput, poseOutput);
    } catch (e) {
      print("Error running pose inference: $e");
      _busy = false;
      return;
    }

    // e. decode pose detections
    _poses.value = _decodePose(poseOutput[0], inputSize);

    // --- Action Classification Logic ---
    if (_poses.value.isNotEmpty) {
      // Assuming we only care about the first detected person for action classification
      final _PoseDetect firstPose = _poses.value.first;
      final Float32List currentKeypoints = Float32List(_numFeatures);

      // Normalize keypoints to 0-1 range based on the inputSize (640x640)
      for (int i = 0; i < 17; i++) {
        currentKeypoints[i * 2] = firstPose.kps[i].dx / inputSize; // normalized X
        currentKeypoints[i * 2 + 1] = firstPose.kps[i].dy / inputSize; // normalized Y
      }

      _keypointSequenceBuffer.addLast(currentKeypoints);
      if (_keypointSequenceBuffer.length > _sequenceLength) {
        _keypointSequenceBuffer.removeFirst();
      }

      // This condition now becomes true immediately if _sequenceLength is 1
      if (_keypointSequenceBuffer.length == _sequenceLength) {
        // Flatten the buffer into a 2D array for scaling
        final Float32List seqInputRaw = Float32List(_sequenceLength * _numFeatures);
        int seqIdx = 0;
        for (final kps in _keypointSequenceBuffer) {
          for (int i = 0; i < _numFeatures; i++) {
            seqInputRaw[seqIdx++] = kps[i];
          }
        }

        // Apply scaler (re-implementation of StandardScaler)
        final Float32List inputScaledFlat = Float32List(_sequenceLength * _numFeatures);
        for (int i = 0; i < _sequenceLength * _numFeatures; i++) {
          // Check if _scalerMean and _scalerScale have enough elements
          if (_scalerMean.length > (i % _numFeatures) && _scalerScale.length > (i % _numFeatures) && _scalerScale[i % _numFeatures] != 0) {
            inputScaledFlat[i] = (seqInputRaw[i] - _scalerMean[i % _numFeatures]) / _scalerScale[i % _numFeatures];
          } else {
            inputScaledFlat[i] = 0.0; // Fallback if scaler data is missing or zero
          }
        }

        // Reshape for CNN input [1, SEQUENCE_LENGTH, NUM_FEATURES]
        final List<List<List<double>>> cnnInput = [
          List.generate(_sequenceLength, (s) => List.generate(_numFeatures, (f) => inputScaledFlat[s * _numFeatures + f]))
        ];

        // Prepare CNN output
        final cnnOutputShape = _cnnInterpreter.getOutputTensor(0).shape; // e.g., [1, num_actions]
        final cnnOutput = List.filled(cnnOutputShape[0] * cnnOutputShape[1], 0.0).reshape(cnnOutputShape);

        try {
          _cnnInterpreter.run(cnnInput, cnnOutput);

          // Process CNN output
          final List<double> probabilities = cnnOutput[0].cast<double>();
          double maxProb = -1.0;
          int predictedIndex = -1;
          for (int i = 0; i < probabilities.length; i++) {
            if (probabilities[i] > maxProb) {
              maxProb = probabilities[i];
              predictedIndex = i;
            }
          }


          if (maxProb >= _confidenceThresholdCnn && predictedIndex != -1 && predictedIndex < _actionLabels.length) {
            _currentPredictedAction = _actionLabels[predictedIndex];
            _currentConfidence = maxProb;
          } else {
            _currentPredictedAction = "Tidak Yakin";
            _currentConfidence = maxProb;
          }
        } catch (e) {
          print("Error running CNN inference: $e");
          _currentPredictedAction = "Error CNN";
          _currentConfidence = 0.0;
        }
      } else {
        _currentPredictedAction = "Buffer: ${_keypointSequenceBuffer.length}/$_sequenceLength";
        _currentConfidence = 0.0;
      }
    } else {
      _currentPredictedAction = "Tidak ada orang terdeteksi";
      _currentConfidence = 0.0;
    }

    _busy = false;
    if (mounted) setState(() {}); // Trigger rebuild to show latest prediction
  }

  /* ─── util : YUV420 -> RGB Uint8List order RGBRGB… ─────────────────────── */
  static Uint8List _yuv420toRgb(CameraImage img) {
    final w = img.width, h = img.height;
    final uvRowStride = img.planes[1].bytesPerRow;
    final uvPixelStride = img.planes[1].bytesPerPixel!;
    final out = Uint8List(w * h * 3);
    int outIdx = 0;
    for (int y = 0; y < h; y++) {
      final yRow = y * img.planes[0].bytesPerRow;
      final uvRow = (y >> 1) * uvRowStride;
      for (int x = 0; x < w; x++) {
        final uvIndex = uvRow + (x >> 1) * uvPixelStride;
        final yPixel = img.planes[0].bytes[yRow + x];
        final uPixel = img.planes[1].bytes[uvIndex];
        final vPixel = img.planes[2].bytes[uvIndex];

        final c = yPixel - 16;
        final d = uPixel - 128;
        final e = vPixel - 128;

        int r = (298 * c + 409 * e + 128) >> 8;
        int g = (298 * c - 100 * d - 208 * e + 128) >> 8;
        int b = (298 * c + 516 * d + 128) >> 8;
        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        out[outIdx++] = r.toUnsigned(8);
        out[outIdx++] = g.toUnsigned(8);
        out[outIdx++] = b.toUnsigned(8);
      }
    }
    return out;
  }

  /* ─── util : decode pose ─────────────────────────────────── */
  List<_PoseDetect> _decodePose(List<List<double>> rawDetections, int imgSize) {
    final poses = <_PoseDetect>[];
    const double confThreshold = 0.25; // Adjusted to a more common YOLO threshold

    // MODIFIED: Decoding logic to handle rawDetections from TFLite YOLOv8-pose output
    // Asumsi rawDetections berbentuk [num_features, num_detections]
    // Misalnya, [56, 8400] di mana 56 adalah (cx, cy, w, h, conf, 17*3 keypoints)
    final int numDetections = rawDetections[0].length; // 8400
    final int numFeaturesPerDetection = rawDetections.length; // 56

    // Pastikan memiliki cukup fitur untuk bbox + keypoints
    if (numFeaturesPerDetection < 5 + 17 * 3) {
      print("Warning: Insufficient features per detection in pose output. Expected at least ${5 + 17 * 3}, got $numFeaturesPerDetection");
      return poses;
    }

    // Buat list deteksi dalam format yang mudah diolah (list of lists of doubles)
    // Setiap inner list adalah [cx, cy, w, h, conf, kp1_x, kp1_y, kp1_conf, ...]
    List<List<double>> detections = [];
    for (int i = 0; i < numDetections; i++) {
      List<double> currentDet = [];
      for (int j = 0; j < numFeaturesPerDetection; j++) {
        currentDet.add(rawDetections[j][i]);
      }
      detections.add(currentDet);
    }

    // Sort detections by confidence in descending order
    // This helps in picking the most confident detection if multiple are present
    detections.sort((a, b) => b[4].compareTo(a[4]));

    for (final det in detections) {
      final double conf = det[4];
      if (conf < confThreshold) continue;

      // Extract raw (normalized) bounding box coordinates and keypoints
      final double cx_norm = det[0];
      final double cy_norm = det[1];
      final double w_norm = det[2];
      final double h_norm = det[3];

      // Convert normalized (0-1) box coordinates to image coordinates (0-640)
      // These are relative to the input image (640x640)
      final rect = Rect.fromLTWH(
        (cx_norm - w_norm / 2) * imgSize,
        (cy_norm - h_norm / 2) * imgSize,
        w_norm * imgSize,
        h_norm * imgSize,
      );

      final kps = <Offset>[];
      // Keypoints start from index 5
      for (int i = 0; i < 17; i++) {
        final x = det[5 + i * 3] * imgSize;
        final y = det[5 + i * 3 + 1] * imgSize;
        final kpConf = det[5 + i * 3 + 2]; // Keypoint confidence
        if (kpConf > 0.3) { // You can adjust this keypoint confidence threshold
          kps.add(Offset(x, y));
        } else {
          kps.add(Offset.zero); // Or a special value to indicate low confidence
        }
      }

      // If a detection is valid, add it to the list
      poses.add(_PoseDetect(rect, kps, conf));
      // Only take the most confident detection for simplicity if needed
      // if (poses.isNotEmpty) break;
    }
    return poses;
  }


  /* ─── UI ──────────────────────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraImageSize == null || _cam == null) { // Check _cam for null
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    // final double screenHeight = MediaQuery.of(context).size.height; // Not used
    final double cameraAspectRatio = _cam!.value.aspectRatio; // Use null-safe operator

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pose Detection & Action Classification'),
        actions: [
          IconButton(
            icon: Icon(Icons.flip_camera_ios),
            onPressed: _toggleCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: cameraAspectRatio,
              child: Stack(
                children: [
                  CameraPreview(_cam!), // Use null-safe operator
                  // Overlay for predictions and confidence
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black54,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PREDIKSI MODEL: $_currentPredictedAction',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Text(
                            'CONFIDENCE: ${(_currentConfidence * 100).toStringAsFixed(2)}%',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // CustomPaint for drawing detections
                  ValueListenableBuilder<List<_PoseDetect>>(
                    valueListenable: _poses,
                    builder: (_, list, __) {
                      return CustomPaint(
                        size: Size(screenWidth, screenWidth / cameraAspectRatio),
                        painter: _Painter(
                          list,
                          cameraImageSize: _cameraImageSize!,
                          modelInputSize: _poseInShape[1].toDouble(),
                          previewSize: Size(screenWidth, screenWidth / cameraAspectRatio),
                          cameraLensDirection: _currentCameraLensDirection, // Pass camera lens direction
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ─── data & painter ───────────────────────────────────────────────────── */
class _PoseDetect {
  _PoseDetect(this.rect, this.kps, this.score);
  final Rect rect;
  final List<Offset> kps;
  final double score;
}

class _Painter extends CustomPainter {
  _Painter(this.list, {
    required this.cameraImageSize,
    required this.modelInputSize,
    required this.previewSize,
    required this.cameraLensDirection, // Receive camera lens direction
  });

  final List<_PoseDetect> list;
  final Size cameraImageSize; // Original camera frame size (e.g., 480x640)
  final double modelInputSize; // Original model input size (640.0)
  final Size previewSize; // The size of the CameraPreview widget on screen
  final CameraLensDirection cameraLensDirection; // Store camera lens direction

  final pBox = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.blue;
  final pKp = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red;
  final pSkel = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = Colors.green;

  final skeletonConnections = const [
    [0, 1], [0, 2], [1, 3], [2, 4], // Hidung ke mata & telinga
    [0, 5], [0, 6], [5, 6], // Hidung ke bahu, antar bahu
    [5, 7], [7, 9], // Bahu kiri ke siku ke pergelangan tangan
    [6, 8], [8, 10], // Bahu kanan ke siku ke pergelangan tangan
    [5, 11], [6, 12], [11, 12], // Bahu ke pinggul, antar pinggul
    [11, 13], [13, 15], // Pinggul kiri ke lutut ke pergelangan kaki
    [12, 14], [14, 16], // Pinggul kanan ke lutut ke pergelangan kaki
  ];

  @override
  void paint(Canvas c, Size s) {
    final double cameraWidth = cameraImageSize.width;
    final double cameraHeight = cameraImageSize.height;

    // Calculate the crop dimensions applied during preprocessing (letterboxing)
    // The cropped image is a square of `shorterCameraDim` size
    final double shorterCameraDim = math.min(cameraWidth, cameraHeight);
    final double xOffsetOriginalCrop = (cameraWidth - shorterCameraDim) / 2;
    final double yOffsetOriginalCrop = (cameraHeight - shorterCameraDim) / 2;

    // Scale factor from the model's 640x640 input to the *cropped* camera image
    final double modelToCroppedScale = shorterCameraDim / modelInputSize;

    // Calculate the overall scale from the original camera frame to the preview widget on screen
    // This ensures detections are drawn correctly regardless of camera orientation or preview scaling
    final double scaleX = previewSize.width / cameraWidth;
    final double scaleY = previewSize.height / cameraHeight;
    final double finalScale = math.min(scaleX, scaleY);

    // Calculate offsets to center the camera preview within the CustomPaint area
    // This is needed if the camera preview itself is letterboxed by Flutter's AspectRatio/FittedBox
    final double renderedPreviewWidth = cameraWidth * finalScale;
    final double renderedPreviewHeight = cameraHeight * finalScale;
    final double offsetX_preview = (s.width - renderedPreviewWidth) / 2;
    final double offsetY_preview = (s.height - renderedPreviewHeight) / 2;

    c.save(); // Save the current canvas state

    // If it's a front camera, mirror the canvas horizontally
    if (cameraLensDirection == CameraLensDirection.front) {
      // Translate to the center of the rendered preview
      c.translate(renderedPreviewWidth + offsetX_preview * 2, 0); // Translate to the right edge of the preview
      c.scale(-1.0, 1.0); // Mirror horizontally
    }

    for (final d in list) {
      // 1. Convert model output coordinates (0-modelInputSize) to coordinates relative to the *cropped* camera image
      final double detLeftCropped = d.rect.left * modelToCroppedScale;
      final double detTopCropped = d.rect.top * modelToCroppedScale;
      final double detWidthCropped = d.rect.width * modelToCroppedScale;
      final double detHeightCropped = d.rect.height * modelToCroppedScale;

      // 2. Add back the original crop offsets to get coordinates relative to the *full* original camera image
      final double detLeftFullCamera = detLeftCropped + xOffsetOriginalCrop;
      final double detTopFullCamera = detTopCropped + yOffsetOriginalCrop;

      // 3. Scale these full camera image coordinates to the *display size* and apply final offsets for centering
      final scaledRect = Rect.fromLTWH(
        detLeftFullCamera * finalScale + offsetX_preview,
        detTopFullCamera * finalScale + offsetY_preview,
        detWidthCropped * finalScale,
        detHeightCropped * finalScale,
      );
      c.drawRect(scaledRect, pBox);

      // Draw "person" text
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'person',
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black54,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(c, Offset(scaledRect.left, scaledRect.top - textPainter.height - 2));

      // Skeleton and Keypoints
      for (final conn in skeletonConnections) {
        final Offset p1_raw = d.kps[conn[0]];
        final Offset p2_raw = d.kps[conn[1]];

        // Transform keypoint coordinates similarly
        final Offset p1_fullCamera = Offset(
          p1_raw.dx * modelToCroppedScale + xOffsetOriginalCrop,
          p1_raw.dy * modelToCroppedScale + yOffsetOriginalCrop,
        );
        final Offset p2_fullCamera = Offset(
          p2_raw.dx * modelToCroppedScale + xOffsetOriginalCrop,
          p2_raw.dy * modelToCroppedScale + yOffsetOriginalCrop,
        );

        final p1_scaled = Offset(
          p1_fullCamera.dx * finalScale + offsetX_preview,
          p1_fullCamera.dy * finalScale + offsetY_preview,
        );
        final p2_scaled = Offset(
          p2_fullCamera.dx * finalScale + offsetX_preview,
          p2_fullCamera.dy * finalScale + offsetY_preview,
        );
        c.drawLine(p1_scaled, p2_scaled, pSkel);
      }

      for (final k in d.kps) {
        // Only draw keypoints if they are not Offset.zero (i.e., had sufficient confidence)
        if (k != Offset.zero) {
          final scaledKp = Offset(
            (k.dx * modelToCroppedScale + xOffsetOriginalCrop) * finalScale + offsetX_preview,
            (k.dy * modelToCroppedScale + yOffsetOriginalCrop) * finalScale + offsetY_preview,
          );
          c.drawCircle(scaledKp, 3 * finalScale, pKp);
        }
      }

      // Draw Score (Confidence)
      final tp = TextPainter(
        text: TextSpan(
            text: d.score.toStringAsFixed(2),
            style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                backgroundColor: Colors.black54)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, scaledRect.topLeft.translate(0, scaledRect.height + 2));
    }
    c.restore(); // Restore the canvas state
  }

  @override
  bool shouldRepaint(_Painter old) =>
      old.list != list ||
          old.cameraImageSize != cameraImageSize ||
          old.previewSize != previewSize ||
          old.cameraLensDirection != cameraLensDirection; // Add cameraLensDirection to repaint check
}