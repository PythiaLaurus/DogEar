import 'package:flutter/material.dart';

import 'checker_boder_painter.dart';

/// Draw the hue slider track.
class HueTrackPainter extends CustomPainter {
  /// The distance (in pixels) from the left and right edges where the color remains constant.
  final double trackPadding;

  const HueTrackPainter({this.trackPadding = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // Calculate relative position
    // Avoid crossing exceeds
    final double safePadding = trackPadding.clamp(0.0, size.width / 2);
    final double startT = size.width > 0 ? safePadding / size.width : 0.0;
    final double endT = 1.0 - startT;
    final double activeWidth = endT - startT;

    final List<Color> spectrumColors = [
      const HSVColor.fromAHSV(1.0, 0.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 60.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 120.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 180.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 240.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 300.0, 1.0, 1.0).toColor(),
      const HSVColor.fromAHSV(1.0, 360.0, 1.0, 1.0).toColor(),
    ];

    final List<Color> colors = [
      spectrumColors.first,
      ...spectrumColors,
      spectrumColors.last,
    ];

    final List<double> stops = [0.0];
    // Calculate stops
    for (int i = 0; i < spectrumColors.length; i++) {
      final double t = i / (spectrumColors.length - 1);
      stops.add(startT + t * activeWidth);
    }
    stops.add(1.0);

    Gradient gradient = LinearGradient(colors: colors, stops: stops);
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(HueTrackPainter oldDelegate) =>
      oldDelegate.trackPadding != trackPadding;
}

/// Draw the alpha slider track.
class AlphaTrackPainter extends CustomPainter {
  final Color baseColor;
  final double trackPadding;

  const AlphaTrackPainter({required this.baseColor, this.trackPadding = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // Draw the checkerboard background.
    CheckerBoardPainter(
      cellSize: 3,
      darkColor: Color(0xFFCCCCCC),
      lightColor: Color(0xFFFFFFFF),
    ).paint(canvas, Size(size.width - 1, size.height - 1));

    // Calculate relative position
    // Avoid crossing exceeds
    final double safePadding = trackPadding.clamp(0.0, size.width / 2);
    final double startT = size.width > 0 ? safePadding / size.width : 0.0;
    final double endT = 1.0 - startT;

    // 2 real colors
    final Color transparentColor = baseColor.withValues(alpha: 0.0);
    final Color solidColor = baseColor.withValues(alpha: 1.0);

    // Draw gradient (transparent -> solid)
    final Gradient gradient = LinearGradient(
      colors: [transparentColor, transparentColor, solidColor, solidColor],
      stops: [0.0, startT, endT, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(AlphaTrackPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor ||
      oldDelegate.trackPadding != trackPadding;
}
