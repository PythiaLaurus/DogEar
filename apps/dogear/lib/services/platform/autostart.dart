import 'dart:io';
import 'native_privilege_manager.dart';

import '../../configs/app_config.dart';

class AppAutostart {
  AppAutostart._();
  static final instance = AppAutostart._();

  static const _taskName = "${AppConfig.appName}AutostartTask";

  /// Enable or disable autostart.
  ///
  /// [enabled] is true if autostart should be enabled.
  /// [enabled] is false if autostart should be disabled.
  Future<void> setAutostart(bool enabled) async {
    if (!Platform.isWindows) return;

    if (await isEnabled() == enabled) return;

    // Check if the app is running with administrative privileges. If not, request admin privileges to enable/disable autostart.
    if (!nativePrivilegeManager.isAppRunAsAdmin()) {
      nativePrivilegeManager.requestAdminPrivileges([AppConfig.argSilent]);
      return;
    }

    if (enabled) {
      enable();
    } else {
      disable();
    }
  }

  /// Checks if autostart is enabled by looking for the existence of the scheduled task.
  ///
  /// Returns true if the task exists, false otherwise.
  Future<bool> isEnabled() async {
    // Use schtasks to check if the task exists. If it does, autostart is enabled.
    final result = await Process.run('schtasks', ['/query', '/tn', _taskName]);
    return result.exitCode == 0;
  }

  /// Enables autostart by creating a scheduled task that runs the app at login with the highest privileges.
  ///
  /// Returns true if the operation was successful, false otherwise.
  ///
  /// Note: This method requires administrative privileges to create a scheduled task with the highest run level.
  Future<bool> enable() async {
    final String exePath = Platform.resolvedExecutable;

    // Build the command
    // /create: Create a task
    // /tn: Task name
    // /tr: Path to the executable (quoted to handle spaces)
    // /sc: Schedule frequency (onlogon means at login)
    // /rl: Run level (highest means run with admin privileges)
    // /f: Force overwrite if the task already exists
    final result = await Process.run('schtasks', [
      '/create',
      '/tn',
      _taskName,
      '/tr',
      '"$exePath" ${AppConfig.argSilent}',
      '/sc',
      'onlogon',
      '/rl',
      'highest',
      '/f',
    ]);

    return result.exitCode == 0;
  }

  /// Disables autostart by deleting the scheduled task.
  ///
  /// Returns true if the operation was successful, false otherwise.
  ///
  /// Note: This method requires administrative privileges to delete a scheduled task that was created with the highest run level.
  Future<bool> disable() async {
    final result = await Process.run('schtasks', [
      '/delete',
      '/tn',
      _taskName,
      '/f',
    ]);

    return result.exitCode == 0;
  }
}

final appAutostart = AppAutostart.instance;
