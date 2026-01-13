import 'package:flutter/material.dart';

/// Draw a checkerboard background (representing transparent).
class CheckerBoardPainter extends CustomPainter {
  final double cellSize;
  final Color darkColor;
  final Color lightColor;

  CheckerBoardPainter({
    this.cellSize = 8.0,
    this.darkColor = const Color(0xFFE0E0E0),
    this.lightColor = const Color(0xFFFFFFFF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int hCount = (size.width / cellSize).ceil();
    final int vCount = (size.height / cellSize).ceil();

    // Fill background with light color
    canvas.drawRect(Offset.zero & size, Paint()..color = lightColor);

    // Draw dark cells only
    final Paint darkPaint = Paint()..color = darkColor;

    for (int i = 0; i < hCount; i++) {
      for (int j = 0; j < vCount; j++) {
        if ((i + j) % 2 == 1) {
          canvas.drawRect(
            Rect.fromLTWH(i * cellSize, j * cellSize, cellSize, cellSize),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
