import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'services/win32_service.dart';
import 'services/overlay_service.dart';

const String kAppTitle = 'PinX - Window Manager';
const String kMutexName = 'Global\\PinX_SingleInstance_Mutex';
const String kPrefHotkeyKey = 'pinx_hotkey';
const String kPrefCloseToTray = 'pinx_close_to_tray';
const String kPrefShowTrayIcon = 'pinx_show_tray_icon';
const String kPrefTriangleColor = 'pinx_triangle_color';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure single instance
  final win32Service = Win32Service();
  if (!win32Service.ensureSingleInstance(kMutexName)) {
    exit(0);
  }

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Initialize hotkey manager
  await hotKeyManager.unregisterAll();

  // Initial Window Options: Start as a "Settings Window"
  WindowOptions windowOptions = const WindowOptions(
    size: Size(500, 700),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: false,
    fullScreen: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setFullScreen(false);
    await windowManager.setHasShadow(true);
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: kAppTitle),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with TrayListener, WindowListener {
  final Win32Service _win32Service = Win32Service();
  final OverlayService _overlayService = OverlayService();

  // Settings
  HotKey _currentHotKey = HotKey(
    key: LogicalKeyboardKey.home,
    modifiers: [HotKeyModifier.alt, HotKeyModifier.control],
    scope: HotKeyScope.system,
  );
  bool _closeToTray = true;
  bool _showTrayIcon = true;
  Color _triangleColor = Colors.red;

  // UI State
  final Set<int> _pinnedWindows = {};

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);

    // Initialize Overlay Service (Win32 Class & Hook)
    _overlayService.init();

    _loadSettings();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    _overlayService.dispose();
    super.dispose();
  }

  // --- Window Mode Management ---

  void _toggleSettings(bool visible) async {
    if (visible) {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setSkipTaskbar(false);
    } else {
      await windowManager.hide();
      await windowManager.setSkipTaskbar(true);
    }
  }

  // --- Settings & Persistence ---

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _closeToTray = prefs.getBool(kPrefCloseToTray) ?? true;
      _showTrayIcon = prefs.getBool(kPrefShowTrayIcon) ?? true;

      final colorInt = prefs.getInt(kPrefTriangleColor);
      if (colorInt != null) {
        _triangleColor = Color(colorInt);
      }
    });

    // Update Overlay Color
    _overlayService.updateColor(_triangleColor);

    final hotKeyJson = prefs.getString(kPrefHotkeyKey);
    if (hotKeyJson != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(hotKeyJson);
        _currentHotKey = HotKey.fromJson(map);
      } catch (e) {
        _addLog('Error loading hotkey: $e');
      }
    }

    _registerHotkey();
    _updateTray();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefCloseToTray, _closeToTray);
    await prefs.setBool(kPrefShowTrayIcon, _showTrayIcon);
    // Use value for now, ignore deprecation or use new API if known
    // The warning says: Use component accessors like .r or .g, or toARGB32 for an explicit conversion
    // Assuming toARGB32 might not be available in all versions, but let's try just ignoring the warning or keeping it as is.
    // Actually, if it's deprecated, let's try to see if we can use something else or suppress it.
    // For now, I'll leave it but maybe suppress the warning?
    // Or better, let's try casting to int if that's what it wants.
    await prefs.setInt(kPrefTriangleColor, _triangleColor.value);
    await prefs.setString(kPrefHotkeyKey, jsonEncode(_currentHotKey.toJson()));

    _updateTray();
  }

  Future<void> _registerHotkey() async {
    await hotKeyManager.unregisterAll();
    await hotKeyManager.register(
      _currentHotKey,
      keyDownHandler: (hotKey) {
        _handleToggleTopMost();
      },
    );
  }

  Future<void> _updateTray() async {
    if (_showTrayIcon) {
      await _initSystemTray();
    } else {
      await trayManager.destroy();
    }
  }

  Future<void> _initSystemTray() async {
    String? iconPath;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final file = File('${appDocDir.path}/app_icon.ico');
      final byteData = await rootBundle.load('assets/app_icon.ico');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      iconPath = file.path;
    } catch (e) {
      // Ignore
    }

    await trayManager.setIcon(
      iconPath ?? 'windows/runner/resources/app_icon.ico',
    );
    await trayManager.setToolTip('PinX');
    Menu menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: 'Settings'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: 'Exit'),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  void _addLog(String message) {
    debugPrint(message);
  }

  void _handleToggleTopMost() {
    try {
      final hwnd = _win32Service.getEffectiveForegroundWindow();
      if (hwnd == 0) {
        _addLog('No effective foreground window found (or ignored).');
        return;
      }

      final isTopMost = _win32Service.toggleAlwaysOnTop(hwnd);
      _addLog('Toggled TopMost for $hwnd: $isTopMost');

      setState(() {
        if (isTopMost) {
          _pinnedWindows.add(hwnd);
          _overlayService.add(hwnd);
        } else {
          _pinnedWindows.remove(hwnd);
          _overlayService.remove(hwnd);
        }
      });
    } catch (e) {
      _addLog('Error toggling TopMost: $e');
      if (e is WindowsException && e.code == 5) {
        _win32Service.relaunchElevated();
        exit(0);
      }
    }
  }

  String _formatHotkey(HotKey hotKey) {
    final mods =
        hotKey.modifiers?.map((m) => _getModifierLabel(m)).join(' + ') ?? '';
    final key = hotKey.key.keyLabel;
    if (mods.isNotEmpty) {
      return '$mods + $key';
    }
    return key;
  }

  String _getModifierLabel(HotKeyModifier modifier) {
    switch (modifier) {
      case HotKeyModifier.alt:
        return 'Alt';
      case HotKeyModifier.control:
        return 'Ctrl';
      case HotKeyModifier.shift:
        return 'Shift';
      case HotKeyModifier.meta:
        return 'Meta';
      default:
        return modifier.toString().split('.').last;
    }
  }

  // --- UI Construction ---

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick Indicator Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _triangleColor,
              onColorChanged: (color) {
                setState(() {
                  _triangleColor = color;
                });
                // Update Native Overlay Color immediately
                _overlayService.updateColor(color);
              },
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveSettings();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _recordHotkey() async {
    HotKey? newKey;
    final FocusNode focusNode = FocusNode();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Press New Hotkey'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Press any key combination...'),
              const SizedBox(height: 20),
              Focus(
                focusNode: focusNode,
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent) {
                    List<HotKeyModifier> modifiers = [];
                    if (HardwareKeyboard.instance.isControlPressed) {
                      modifiers.add(HotKeyModifier.control);
                    }
                    if (HardwareKeyboard.instance.isAltPressed) {
                      modifiers.add(HotKeyModifier.alt);
                    }
                    if (HardwareKeyboard.instance.isShiftPressed) {
                      modifiers.add(HotKeyModifier.shift);
                    }
                    if (HardwareKeyboard.instance.isMetaPressed) {
                      modifiers.add(HotKeyModifier.meta);
                    }

                    // Ignore modifier-only presses
                    if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
                        event.logicalKey == LogicalKeyboardKey.controlRight ||
                        event.logicalKey == LogicalKeyboardKey.altLeft ||
                        event.logicalKey == LogicalKeyboardKey.altRight ||
                        event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                        event.logicalKey == LogicalKeyboardKey.shiftRight ||
                        event.logicalKey == LogicalKeyboardKey.metaLeft ||
                        event.logicalKey == LogicalKeyboardKey.metaRight) {
                      return KeyEventResult.ignored;
                    }

                    newKey = HotKey(
                      key: event.logicalKey,
                      modifiers: modifiers,
                      scope: HotKeyScope.system,
                    );

                    Navigator.of(context).pop();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Builder(
                  builder: (context) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!focusNode.hasFocus) {
                        focusNode.requestFocus();
                      }
                    });
                    return Container(
                      width: 200,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Focus here & Press Keys',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    focusNode.dispose();

    if (newKey != null) {
      setState(() {
        _currentHotKey = newKey!;
      });
      await _registerHotkey();
      _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Important for rounded corners
      body: Center(
        child: Container(
          // Window Content
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              // Custom Title Bar with Dragging
              GestureDetector(
                onPanStart: (details) {
                  windowManager.startDragging();
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.push_pin, size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'PinX Settings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        onPressed: () {
                          if (_closeToTray) {
                            _toggleSettings(false);
                          } else {
                            windowManager.destroy();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    // Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Running Active',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Pinned Windows: ${_pinnedWindows.length}'),
                          const SizedBox(height: 8),
                          const Text(
                            'Overlay indicators are managed natively.',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Hotkey Section
                    _buildSectionHeader(context, 'Shortcut', Icons.keyboard),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(_formatHotkey(_currentHotKey)),
                      subtitle: const Text(
                        'Global hotkey to pin/unpin windows',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _recordHotkey,
                      ),
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Appearance Section
                    _buildSectionHeader(context, 'Appearance', Icons.palette),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Triangle Color'),
                      subtitle: const Text('Color of the overlay indicator'),
                      trailing: GestureDetector(
                        onTap: _pickColor,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _triangleColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                      ),
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // System Section
                    _buildSectionHeader(context, 'System', Icons.settings),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Close to Tray'),
                      subtitle: const Text(
                        'Keep running in background when closed',
                      ),
                      value: _closeToTray,
                      onChanged: (value) {
                        setState(() {
                          _closeToTray = value;
                        });
                        _saveSettings();
                      },
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Show Tray Icon'),
                      subtitle: const Text('Show icon in system tray area'),
                      value: _showTrayIcon,
                      onChanged: (value) {
                        setState(() {
                          _showTrayIcon = value;
                        });
                        _saveSettings();
                      },
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  @override
  void onTrayIconMouseDown() {
    _toggleSettings(true);
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      _toggleSettings(true);
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy();
    }
  }

  @override
  void onWindowClose() {
    if (_closeToTray) {
      _toggleSettings(false);
    } else {
      windowManager.destroy();
    }
  }
}
