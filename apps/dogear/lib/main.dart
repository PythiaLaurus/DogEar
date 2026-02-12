import 'dart:io';

import 'configs/app_config.dart';
import 'core/hotkeys/hotkeys.dart';
import 'core/widgets/custom_window_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';

import 'routes/app_routes.dart';
import 'core/theme/theme.dart';
import 'services/platform/autostart.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await appHotKeys.unregisterAll();

  final appInstance = FlutterSingleInstance();
  if (await appInstance.isFirstInstance()) {
    runApp(const ProviderScope(child: MyApp()));
  } else {
    await appInstance.focus();

    exit(0);
  }

  FlutterSingleInstance.onFocus = (_) {
    windowManager.show();
    windowManager.focus();
  };

  bool isSilent = args.contains('--silent');

  appAutostart.initAutostart();

  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(500, 730),
    minimumSize: Size(500, 670),
    title: AppConfig.appName,
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();

    if (!isSilent) {
      await windowManager.show();
      await windowManager.focus();
    }
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(platformBrightnessProvider);
    final appColors = ref.watch(appColorsProvider);

    final baseTheme = ThemeData.from(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.brown,
        brightness: brightness,
      ),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      routerConfig: router,
      theme: baseTheme.copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        listTileTheme: baseTheme.listTileTheme.copyWith(
          contentPadding: EdgeInsets.fromLTRB(12, 0, 0, 0),
        ),
        textSelectionTheme: baseTheme.textSelectionTheme.copyWith(
          selectionColor: appColors.onHover,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(visualDensity: VisualDensity.comfortable),
        ),
      ),
      builder: (context, child) {
        return WindowRoundedCorners(child: child!);
      },
    );
  }
}
