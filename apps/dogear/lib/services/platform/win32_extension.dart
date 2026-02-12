// ignore_for_file: constant_identifier_names, non_constant_identifier_names, camel_case_types

// Functions, types and constants that are not part of the implemented Dart Win32 API.

import 'dart:ffi';
import 'package:win32/win32.dart';

// Win32 API DLL
final _user32 = DynamicLibrary.open('user32.dll');
final _gdi32 = DynamicLibrary.open('gdi32.dll');

/// Callback types.
typedef WinEventProc =
    Void Function(
      IntPtr hWinEventHook,
      Int32 event,
      IntPtr hwnd,
      Int32 idObject,
      Int32 idChild,
      Int32 dwEventThread,
      Int32 dwmsEventTime,
    );

/// TOKEN_ELEVATION.
final class TOKEN_ELEVATION extends Struct {
  @Uint32()
  external int TokenIsElevated;
}

/// The event ID for location change.
const int EVENT_OBJECT_LOCATIONCHANGE = 0x800B;

// Event IDs as their names
const EVENT_OBJECT_DESTROY = 0x8001;
const EVENT_OBJECT_SHOW = 0x8002;
const EVENT_OBJECT_HIDE = 0x8003;

/// The event ID for foreground (focus window) change.
const int EVENT_SYSTEM_FOREGROUND = 0x0003;

/// The event ID for minimize start.
const int EVENT_SYSTEM_MINIMIZESTART = 0x0016;

/// The event ID for restore minimized window.
const int EVENT_SYSTEM_MINIMIZEEND = 0x0017;

/// Run callback in current thread (our dart procedure), not in the thread
/// that triggers the callback (some other thread).
const int WINEVENT_OUTOFCONTEXT = 0x0000;

/// Means full filled polygon
const int WINDING = 2;

/// Native poniter for DefWindowProcW in user32.dll.
/// Used to call DefWindowProcW to avoid isloted calls.
Pointer<NativeFunction<WNDPROC>> get DefWindowProcWPtr => _DefWindowProcW;
final _DefWindowProcW = _user32.lookup<NativeFunction<WNDPROC>>(
  'DefWindowProcW',
);

/// Native signature for SetWinEventHook in user32.dll.
///
/// [eventMin] specifies the event constant for the lowest event value in the range.
/// [eventMax] specifies the event constant for the highest event value in the range.
/// [hmodWinEventProc] handle to the DLL that contains the hook function (null for current process).
/// [pfnWinEventProc] pointer to the event hook function.
/// [idProcess] specifies the ID of the process from which the hook function receives events (0 for all).
/// [idThread] specifies the ID of the thread from which the hook function receives events (0 for all).
/// [dwFlags] flag values that specify the location of the hook function and of the events to be skipped.
///
/// Returns an [HWINEVENTHOOK] handle that identifies this event hook instance.
/// Returns 0 if the hook could not be installed.
int SetWinEventHook(
  int eventMin,
  int eventMax,
  int hmodWinEventProc,
  Pointer<NativeFunction<WinEventProc>> pfnWinEventProc,
  int idProcess,
  int idThread,
  int dwFlags,
) => _SetWinEventHook(
  eventMin,
  eventMax,
  hmodWinEventProc,
  pfnWinEventProc,
  idProcess,
  idThread,
  dwFlags,
);
final _SetWinEventHook = _user32
    .lookupFunction<
      IntPtr Function(
        Int32,
        Int32,
        IntPtr,
        Pointer<NativeFunction<WinEventProc>>,
        Int32,
        Int32,
        Int32,
      ),
      int Function(
        int,
        int,
        int,
        Pointer<NativeFunction<WinEventProc>>,
        int,
        int,
        int,
      )
    >('SetWinEventHook');

/// Native signature for UnhookWinEvent in user32.dll.
///
/// [hWinEventHook]: Handle to the event hook function.<br>
///
/// Returns 0 if successful, or a nonzero error code.
int UnhookWinEvent(int hWinEventHook) => _UnhookWinEvent(hWinEventHook);
final _UnhookWinEvent = _user32
    .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
      'UnhookWinEvent',
    );

/// Native signature for CreatePolygonRgn in gdi32.dll.
///
/// [lpPoints]: A pointer to an array of [POINT] structures defining the vertices.<br>
/// [nCount]: The number of points in the array.<br>
/// [iPolyFillMode]: The fill mode (1 for ALTERNATE, 2 for WINDING).<br>
///
/// Returns a handle to the region (HRGN) if successful, or 0 on failure.
int CreatePolygonRgn(Pointer<POINT> lpPoints, int nCount, int iPolyFillMode) =>
    _CreatePolygonRgn(lpPoints, nCount, iPolyFillMode);
final _CreatePolygonRgn = _gdi32
    .lookupFunction<
      IntPtr Function(Pointer<POINT>, Int32, Int32),
      int Function(Pointer<POINT>, int, int)
    >('CreatePolygonRgn');
