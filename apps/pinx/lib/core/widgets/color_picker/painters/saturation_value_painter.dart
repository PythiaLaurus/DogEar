import 'package:flutter/material.dart';

/// Draw the saturation(X-axis) / value(Y-axis) square selection area.
class SaturationValuePainter extends CustomPainter {
  final HSVColor hsvColor;

  const SaturationValuePainter({required this.hsvColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // Vertical gradient: transparent -> black (Value)
    const Gradient gradientV = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x00000000), // Colors.transparent
        Color(0xFF000000), // Colors.black
      ],
    );

    // Horizontal gradient: white -> current hue color (Saturation)
    final Gradient gradientH = LinearGradient(
      colors: [
        Color(0xFFFFFFFF), // Colors.white
        HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, 1.0).toColor(),
      ],
    );

    // Draw a mix of the two gradients
    canvas.drawRect(rect, Paint()..shader = gradientH.createShader(rect));
    canvas.drawRect(rect, Paint()..shader = gradientV.createShader(rect));
  }

  @override
  bool shouldRepaint(SaturationValuePainter oldDelegate) =>
      oldDelegate.hsvColor != hsvColor;
}
