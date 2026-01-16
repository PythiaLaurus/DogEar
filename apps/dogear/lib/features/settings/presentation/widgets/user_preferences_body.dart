import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/color_picker/color_picker.dart';
import '../../../../core/widgets/shortcut_recorder.dart';
import '../../../../core/widgets/theme_model_selector.dart';
import '../../application/user_preferences.dart';
import '../../domain/settings_items.dart';
import '../../domain/user_preferences_model.dart';

class UserPreferencesBody extends ConsumerStatefulWidget {
  const UserPreferencesBody({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UserPreferencesBodyState();
}

class _UserPreferencesBodyState extends ConsumerState<UserPreferencesBody> {
  static const List<SettingsCategory> _userPrefsCategories = [
    SettingsCategory(
      icon: Icons.keyboard,
      title: "Shortcut",
      items: [
        SettingsItem(
          type: SettingsItemType.shortcut,
          function: "Pin Active Window",
          description: "Global hotkey to pin/unpin windows",
        ),
      ],
    ),
    SettingsCategory(
      icon: Icons.palette,
      title: "Appearance",
      items: [
        SettingsItem(
          type: SettingsItemType.dogEarColor,
          function: "Dog Ear Color",
          description: "Color of the overlay indicator",
        ),
      ],
    ),
    SettingsCategory(
      icon: Icons.settings,
      title: "System",
      items: [
        SettingsItem(
          type: SettingsItemType.closeToTray,
          function: "Close to Tray",
          description: "Keep running in background when closed",
        ),
        SettingsItem(
          type: SettingsItemType.showTrayIcon,
          function: "Show Tray Icon",
          description: "Show icon in system tray area",
        ),
        SettingsItem(
          type: SettingsItemType.themeMode,
          function: "App Theme",
          description: "",
        ),
        SettingsItem(
          type: SettingsItemType.resetUserPrefs,
          function: "Reset all settings",
          description: "",
        ),
      ],
    ),
  ];

  void _pickColor() {
    final appColors = ref.watch(appColorsProvider);
    final appTextStyles = ref.watch(appTextStylesProvider);
    final userPrefs =
        ref.watch(userPreferencesProvider).value ??
        UserPreferencesModel.initialize();
    final userPrefsCtrl = ref.read(userPreferencesProvider.notifier);

    int colorSelectedARGB = userPrefs.dogEarColorARGB;

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appColors.background,
          titlePadding: EdgeInsets.fromLTRB(30, 20, 30, 0),
          title: Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text('Pick Indicator Color', style: appTextStyles.title),
              IconButton(
                onPressed: () => context.pop(),
                visualDensity: .compact,
                icon: Icon(Icons.close_rounded),
              ),
            ],
          ),
          contentPadding: EdgeInsets.fromLTRB(20, 4, 20, 20),
          content: SingleChildScrollView(
            child: ProColorPicker(
              pickerColor: Color(colorSelectedARGB),
              onColorChanged: (color) {
                final newColorARGB = color.toARGB32();
                if (colorSelectedARGB == newColorARGB) return;

                setState(() {
                  colorSelectedARGB = newColorARGB;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
                userPrefsCtrl.updateDogEarColor(colorSelectedARGB);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _resetUserPrefs() {
    final appColors = ref.watch(appColorsProvider);
    final appTextStyles = ref.watch(appTextStylesProvider);
    final userPrefsCtrl = ref.read(userPreferencesProvider.notifier);

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return AlertDialog(
          titlePadding: EdgeInsets.fromLTRB(40, 40, 40, 30),
          backgroundColor: appColors.background,
          title: Text(
            'Reset all setting to default?',
            style: appTextStyles.title,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
                userPrefsCtrl.resetUserPrefs();
              },
              style: ButtonStyle(visualDensity: VisualDensity.comfortable),
              child: Text('Confirm', style: appTextStyles.body.alertColor()),
            ),
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: Text(
                'Cancel',
                style: appTextStyles.body.contextColor(context),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefsBuilders = _getUserPrefsBuilders();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _userPrefsCategories.map((cata) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(title: cata.title, icon: cata.icon),
            const SizedBox(height: 6),
            ...cata.items.map((item) {
              final builder = prefsBuilders[item.type];
              if (builder == null) return const SizedBox.shrink();
              return builder(item);
            }),
            const SizedBox(height: 24),
          ],
        );
      }).toList(),
    );
  }

  Map<SettingsItemType, Widget Function(SettingsItem item)>
  _getUserPrefsBuilders() {
    final appTextStyles = ref.watch(appTextStylesProvider);
    final userPrefs =
        ref.watch(userPreferencesProvider).value ??
        UserPreferencesModel.initialize();
    final userPrefsCtrl = ref.read(userPreferencesProvider.notifier);

    final widgetBuilders =
        <SettingsItemType, Widget Function(SettingsItem item)>{
          SettingsItemType.shortcut: (item) {
            return ListTile(
              title: Text(item.function, style: appTextStyles.bodyLarge),
              subtitle: Text(item.description, style: appTextStyles.body),
              trailing: ShortcutRecorder(
                hotkeyDisplayed: userPrefs.shortcut,
                onChanged: (hotkey) {
                  userPrefsCtrl.updateShortcut(hotkey);
                },
              ),
            );
          },
          SettingsItemType.dogEarColor: (item) {
            return ListTile(
              title: Text(item.function, style: appTextStyles.bodyLarge),
              subtitle: Text(item.description, style: appTextStyles.body),
              contentPadding: EdgeInsets.fromLTRB(12, 0, 8, 0),
              trailing: GestureDetector(
                onTap: _pickColor,
                child: ColorSwatchCircle(
                  color: Color(userPrefs.dogEarColorARGB),
                  radius: 20,
                ),
              ),
            );
          },
          SettingsItemType.closeToTray: (item) {
            return SwitchListTile(
              title: Text(item.function, style: appTextStyles.bodyLarge),
              subtitle: Text(item.description, style: appTextStyles.body),
              value: userPrefs.closeToTray,
              onChanged: (value) {
                userPrefsCtrl.updateCloseToTray(value);
              },
              overlayColor: WidgetStatePropertyAll(Colors.transparent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
            );
          },
          SettingsItemType.showTrayIcon: (item) {
            return SwitchListTile(
              title: Text(item.function, style: appTextStyles.bodyLarge),
              subtitle: Text(item.description, style: appTextStyles.body),
              value: userPrefs.showTrayIcon,
              onChanged: (value) {
                userPrefsCtrl.updateShowTrayIcon(value);
              },
              overlayColor: WidgetStatePropertyAll(Colors.transparent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
            );
          },
          SettingsItemType.themeMode: (item) {
            return Column(
              children: [
                const SizedBox(height: 8),
                ListTile(
                  title: Text(item.function, style: appTextStyles.bodyLarge),
                  trailing: ThemeModelSelector(),
                ),
              ],
            );
          },
          SettingsItemType.resetUserPrefs: (item) {
            final appColors = ref.watch(appColorsProvider);
            final appTextStyles = ref.watch(appTextStylesProvider);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _resetUserPrefs(),
                      style: ButtonStyle(
                        visualDensity: VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        foregroundColor: appColors.stateResolved(
                          hoverColor: Colors.red,
                          normalColor: Theme.of(context).colorScheme.primary,
                        ),
                        textStyle: WidgetStatePropertyAll(
                          appTextStyles.bodySmall.nullColor(),
                        ),
                        overlayColor: WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                      ),
                      child: Text(item.function),
                    ),
                  ],
                ),
              ],
            );
          },
        };

    return widgetBuilders;
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
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
}
