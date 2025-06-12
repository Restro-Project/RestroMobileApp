import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../home/exercise_performance.dart';
import 'pose_painter.dart';

class DetectPage extends StatefulWidget {
  const DetectPage({
    super.key,
    required this.cameras,
    required this.plannedExercises,   // [{actionName,targetReps}]
    required this.maxDurationPerRep,  // detik
  });

  final List<CameraDescription> cameras;
  final List<Map<String, dynamic>> plannedExercises;
  final int maxDurationPerRep;

  @override
  State<DetectPage> createState() => _DetectPageState();
}

class _DetectPageState extends State<DetectPage> {
  // ═══════════ hyper-parameter ═══════════
  static const int    _seqLen   = 60;
  static const int    _numFeat  = 33 * 2;
  static const double _needConf = .80;
  static const double _holdSec  = 2.0;
  static const int    _prepSec  = 3;
  static const double _thVis    = .35;

  /// gerakan yang hanya butuh badan-atas ⇒ landmark kaki dimask
  final Set<String> _upperBodyOnly = {
    'Rentangkan',
    'Naikan Kepalan Kedepan',
    'Angkat Tangan',
  };

  // ═══════════ kamera & pose ═══════════
  CameraController? _cam;
  PoseDetector?     _pose;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;
  Size? _rawSize;
  int  _camIdx = 0;
  bool get _isFront =>
      widget.cameras[_camIdx].lensDirection == CameraLensDirection.front;

  // ═══════════ TFLite ═══════════
  late Interpreter   _intrp;
  late List<double>  _mean, _scale;
  late List<String>  _actions;
  final _seq = Queue<Float32List>();

  // ═══════════ sesi latihan ═══════════
  final _summary = <ExercisePerformance>[];
  int _exIdx = 0;
  ExercisePerformance? _ex;
  int    _attempt = 1;

  double? _prepEnd;                 // selesai countdown
  double  _repStart = 0;            // mulai timer repetisi
  double  _now      = 0;            // waktu “sekarang” (di-update oleh _ticker)
  double? _perfectStart;
  bool    _repDone  = false;
  bool    _maskLeg  = false;

  String _quality = 'Tidak Terdeteksi';
  String _instr   = 'Bersiap…';
  String _pred    = '…';

  // ═══════════ UI helper ═══════════
  CustomPaint? _overlay;
  Timer? _ticker;
  bool _busy = false, _assetsReady = false;

  // ───────────────── lifecycle ─────────────────
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _initCamera();

    _pose = PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.accurate,
        mode : PoseDetectionMode.stream,
      ),
    );

    await _loadAssets();
    _startExercise();

    _ticker = Timer.periodic(
      const Duration(milliseconds: 80),
          (_) => setState(() => _now = DateTime.now().millisecondsSinceEpoch / 1000),
    );
  }

  // ─────────── camera ───────────
  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) {
      _showErr('Tidak ada kamera'); return;
    }
    _camIdx %= widget.cameras.length;
    final desc = widget.cameras[_camIdx];

    _cam = CameraController(
      desc,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _cam!.initialize();

    _rotation = switch (desc.sensorOrientation) {
      90  => InputImageRotation.rotation90deg,
      180 => InputImageRotation.rotation180deg,
      270 => InputImageRotation.rotation270deg,
      _   => InputImageRotation.rotation0deg,
    };

    await _cam!.startImageStream(_onFrame);
    setState(() {});
  }

  Future<void> _switchCam() async {
    if (widget.cameras.length < 2) return;
    await _cam?.stopImageStream();
    await _cam?.dispose();
    _camIdx = (_camIdx + 1) % widget.cameras.length;
    await _initCamera();
  }

  // ─────────── assets ───────────
  Future<void> _loadAssets() async {
    _intrp = await Interpreter.fromAsset(
      'assets/models/cnn_best.tflite',
      options: InterpreterOptions()..threads = 4,
    );

    _actions = (await rootBundle.loadString('assets/actions.txt'))
        .split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final js = jsonDecode(await rootBundle.loadString('assets/scaler.json'));
    _mean  = (js['mean']  as List).cast<num>().map((e) => e.toDouble()).toList();
    _scale = (js['scale'] as List).cast<num>().map((e) => e.toDouble()).toList();

    setState(() => _assetsReady = true);
  }

  // ─────────── sesi latihan ───────────
  void _startExercise() {
    if (_exIdx >= widget.plannedExercises.length) { _finish(); return; }

    final plan = widget.plannedExercises[_exIdx];
    _ex = ExercisePerformance(
      actionName: plan['actionName'],
      targetReps: plan['targetReps'],
    );
    _maskLeg = _upperBodyOnly.contains(_ex!.actionName);
    _attempt = 1;
    _resetRep(clearSeq: true);
  }

  void _resetRep({bool clearSeq = false}) {
    if (clearSeq) _seq.clear();

    _now = DateTime.now().millisecondsSinceEpoch / 1000;

    _prepEnd      = _attempt == 1 ? _now + _prepSec : null;
    _repStart     = (_prepEnd ?? _now);               // timer mulai setelah countdown
    _perfectStart = null;
    _repDone      = false;
    _quality      = 'Tidak Terdeteksi';
    _instr        = _attempt == 1 ? 'Bersiap…' : 'Ikuti gerakan';
    _pred         = '…';
  }

  void _completeRep(String type) {
    if (_repDone) return;
    _repDone = true;

    _ex!.recordAttempt(type);
    _instr = type == 'Sempurna' ? 'BERHASIL!' : 'WAKTU HABIS!';

    setState(() {});
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_ex!.completedReps + _ex!.failedAttempts < _ex!.targetReps) {
        _attempt++;
        _resetRep();                        // countdown hilang di percobaan berikut
      } else {
        _summary.add(_ex!);
        _exIdx++;
        _startExercise();
      }
    });
  }

  // ─────────── frame loop ───────────
  Future<void> _onFrame(CameraImage img) async {
    if (_busy || !_assetsReady) return;
    _busy = true;

    try {
      final wb = WriteBuffer();
      for (final p in img.planes) wb.putUint8List(p.bytes);
      final bytes = wb.done().buffer.asUint8List();

      final input = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(img.width.toDouble(), img.height.toDouble()),
          rotation: _rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: img.planes.first.bytesPerRow,
        ),
      );

      final poses = await _pose!.processImage(input);

      _rawSize ??= (_rotation == InputImageRotation.rotation90deg ||
          _rotation == InputImageRotation.rotation270deg)
          ? Size(img.height.toDouble(), img.width.toDouble())
          : Size(img.width.toDouble(),  img.height.toDouble());

      // update buffer
      _seq.add(
        poses.isNotEmpty && poses.first.landmarks.length == 33
            ? _vecFromPose(poses.first)
            : Float32List(_numFeat),
      );
      if (_seq.length > _seqLen) _seq.removeFirst();

      final ready = (_prepEnd == null || _now >= _prepEnd!) &&
          _seq.length == _seqLen;
      if (ready) _runModel();

      if (_prepEnd != null && _now >= _prepEnd! && _instr.startsWith('Bersi')) {
        _instr = 'Ikuti gerakan';
      }

      _overlay = poses.isEmpty
          ? null
          : CustomPaint(
        painter: PosePainter(
          poses: poses,
          imageSize: _rawSize!,
          isFrontCamera: _isFront,
          hideLegs: _maskLeg,
        ),
      );
      setState(() {});
    } finally {
      _busy = false;
    }
  }

  // ─────────── landmark → fitur ───────────
  Float32List _vecFromPose(Pose pose) {
    final lms = pose.landmarks.values.toList()
      ..sort((a, b) => a.type.index.compareTo(b.type.index));

    final v = Float32List(_numFeat);
    final mirror = _isFront;

    for (int i = 0; i < 33; i++) {
      // indeks dalam vektor rata (untuk meng-akses _mean)
      final ixX = i * 2, ixY = i * 2 + 1;

      final bool legPart  = i >= 23;
      final bool masked   = _maskLeg && legPart;
      final bool invisible = lms[i].likelihood < _thVis;

      if (masked || invisible) {
        // gunakan nilai mean asli supaya (x-µ)/σ = 0 sesudah normalisasi
        v[ixX] = _mean[ixX];
        v[ixY] = _mean[ixY];
        continue;
      }

      double nx = lms[i].x / _rawSize!.width;
      double ny = lms[i].y / _rawSize!.height;
      if (mirror) nx = 1 - nx;

      v[ixX] = nx;
      v[ixY] = ny;
    }
    return v;
  }

  // ─────────── inference ───────────
  void _runModel() {
    final flat = Float32List(_seqLen * _numFeat);
    int k = 0;
    for (final f in _seq) { flat.setRange(k, k + _numFeat, f); k += _numFeat; }

    final scaled = Float32List(flat.length);
    for (int i = 0; i < flat.length; i++) {
      final j = i % _numFeat;
      scaled[i] = (flat[i] - _mean[j]) / (_scale[j] + 1e-8);
    }

    final input = [
      List.generate(_seqLen,
              (t) => scaled.sublist(t * _numFeat, (t + 1) * _numFeat).toList())
    ];
    final output = [List.filled(_actions.length, 0.0)];
    _intrp.run(input, output);

    final probs = List<double>.from(output[0]);
    final best  = probs.indexWhere((e) => e == probs.reduce(math.max));

    _pred = _actions[best];
    _updateState(probs[best]);
  }

  void _updateState(double conf) {
    if (_ex == null ||
        _repDone ||
        (_prepEnd != null && _now < _prepEnd!)) return;

    if (_pred == _ex!.actionName && conf >= _needConf) {
      _quality = 'Sempurna';
      _instr   = 'TAHAN!';
      _perfectStart ??= _now;
      if (_now - _perfectStart! >= _holdSec) _completeRep('Sempurna');
    } else {
      _quality = 'Belum Tepat';
      _instr   = 'Ikuti gerakan';
      _perfectStart = null;
    }

    if (_now - _repStart > widget.maxDurationPerRep) {
      _completeRep('Waktu Habis');
    }
  }

  // ─────────── UI ───────────
  @override
  Widget build(BuildContext context) {
    if (_cam == null || !_cam!.value.isInitialized || !_assetsReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final ex     = _ex!;
    final inPrep = _prepEnd != null && _now < _prepEnd!;
    final double prog = inPrep
        ? 0.0
        : math.min(1.0, (_now - _repStart) / widget.maxDurationPerRep);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteksi Gerakan'),
        actions: [
          if (widget.cameras.length > 1)
            IconButton(icon: const Icon(Icons.cameraswitch), onPressed: _switchCam),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cam!),
          if (_overlay != null) _overlay!,
          _bottom(ex, prog, inPrep),
        ],
      ),
    );
  }

  Widget _bottom(ExercisePerformance ex, double prog, bool inPrep) => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black.withOpacity(.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Gerakan: ${ex.actionName}',
              style: const TextStyle(color: Colors.white, fontSize: 20)),
          Text('Repetisi: ${ex.completedReps}/${ex.targetReps} (Percobaan: $_attempt)',
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 6),
          if (inPrep) ...[
            Text('Bersiap…  ${(_prepEnd! - _now).ceil()}',
                style: const TextStyle(color: Colors.amber, fontSize: 24)),
          ] else ...[
            Text('Kualitas: $_quality',
                style: TextStyle(
                    color: _quality == 'Sempurna'
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Instruksi: $_instr',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            Text('Prediksi: $_pred',
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
          if (!_repDone && !inPrep)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(
                value: prog,
                backgroundColor: Colors.grey.shade700,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
              ),
            ),
        ],
      ),
    ),
  );

  // ───────── util ─────────
  void _showErr(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _finish() {
    _ticker?.cancel();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sesi Selesai'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _summary
              .map((e) => Text('${e.actionName}: ${e.completedReps} ok / ${e.failedAttempts} gagal'))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cam?.dispose();
    _pose?.close();
    _intrp.close();
    _ticker?.cancel();
    super.dispose();
  }
}