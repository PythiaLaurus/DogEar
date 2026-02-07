import 'package:flutter/material.dart';

extension WidgetExtension on Widget {
  Widget padding({required EdgeInsetsGeometry padding}) =>
      Padding(padding: padding, child: this);

  Widget mouseRegion({MouseCursor cursor = SystemMouseCursors.basic}) =>
      MouseRegion(cursor: cursor, child: this);
}
