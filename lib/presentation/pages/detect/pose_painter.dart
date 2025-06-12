import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Melukis 33 landmark + beberapa sambungan tulang.
class PosePainter extends CustomPainter {
  const PosePainter({
    required this.poses,
    required this.imageSize,
    required this.isFrontCamera,
  });

  final List<Pose> poses;
  final Size imageSize;          // frame RAW (setelah rotasi tegak)
  final bool isFrontCamera;      // mirror X utk kamera depan

  @override
  void paint(Canvas canvas, Size size) {
    final joint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill
      ..strokeWidth = 4;

    final bone = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final pose in poses) {
      // titik
      for (final lm in pose.landmarks.values) {
        canvas.drawCircle(_map(lm, size), 4, joint);
      }
      // contoh sambungan
      _link(canvas, pose, size, bone,
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      _link(canvas, pose, size, bone,
          PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      _link(canvas, pose, size, bone,
          PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      _link(canvas, pose, size, bone,
          PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
      _link(canvas, pose, size, bone,
          PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
      _link(canvas, pose, size, bone,
          PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
      _link(canvas, pose, size, bone,
          PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
      _link(canvas, pose, size, bone,
          PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    }
  }

  Offset _map(PoseLandmark lm, Size canvas) {
    double nx = lm.x / imageSize.width;
    double ny = lm.y / imageSize.height;
    if (isFrontCamera) nx = 1 - nx;
    return Offset(nx * canvas.width, ny * canvas.height);
  }

  void _link(
      Canvas c,
      Pose p,
      Size s,
      Paint paint,
      PoseLandmarkType a,
      PoseLandmarkType b,
      ) {
    final la = p.landmarks[a];
    final lb = p.landmarks[b];
    if (la == null || lb == null) return;
    c.drawLine(_map(la, s), _map(lb, s), paint);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) => true;
}
