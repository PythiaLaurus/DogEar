import 'package:flutter/material.dart';

class ColorSelectorRing extends StatelessWidget {
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final BoxDecoration? decoration;
  final Widget? child;

  const ColorSelectorRing({
    super.key,
    required this.radius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.decoration,
    this.child,
  }) : assert(radius > 0, 'radius must be greater than 0'),
       assert(
         (backgroundColor != null ||
                 borderColor != null ||
                 borderWidth != null) ||
             decoration == null,
         'decoration cannot be used with backgroundColor, borderColor or borderWidth at the same time',
       );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: decoration != null
          ? decoration!.copyWith(shape: BoxShape.circle)
          : BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(
                color: borderColor ?? Colors.white,
                width: borderWidth ?? 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
      child: child,
    );
  }
}
