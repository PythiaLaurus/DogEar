import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../window/window_state.dart';

final _kIsMacos = Platform.isMacOS;

class WindowRoundedCorners extends ConsumerWidget {
  final Widget child;
  final double radius;
  const WindowRoundedCorners({
    super.key,
    required this.child,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_kIsMacos) {
      final windowState = ref.watch(windowStateProvider);
      final isMaximized = windowState == WindowStateStatus.maximized;
      final isDocked = windowState == WindowStateStatus.docked;
      final isMaxOrDocked = isMaximized || isDocked;

      return WindowResizableBorder(
        resizeEdgeSize: isDocked ? 8 : 14,
        resizeEdgeMargin: isDocked ? EdgeInsets.zero : const EdgeInsets.all(4),
        child: Container(
          clipBehavior: Clip.antiAlias,
          margin: isMaxOrDocked ? null : const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: isMaxOrDocked
                ? null
                : BorderRadius.all(Radius.circular(radius)),
            boxShadow: isMaxOrDocked
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 8,
                    ),
                  ],
          ),
          child: child,
        ),
      );
    }

    return child;
  }
}

/// Rewrite [VirtualWindowFrame]
class WindowResizableBorder extends ConsumerWidget {
  final Widget child;
  final double resizeEdgeSize;
  final EdgeInsets resizeEdgeMargin;

  const WindowResizableBorder({
    super.key,
    required this.child,
    this.resizeEdgeSize = 8,
    this.resizeEdgeMargin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_kIsMacos) {
      final windowState = ref.watch(windowStateProvider);
      final isMaximized = windowState == WindowStateStatus.maximized;

      return DragToResizeArea(
        resizeEdgeSize: resizeEdgeSize,
        resizeEdgeMargin: resizeEdgeMargin,
        enableResizeEdges: (isMaximized)
            ? []
            : [
                ResizeEdge.topLeft,
                ResizeEdge.top,
                ResizeEdge.topRight,
                ResizeEdge.bottomLeft,
                ResizeEdge.bottom,
                ResizeEdge.bottomRight,
                ResizeEdge.left,
                ResizeEdge.right,
              ],
        child: child,
      );
    }

    return child;
  }
}
