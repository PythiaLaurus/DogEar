import 'package:flutter/material.dart';

extension WidgetExtension on Widget {
  Widget padding(EdgeInsetsGeometry padding) =>
      Padding(padding: padding, child: this);
}
