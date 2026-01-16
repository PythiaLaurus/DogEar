import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../painters/painters.dart';
import '../utils/color_utils.dart';

/// A widget that displays a color preview and allows editing the color.
/// It includes a [RGBAInputField], a [ColorSwatchCircle], and a [HexInputField].
class ColorPreviewEditor extends ConsumerWidget {
  final Color color;
  final void Function(Color color) onColorChanged;
  const ColorPreviewEditor({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = ref.watch(appColorsProvider);
    final appTextStyles = ref.watch(appTextStylesProvider);

    return Column(
      spacing: 16,
      children: [
        // RGBA Inputs
        RGBAInputField(color: color, onColorChanged: onColorChanged),

        // Swatch Color and Hex Input
        Row(
          children: [
            // Swatch Circle
            ColorSwatchCircle(color: color),
            const SizedBox(width: 12),
            // Hex Input
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "HEX Color",
                    style: appTextStyles.bodySmall.copyWith(
                      color: appColors.textDisabled,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  HexInputField(color: color, onColorChanged: onColorChanged),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A row of RGBA input fields.
/// This doesn't include the swatch color preview.
class RGBAInputField extends ConsumerStatefulWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const RGBAInputField({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RGBAInputFieldState();
}

class _RGBAInputFieldState extends ConsumerState<RGBAInputField> {
  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    // Convert to int
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    final a = (color.a * 255).round();

    return Row(
      children: [
        _buildItem("R", r, (v) => color.withValues(red: v / 255.0)),
        const SizedBox(width: 8),
        _buildItem("G", g, (v) => color.withValues(green: v / 255.0)),
        const SizedBox(width: 8),
        _buildItem("B", b, (v) => color.withValues(blue: v / 255.0)),
        const SizedBox(width: 8),
        _buildItem("A", a, (v) => color.withValues(alpha: v / 255.0)),
      ],
    );
  }

  Widget _buildItem(String label, int val, Color Function(int) factory) {
    final appColors = ref.watch(appColorsProvider);
    final appTextStyles = ref.watch(appTextStylesProvider);

    return Expanded(
      child: Column(
        children: [
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: appColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: appColors.widgetDisabled),
            ),
            child: SingleRGBAInputField(
              value: val,
              onChanged: (newVal) => widget.onColorChanged(factory(newVal)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: appTextStyles.bodyExtraSmall.copyWith(
              color: appColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single RGBA input field.
/// Used in [RGBAInputField].
class SingleRGBAInputField extends ConsumerStatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const SingleRGBAInputField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SingleRGBAInputFieldState();
}

class _SingleRGBAInputFieldState extends ConsumerState<SingleRGBAInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  void _handleFocus() {
    if (!_focusNode.hasFocus) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.value.toString());

    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocus);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(SingleRGBAInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.value.toString() != _controller.text) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTextStyles = ref.watch(appTextStylesProvider);

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textAlign: TextAlign.center,
      style: appTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (val) {
        if (val.isEmpty) return;
        final intVal = int.tryParse(val);
        if (intVal != null) {
          widget.onChanged(intVal.clamp(0, 255));
        }
      },
    );
  }
}

/// A circle with a swatch color.
class ColorSwatchCircle extends StatelessWidget {
  final Color color;
  final double radius;
  final double ckeckerBoardCellSize;
  final BoxDecoration? boxDecoration;

  const ColorSwatchCircle({
    super.key,
    required this.color,
    this.radius = 25,
    this.ckeckerBoardCellSize = 6,
    this.boxDecoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration:
          boxDecoration ??
          BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: CheckerBoardPainter(cellSize: ckeckerBoardCellSize),
            ),
            ColoredBox(color: color),
          ],
        ),
      ),
    );
  }
}

/// A hex display and input field.
class HexInputField extends ConsumerStatefulWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const HexInputField({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HexInputFieldState();
}

class _HexInputFieldState extends ConsumerState<HexInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  void _handleFocus() {
    if (!_focusNode.hasFocus) {
      _controller.text = widget.color.toHexString();
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.color.toHexString());

    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocus);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(HexInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        widget.color.toHexString() != _controller.text) {
      _controller.text = widget.color.toHexString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = ref.watch(appColorsProvider);
    final appTextStyles = ref.watch(appTextStylesProvider);

    return Container(
      height: 40,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: appColors.onHover.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: appColors.widgetDisabled),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: appTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [HexFormatter()],
        onChanged: (value) {
          final newColor = ColorUtils.colorFromHex(value);
          if (newColor != null) {
            widget.onColorChanged(newColor);
          }
        },
      ),
    );
  }
}

/// Format: # + upper case hex
class HexFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text.toUpperCase();
    if (!newText.startsWith('#')) {
      newText = '#$newText';
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
