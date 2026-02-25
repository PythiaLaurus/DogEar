import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'native_extension.dart';

class NativePrivilegeManager with NativaErrorLogger {
  NativePrivilegeManager._();
  static final instance = NativePrivilegeManager._();

  @override
  String get moduleName => "NativePrivilegeManager";

  bool? _isRunningAsAdmin;

  /// Whether the app is running with administrative privileges.
  bool get isRunningAsAdmin => _isRunningAsAdmin ??= _checkRunningAsAdmin();

  /// Requests administrative privileges by relaunching the app with elevated permissions using ShellExecute.
  void requestAdminPrivileges([List<String>? arguments]) {
    final pOperation = 'runas'.toNativeUtf16();
    final pFile = Platform.resolvedExecutable.toNativeUtf16();
    final pDir = File(Platform.resolvedExecutable).parent.path.toNativeUtf16();

    // Combine the current executable arguments with any additional arguments provided
    final List<String> allArgs = [
      ...Platform.executableArguments,
      ...?arguments,
    ];
    final String argsString = allArgs.join(' ');
    final pParameters = argsString.toNativeUtf16();

    try {
      // Use ShellExecute to relaunch the app with admin privileges
      // hwnd: NULL (no parent window)
      // lpOperation: "runas" to request elevation
      // lpFile: Path to the executable
      // lpParameters: Command line arguments (if any)
      // lpDirectory: Working directory
      // nShowCmd: SW_SHOWNORMAL(1) to show the window normally
      final result = ShellExecute(
        null,
        PCWSTR(pOperation),
        PCWSTR(pFile),
        PCWSTR(pParameters),
        PCWSTR(pDir),
        SW_SHOWNORMAL,
      );

      // ShellExecute returns a value greater than 32 if successful.
      // If the return value is less than or equal to 32, it indicates an error.
      if (result.address <= 32) {
        throw Exception(
          'Failed to relaunch with admin privileges. Error code: $result',
        );
      }

      // Exit the current instance after launching the new one
      exit(0);
    } finally {
      free(pOperation);
      free(pFile);
      free(pDir);
      free(pParameters);
    }
  }

  /// Check whether the app is running with administrative privileges.
  bool _checkRunningAsAdmin() {
    // Get the current process handle
    final hProcess = GetCurrentProcess();
    final phToken = calloc<IntPtr>().cast<HANDLE>();

    try {
      // Open the access token associated with the current process
      if (!OpenProcessToken(hProcess, TOKEN_QUERY, phToken).value) {
        log("isAppRunAsAdmin", NativeError.getSuccessWin32Result(false));
        return false;
      }

      final hToken = phToken.value as HANDLE;
      final pElevation = calloc<TOKEN_ELEVATION>();
      final pReturnLength = calloc<DWORD>();

      try {
        final result = GetTokenInformation(
          HANDLE(hToken),
          TokenElevation,
          pElevation,
          sizeOf<TOKEN_ELEVATION>(),
          pReturnLength,
        );
        if (!result.value) {
          log("isAppRunAsAdmin", NativeError.getSuccessWin32Result(false));
          return false;
        }

        final value = pElevation.ref.TokenIsElevated != 0;
        log("isAppRunAsAdmin", NativeError.getSuccessWin32Result(value));
        return value;
      } finally {
        hToken.close();
        free(pElevation);
        free(pReturnLength);
      }
    } finally {
      free(phToken);
    }
  }
}

final nativePrivilegeManager = NativePrivilegeManager.instance;
