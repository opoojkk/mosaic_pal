import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> currentStroke;
  final double brushSize;
  final bool isDrawing;

  ImagePainter({
    required this.image,
    required this.currentStroke,
    required this.brushSize,
    required this.isDrawing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());

    if (isDrawing && currentStroke.isNotEmpty) {
      final strokePaint = Paint()
        ..color = Colors.red.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = brushSize
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (currentStroke.length > 1) {
        final path = Path()..moveTo(currentStroke.first.dx, currentStroke.first.dy);
        for (int i = 1; i < currentStroke.length; i++) {
          path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
        }
        canvas.drawPath(path, strokePaint);
      }

      final previewPaint = Paint()
        ..color = Colors.red.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(currentStroke.last, brushSize / 2, previewPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
