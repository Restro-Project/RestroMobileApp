import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;

  PosePainter(this.poses, this.imageSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.blueAccent;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0
      ..color = Colors.blueAccent;

    // Helper to scale landmark coordinates
    void paintLandmark(Offset point) {
      canvas.drawCircle(point, 6, dotPaint);
    }

    // Helper to paint connections
    void paintConnection(Offset start, Offset end) {
      canvas.drawLine(start, end, paint);
    }

    for (final pose in poses) {
      // Draw all landmarks
      for (final landmark in pose.landmarks.values) {
        final point = _scaleAndRotate(
            landmark.x, landmark.y, imageSize, size, rotation);
        paintLandmark(point);
      }

      // Draw connections for various body parts
      _drawConnections(canvas, paint, pose, imageSize, size, rotation);
    }
  }

  void _drawConnections(Canvas canvas, Paint paint, Pose pose, Size imageSize,
      Size canvasSize, InputImageRotation rotation) {
    final List<List<PoseLandmarkType>> connections = [
      // Torso
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],

      // Left Arm
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb],
      [PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky],
      [PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex],
      [PoseLandmarkType.leftIndex, PoseLandmarkType.leftPinky],

      // Right Arm
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      [PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb],
      [PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky],
      [PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex],
      [PoseLandmarkType.rightIndex, PoseLandmarkType.rightPinky],

      // Left Leg
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel],
      [PoseLandmarkType.leftHeel, PoseLandmarkType.leftFootIndex],
      [PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex],

      // Right Leg
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
      [PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel],
      [PoseLandmarkType.rightHeel, PoseLandmarkType.rightFootIndex],
      [PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex],

      // Face (simplified)
      [PoseLandmarkType.nose, PoseLandmarkType.leftEyeInner],
      [PoseLandmarkType.leftEyeInner, PoseLandmarkType.leftEye],
      [PoseLandmarkType.leftEye, PoseLandmarkType.leftEyeOuter],
      [PoseLandmarkType.leftEyeOuter, PoseLandmarkType.rightEyeOuter], // Across nose
      [PoseLandmarkType.rightEyeOuter, PoseLandmarkType.rightEye],
      [PoseLandmarkType.rightEye, PoseLandmarkType.rightEyeInner],
      [PoseLandmarkType.rightEyeInner, PoseLandmarkType.nose],
      [PoseLandmarkType.leftEyeOuter, PoseLandmarkType.leftEar],
      [PoseLandmarkType.rightEyeOuter, PoseLandmarkType.rightEar],
      [PoseLandmarkType.leftEar, PoseLandmarkType.rightEar],
    ];

    for (var connection in connections) {
      final startLandmark = pose.landmarks[connection[0]];
      final endLandmark = pose.landmarks[connection[1]];

      if (startLandmark != null && endLandmark != null) {
        final start = _scaleAndRotate(
            startLandmark.x, startLandmark.y, imageSize, canvasSize, rotation);
        final end = _scaleAndRotate(
            endLandmark.x, endLandmark.y, imageSize, canvasSize, rotation);
        canvas.drawLine(start, end, paint);
      }
    }
  }

  Offset _scaleAndRotate(double x, double y, Size imageSize, Size canvasSize,
      InputImageRotation rotation) {
    double scaleX = canvasSize.width / imageSize.width;
    double scaleY = canvasSize.height / imageSize.height;

    // Apply rotation and mirroring based on camera setup
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return Offset(y * scaleY, (imageSize.width - x) * scaleX);
      case InputImageRotation.rotation270deg:
        return Offset((imageSize.height - y) * scaleY, x * scaleX);
      case InputImageRotation.rotation180deg:
        return Offset((imageSize.width - x) * scaleX, (imageSize.height - y) * scaleY);
      case InputImageRotation.rotation0deg:
      default:
      // Assume front camera, so mirror X
        return Offset((imageSize.width - x) * scaleX, y * scaleY);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}