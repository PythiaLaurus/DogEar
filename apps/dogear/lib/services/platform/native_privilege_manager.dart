import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'win32_extension.dart';

class NativePrivilegeManager {
  NativePrivilegeManager._();
  static final instance = NativePrivilegeManager._();

  /// Checks if the app is running with administrative privileges.
  ///
  /// Returns true if the app is running with administrative privileges, false otherwise.
  bool isAppRunAsAdmin() {
    // Get the current process handle
    final hProcess = GetCurrentProcess();
    final phToken = calloc<HANDLE>();

    try {
      // Open the access token associated with the current process
      if (OpenProcessToken(hProcess, TOKEN_QUERY, phToken) == 0) {
        return false;
      }

      final hToken = phToken.value;
      final pElevation = calloc<TOKEN_ELEVATION>();
      final pReturnLength = calloc<DWORD>();

      try {
        final result = GetTokenInformation(
          hToken,
          TokenElevation,
          pElevation,
          sizeOf<TOKEN_ELEVATION>(),
          pReturnLength,
        );
        if (result == 0) return false;

        return pElevation.ref.TokenIsElevated != 0;
      } finally {
        CloseHandle(hToken);
        calloc.free(pElevation);
        calloc.free(pReturnLength);
      }
    } finally {
      calloc.free(phToken);
    }
  }

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
        NULL,
        pOperation,
        pFile,
        pParameters,
        pDir,
        SW_SHOWNORMAL,
      );

      // ShellExecute returns a value greater than 32 if successful.
      // If the return value is less than or equal to 32, it indicates an error.
      if (result <= 32) {
        throw Exception(
          'Failed to relaunch with admin privileges. Error code: $result',
        );
      }

      // Exit the current instance after launching the new one
      exit(0);
    } finally {
      calloc.free(pOperation);
      calloc.free(pFile);
      calloc.free(pDir);
      calloc.free(pParameters);
    }
  }
}

final nativePrivilegeManager = NativePrivilegeManager.instance;
