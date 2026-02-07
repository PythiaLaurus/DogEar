import 'package:flutter/material.dart';

import '../painters/painters.dart';
import 'preview.dart';
import 'selector_ring.dart';

/// A hue slider used to select a hue value.
/// Needs a [HSVColor] to work.
class HueSlider extends StatelessWidget {
  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onHSVColorChanged;

  const HueSlider({
    super.key,
    required this.hsvColor,
    required this.onHSVColorChanged,
  });

  static const thumbSize = 20.0;

  @override
  Widget build(BuildContext context) {
    return ColorPropertySlider(
      propertyType: ColorPropertyType.hue,
      value: hsvColor.hue / 360,
      trackPainter: HueTrackPainter(),
      thumbColor: HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, 1.0).toColor(),
      thumbSize: thumbSize,
      onChanged: (value) => onHSVColorChanged(hsvColor.withHue(value * 360)),
    );
  }
}

/// A alpha slider  used to select an alpha value.
/// Needs a [HSVColor] to work.
class AlphaSlider extends StatelessWidget {
  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onHSVColorChanged;

  const AlphaSlider({
    super.key,
    required this.hsvColor,
    required this.onHSVColorChanged,
  });

  static const thumbSize = 20.0;

  @override
  Widget build(BuildContext context) {
    return ColorPropertySlider(
      propertyType: ColorPropertyType.alpha,
      value: hsvColor.alpha,
      backgroundPainter: const CheckerBoardPainter(
        cellSize: 3,
        darkColor: Color(0xFFCCCCCC),
        lightColor: Color(0xFFFFFFFF),
      ),
      trackPainter: AlphaTrackPainter(
        baseColor: hsvColor.withAlpha(1).toColor(),
      ),
      thumbColor: hsvColor.toColor(),
      thumbSize: thumbSize,
      onChanged: (value) => onHSVColorChanged(hsvColor.withAlpha(value)),
    );
  }
}

class ColorPropertySlider extends StatelessWidget {
  final ColorPropertyType propertyType;
  final double value;
  final CustomPainter? backgroundPainter;
  final CustomPainter trackPainter;
  final Color thumbColor;
  final double thumbSize;
  final ValueChanged<double> onChanged;

  const ColorPropertySlider({
    super.key,
    required this.propertyType,
    required this.value,
    this.backgroundPainter,
    required this.trackPainter,
    required this.thumbColor,
    required this.thumbSize,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isAlpha = trackPainter is AlphaTrackPainter;
    final padding = thumbSize / 2;

    return SizedBox(
      height: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth - thumbSize;

          void handlePan({required double dx}) {
            final adjustedDx = dx - padding;
            final progress = (adjustedDx / trackWidth).clamp(0.0, 1.0);
            onChanged(progress);
          }

          return GestureDetector(
            onPanDown: (d) => handlePan(dx: d.localPosition.dx),
            onPanUpdate: (d) => handlePan(dx: d.localPosition.dx),
            child: Stack(
              alignment: .center,
              children: [
                Positioned(left: padding, right: padding, child: _track()),
                Positioned(
                  left: value * trackWidth,
                  child: _thumb(isAlpha: isAlpha),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _track() {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 1, spreadRadius: 0),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: CustomPaint(
          size: const Size(double.infinity, 10),
          painter: backgroundPainter,
          foregroundPainter: trackPainter,
        ),
      ),
    );
  }

  Widget _thumb({required bool isAlpha}) {
    return ColorSelectorRing(
      radius: thumbSize / 2,
      backgroundColor: isAlpha ? Colors.transparent : thumbColor,
      child: isAlpha
          ? ColorSwatchCircle(
              color: thumbColor,
              radius: thumbSize / 2,
              ckeckerBoardCellSize: 3,
              boxDecoration: BoxDecoration(),
            )
          : null,
    );
  }
}

enum ColorPropertyType { hue, alpha }
