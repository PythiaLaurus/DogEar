import 'dart:io';

import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppAutostart {
  AppAutostart._();
  static final instance = AppAutostart._();

  /// Initializes autostart functionality.
  ///
  /// This will only setup the configuration for autostart, but not enable or disable it.
  Future<void> initAutostart() async {
    final packageInfo = await PackageInfo.fromPlatform();

    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
      packageName: packageInfo.packageName,
    );
  }

  /// Enable or disable autostart.
  ///
  /// [enabled] is true if autostart should be enabled.
  /// [enabled] is false if autostart should be disabled.
  ///
  /// Note: There is no need to call [launchAtStartup.isEnabled()],
  /// as [launchAtStartup] will handle the state internally and only apply changes if necessary.
  Future<void> setAutostart(bool enabled) async {
    if (enabled) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
  }
}

final appAutostart = AppAutostart.instance;
