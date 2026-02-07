import 'package:flutter/material.dart';

extension WidgetExtension on Widget {
  Padding padding({required EdgeInsetsGeometry padding}) =>
      Padding(padding: padding, child: this);

  MouseRegion mouseRegion({MouseCursor cursor = SystemMouseCursors.basic}) =>
      MouseRegion(cursor: cursor, child: this);
}
