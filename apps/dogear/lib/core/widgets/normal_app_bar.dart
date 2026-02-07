import 'dart:io';

import '../../configs/tray_config.dart';
import '../theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';

class WindowButtons extends ConsumerStatefulWidget {
  const WindowButtons({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends ConsumerState<WindowButtons> {
  @override
  Widget build(BuildContext context) {
    final brightness = ref.watch(platformBrightnessProvider);

    return SizedBox(
      width: 138,
      child: Row(
        children: [
          WindowCaptionButton.minimize(
            brightness: brightness,
            onPressed: () {
              windowManager.minimize();
            },
          ),
          FutureBuilder<bool>(
            future: windowManager.isMaximized(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.data == true) {
                return WindowCaptionButton.unmaximize(
                  brightness: brightness,
                  onPressed: () {
                    windowManager.unmaximize();
                  },
                );
              }
              return WindowCaptionButton.maximize(
                brightness: brightness,
                onPressed: () {
                  windowManager.maximize();
                },
              );
            },
          ),
          WindowCaptionButton.close(
            brightness: brightness,
            onPressed: () {
              if (TrayConfig.closeToTray ?? false) {
                windowManager.hide();
              } else {
                windowManager.close();
              }
            },
          ),
        ],
      ),
    );
  }
}

class NormalAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const NormalAppBar({
    super.key,
    this.height = 46,
    this.title,
    this.titlePadding,
  });
  final double height;
  final Widget? title;
  final EdgeInsetsGeometry? titlePadding;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(appColorsProvider).primary;

    return Container(
      color: color,
      height: height,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding:
                  titlePadding ??
                  EdgeInsets.only(left: Platform.isWindows ? 20 : 100),
              child: title ?? const SizedBox(),
            ),
          ),
          const Positioned.fill(child: DragToMoveArea(child: SizedBox())),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: Platform.isMacOS ? const SizedBox() : const WindowButtons(),
          ),
        ],
      ),
    );
  }
}

class InvisibleDraggableAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const InvisibleDraggableAppBar({super.key, this.height = 46});
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return DragToMoveArea(child: SizedBox(height: height));
  }
}
