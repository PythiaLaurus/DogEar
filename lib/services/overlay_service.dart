import 'dart:ffi';
import 'dart:math' as math;
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/painting.dart' show Color;
import 'win32_service.dart';

class OverlayService {
  static final OverlayService _instance = OverlayService._internal();
  factory OverlayService() => _instance;
  OverlayService._internal();

  final Win32Service _win32 = Win32Service();

  // State
  final Map<int, int> _targetToOverlay = {};
  final Map<int, int> _overlayToTarget = {};
  int _hookHandle = 0;
  int _brushHandle = 0;
  bool _isClassRegistered = false;
  static const String kClassName = 'PinX_Triangle_Overlay';
  static const int OBJID_WINDOW = 0x00000000;

  // Keep callback alive
  late NativeCallable<WinEventProc> _hookCallback;

  static void _staticHookCallback(
    int hWinEventHook,
    int event,
    int hwnd,
    int idObject,
    int idChild,
    int dwEventThread,
    int dwmsEventTime,
  ) {
    _instance._handleLocationChange(event, hwnd, idObject);
  }

  static int _staticWndProc(int hwnd, int msg, int wParam, int lParam) {
    return DefWindowProc(hwnd, msg, wParam, lParam);
  }

  void init() {
    if (_isClassRegistered) return;

    // Register Window Class
    final wndClass = calloc<WNDCLASS>();
    wndClass.ref.style = CS_HREDRAW | CS_VREDRAW;
    wndClass.ref.lpfnWndProc = Pointer.fromFunction<WNDPROC>(_staticWndProc, 0);
    wndClass.ref.cbClsExtra = 0;
    wndClass.ref.cbWndExtra = 0;
    wndClass.ref.hInstance = _win32.getModuleHandle(null);
    wndClass.ref.hIcon = 0;
    wndClass.ref.hCursor = LoadCursor(0, IDC_ARROW);
    wndClass.ref.hbrBackground = 0;
    wndClass.ref.lpszMenuName = nullptr;
    wndClass.ref.lpszClassName = kClassName.toNativeUtf16();

    _win32.registerClass(wndClass.ref);
    _isClassRegistered = true;

    // Start Hook
    _hookCallback = NativeCallable<WinEventProc>.listener(_staticHookCallback);
    _hookHandle = _win32.setWinEventHook(
      Win32Service.EVENT_OBJECT_LOCATIONCHANGE,
      Win32Service.EVENT_OBJECT_LOCATIONCHANGE,
      0,
      _hookCallback.nativeFunction,
      0,
      0,
      Win32Service.WINEVENT_OUTOFCONTEXT,
    );
  }

  void updateColor(Color color) {
    final r = (color.r * 255).toInt();
    final g = (color.g * 255).toInt();
    final b = (color.b * 255).toInt();
    final colorRef = r | (g << 8) | (b << 16);

    // Create new brush first
    final newBrush = _win32.createSolidBrush(colorRef);

    // Set new brush to class
    if (_targetToOverlay.isNotEmpty) {
      final hwnd = _targetToOverlay.values.first;
      // GCLP_HBRBACKGROUND is -10
      _win32.setClassLongPtr(hwnd, -10, newBrush);

      // Force redraw
      for (final h in _targetToOverlay.values) {
        _win32.invalidateRect(h, nullptr, true);
      }
    }

    // Delete old brush
    if (_brushHandle != 0) {
      DeleteObject(_brushHandle);
    }

    _brushHandle = newBrush;
  }

  void add(int targetHwnd) {
    if (_targetToOverlay.containsKey(targetHwnd)) return;

    final hInst = _win32.getModuleHandle(null);
    final overlayHwnd = _win32.createWindowEx(
      WS_EX_TOOLWINDOW |
          WS_EX_TOPMOST |
          WS_EX_NOACTIVATE |
          WS_EX_LAYERED |
          WS_EX_TRANSPARENT,
      kClassName,
      '',
      WS_POPUP | WS_VISIBLE,
      0,
      0,
      20,
      20,
      0,
      0,
      hInst,
      nullptr,
    );

    if (overlayHwnd == 0) return;

    _win32.setLayeredWindowAttributes(overlayHwnd, 0, 255, LWA_ALPHA);

    if (_targetToOverlay.isEmpty && _brushHandle != 0) {
      _win32.setClassLongPtr(overlayHwnd, -10, _brushHandle);
    }

    _targetToOverlay[targetHwnd] = overlayHwnd;
    _overlayToTarget[overlayHwnd] = targetHwnd;

    // Set Shape (Triangle)
    const size = 20;
    final points = [
      math.Point(0, 0),
      math.Point(size, 0),
      math.Point(size, size),
    ];
    final rgn = _win32.createPolygonRgn(points);
    _win32.setWindowRgn(overlayHwnd, rgn, true);
    // Note: SetWindowRgn takes ownership of the region handle, so we don't delete it?
    // "The system does not copy the region. ... Do not make further function calls with this region handle"
    // So we don't need DeleteObject(rgn).

    _updateOverlayPosition(targetHwnd, overlayHwnd);
  }

  void remove(int targetHwnd) {
    final overlay = _targetToOverlay.remove(targetHwnd);
    if (overlay != null) {
      _overlayToTarget.remove(overlay);
      _win32.destroyWindow(overlay);
    }
  }

  void dispose() {
    if (_hookHandle != 0) {
      _win32.unhookWinEvent(_hookHandle);
      _hookHandle = 0;
    }
    _hookCallback.close();

    for (final h in _targetToOverlay.values) {
      _win32.destroyWindow(h);
    }
    _targetToOverlay.clear();
    _overlayToTarget.clear();

    if (_brushHandle != 0) {
      DeleteObject(_brushHandle);
      _brushHandle = 0;
    }
  }

  void _handleLocationChange(int event, int hwnd, int idObject) {
    // Only care about pinned windows
    if (_targetToOverlay.containsKey(hwnd)) {
      _updateOverlayPosition(hwnd, _targetToOverlay[hwnd]!);
    }
  }

  void _updateOverlayPosition(int target, int overlay) {
    final rect = _win32.getWindowRect(target);
    if (rect == null) return;

    const size = 20;
    final x = rect.left + rect.width - size;
    final y = rect.top;

    _win32.setWindowPos(
      overlay,
      HWND_TOPMOST,
      x,
      y,
      size,
      size,
      SWP_NOACTIVATE | SWP_NOOWNERZORDER,
    );
  }
}
