import 'package:flutter/material.dart';

import '../painters/saturation_value_painter.dart';
import 'selector_ring.dart';

class SaturationValuePicker extends StatefulWidget {
  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onChanged;

  const SaturationValuePicker({
    super.key,
    required this.hsvColor,
    required this.onChanged,
  });

  @override
  State<SaturationValuePicker> createState() => _SaturationValuePickerState();
}

class _SaturationValuePickerState extends State<SaturationValuePicker> {
  // Pointer appearance
  static const double _pointerSize = 16;
  static const double _pointerRadius = _pointerSize / 2;

  // Palette appearance
  static const double _padding = _pointerRadius;
  static const double _paletteBorderWidth = 1;
  static const double _paletteBorderRadiusOutside = 8;
  static const double _paletteBorderRadiusInside =
      _paletteBorderRadiusOutside - _paletteBorderWidth;

  // Visual property of palette
  double _visualWidth = 0;
  double _visualHeight = 0;

  // Logic visual property of palette
  double get _logicVisualWidth => _visualWidth - 2 * _paletteBorderWidth;
  double get _logicVisualHeight => _visualHeight - 2 * _paletteBorderWidth;
  double get _logicPadding => _padding + _paletteBorderWidth;

  // Calcute current pointer's center coordinates
  // Relative to the control's top-left
  double get _currentPointerX =>
      _logicPadding + (widget.hsvColor.saturation * _logicVisualWidth);
  double get _currentPointerY =>
      _logicPadding + ((1 - widget.hsvColor.value) * _logicVisualHeight);

  // Absolute positioning logic
  // Triggered when clicking on the background (the palette)
  void _updateColorFromPosition(Offset targetPosition) {
    // Convert to palette coordinate
    double dx = targetPosition.dx - _logicPadding;
    double dy = targetPosition.dy - _logicPadding;

    // Clamp to 0.0 ~ 1.0
    double s = (dx / _logicVisualWidth).clamp(0.0, 1.0);
    double v = 1.0 - (dy / _logicVisualHeight).clamp(0.0, 1.0);

    widget.onChanged(widget.hsvColor.withSaturation(s).withValue(v));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate actual size of palette
        // Subtract padding from the total area (to accommodate pointer overflow)
        _visualWidth = constraints.maxWidth - (_padding * 2);
        _visualHeight = constraints.maxHeight - (_padding * 2);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => _updateColorFromPosition(d.localPosition),
          onPanUpdate: (d) => _updateColorFromPosition(d.localPosition),
          child: Stack(
            children: [
              Positioned(
                left: _padding,
                top: _padding,
                width: _visualWidth,
                height: _visualHeight,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black26,
                      width: _paletteBorderWidth,
                    ),
                    borderRadius: BorderRadius.circular(
                      _paletteBorderRadiusOutside,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      _paletteBorderRadiusInside,
                    ),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: SaturationValuePainter(
                        hsvColor: widget.hsvColor,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: _currentPointerX - _pointerRadius,
                top: _currentPointerY - _pointerRadius,
                child: ColorSelectorRing(
                  radius: _pointerRadius,
                  backgroundColor: widget.hsvColor.withAlpha(1).toColor(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
