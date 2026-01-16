import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preview.dart';
import 'property_slider.dart';
import 'saturation_value_picker.dart';

/// A professional and beautiful color picker.
class ProColorPicker extends ConsumerStatefulWidget {
  const ProColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  @override
  ConsumerState<ProColorPicker> createState() => _ProColorPickerState();
}

class _ProColorPickerState extends ConsumerState<ProColorPicker> {
  late HSVColor _currentHsvColor;

  @override
  void initState() {
    super.initState();
    _currentHsvColor = HSVColor.fromColor(widget.pickerColor);
  }

  @override
  void didUpdateWidget(ProColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickerColor != widget.pickerColor) {
      _currentHsvColor = HSVColor.fromColor(widget.pickerColor);
    }
  }

  // Update internal state
  void _onHsvChanged(HSVColor hsv) {
    setState(() => _currentHsvColor = hsv);
    widget.onColorChanged(hsv.toColor());
  }

  void _onColorChanged(Color color) {
    setState(() => _currentHsvColor = HSVColor.fromColor(color));
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final color = _currentHsvColor.toColor();

    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          // 2D color palette (saturation & value)
          AspectRatio(
            aspectRatio: 1.5,
            child: SaturationValuePicker(
              hsvColor: _currentHsvColor,
              onChanged: _onHsvChanged,
            ),
          ),

          // Sliders (Hue & Alpha)
          HueSlider(
            hsvColor: _currentHsvColor,
            onHSVColorChanged: _onHsvChanged,
          ),
          AlphaSlider(
            hsvColor: _currentHsvColor,
            onHSVColorChanged: _onHsvChanged,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ColorPreviewEditor(
              color: color,
              onColorChanged: _onColorChanged,
            ),
          ),
        ],
      ),
    );
  }
}
