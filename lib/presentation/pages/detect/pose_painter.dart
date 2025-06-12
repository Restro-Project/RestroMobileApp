import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  const PosePainter({
    required this.poses,
    required this.imageSize,
    required this.isFrontCamera,
    this.hideLegs = false,
  });

  final List<Pose> poses;
  final Size imageSize;
  final bool isFrontCamera;
  final bool hideLegs;

  // indeks landmark kaki (23–32)
  bool _isLeg(int idx) => idx >= 23;

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

    for (final p in poses) {
      for (final lm in p.landmarks.values) {
        if (hideLegs && _isLeg(lm.type.index)) continue;
        canvas.drawCircle(_map(lm, size), 4, joint);
      }

      void link(PoseLandmarkType a, PoseLandmarkType b) {
        if (hideLegs && (_isLeg(a.index) || _isLeg(b.index))) return;
        final la = p.landmarks[a], lb = p.landmarks[b];
        if (la == null || lb == null) return;
        canvas.drawLine(_map(la, size), _map(lb, size), bone);
      }

      // lengan
      link(PoseLandmarkType.leftShoulder , PoseLandmarkType.leftElbow);
      link(PoseLandmarkType.leftElbow    , PoseLandmarkType.leftWrist);
      link(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      link(PoseLandmarkType.rightElbow   , PoseLandmarkType.rightWrist);

      // kaki (digambar hanya jika hideLegs==false)
      link(PoseLandmarkType.leftHip , PoseLandmarkType.leftKnee);
      link(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
      link(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
      link(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);
    }
  }

  Offset _map(PoseLandmark lm, Size canvas) {
    double nx = lm.x / imageSize.width;
    double ny = lm.y / imageSize.height;
    if (isFrontCamera) nx = 1 - nx;
    return Offset(nx * canvas.width, ny * canvas.height);
  }

  @override
  bool shouldRepaint(covariant PosePainter old) =>
      old.hideLegs != hideLegs || old.poses != poses;
}
