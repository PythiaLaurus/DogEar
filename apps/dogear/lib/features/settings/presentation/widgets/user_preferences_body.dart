import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/color_picker/color_picker.dart';
import '../../../../core/widgets/shortcut_recorder.dart';
import '../../../../core/widgets/theme_model_selector.dart';
import '../../../topmost_overlay_orchestration/application/topmost_overlay_orchestrator.dart';
import '../../application/user_preferences.dart';

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
      items: [SettingsItem.shortcut],
    ),
    SettingsCategory(
      icon: Icons.palette,
      title: "Appearance",
      items: [SettingsItem.dogEarColor, SettingsItem.themeMode],
    ),
    SettingsCategory(
      icon: Icons.settings,
      title: "System",
      items: [
        SettingsItem.closeToTray,
        SettingsItem.showTrayIcon,
        SettingsItem.autostart,
        SettingsItem.resetUserPrefs,
      ],
    ),
  ];

  void _pickColor() async {
    final appColors = ref.watch(appColorsProvider);
    final appTextStyles = ref.watch(appTextStylesProvider);

    final userPrefsCtrl = ref.read(userPreferencesProvider.notifier);
    final orchestrator = ref.read(topmostOverlayOrchestratorProvider.notifier);

    int colorSelectedArgb = ref.read(
      userPreferencesProvider.select(
        (s) => s.getPrefsField(SettingsItem.dogEarColor),
      ),
    );

    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appColors.background,
          titlePadding: EdgeInsets.fromLTRB(30, 20, 20, 0),
          title: Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text('Pick Indicator Color', style: appTextStyles.title),
              IconButton(
                onPressed: () => context.pop(),
                visualDensity: .compact,
                mouseCursor: SystemMouseCursors.click,
                icon: Icon(Icons.close_rounded),
              ),
            ],
          ),
          contentPadding: EdgeInsets.fromLTRB(0, 4, 0, 20),
          content: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ProColorPicker(
              pickerColor: Color(colorSelectedArgb),
              onColorChanged: (color) {
                final newColorArgb = color.toARGB32();
                if (colorSelectedArgb == newColorArgb) return;

                setState(() {
                  colorSelectedArgb = newColorArgb;
                });
                orchestrator.updateOverlayColor(color);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop(true);
                userPrefsCtrl.updateDogEarColor(colorSelectedArgb);
              },
              style: ButtonStyle(
                mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      userPrefsCtrl.reapplyDogEarColor();
    }
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
              style: ButtonStyle(
                visualDensity: VisualDensity.comfortable,
                mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
              ),
              child: Text(
                'Confirm',
                style: appTextStyles.bodyLarge.alertColor(),
              ),
            ),
            TextButton(
              onPressed: () {
                context.pop();
              },
              style: ButtonStyle(
                mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
              ),
              child: Text(
                'Cancel',
                style: appTextStyles.bodyLarge.contextColor(context),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _userPrefsCategories.map((cata) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(title: cata.title, icon: cata.icon),
            const SizedBox(height: 6),
            ...cata.items.map(_buildUserPrefsItem),
            const SizedBox(height: 24),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildUserPrefsItem(SettingsItem item) {
    final appTextStyles = ref.watch(appTextStylesProvider);

    final userPrefsCtrl = ref.read(userPreferencesProvider.notifier);

    return switch (item) {
      .shortcut => _buildConsumer(
        item: item,
        childBuilder: (value) => ListTile(
          title: Text(item.function, style: appTextStyles.bodyLarge),
          subtitle: Text(item.description, style: appTextStyles.body),
          trailing: ShortcutRecorder(
            hotkeyDisplayed: value as HotKey?,
            onChanged: userPrefsCtrl.updateShortcut,
          ).mouseRegion(),
        ),
      ),
      .dogEarColor => _buildConsumer(
        item: item,
        childBuilder: (value) => ListTile(
          title: Text(item.function, style: appTextStyles.bodyLarge),
          subtitle: Text(item.description, style: appTextStyles.body),
          contentPadding: EdgeInsets.fromLTRB(12, 0, 8, 0),
          trailing: GestureDetector(
            onTap: _pickColor,
            child: ColorSwatchCircle(color: Color(value as int), radius: 20),
          ).mouseRegion(),
        ),
      ),
      .themeMode => Column(
        children: [
          const SizedBox(height: 8),
          ListTile(
            title: Text(item.function, style: appTextStyles.bodyLarge),
            trailing: ThemeModelSelector(),
          ),
        ],
      ),
      .closeToTray => _buildSwitchListTile(
        item: item,
        onChanged: userPrefsCtrl.updateCloseToTray,
      ),
      .showTrayIcon => _buildSwitchListTile(
        item: item,
        onChanged: userPrefsCtrl.updateShowTrayIcon,
      ),
      .autostart => _buildSwitchListTile(
        item: item,
        onChanged: userPrefsCtrl.updateAutostart,
      ),
      .resetUserPrefs => _buildResetButton(item),
    };
  }

  Widget _buildSwitchListTile({
    required SettingsItem item,
    required ValueChanged<bool> onChanged,
  }) {
    final appTextStyles = ref.watch(appTextStylesProvider);

    return _buildConsumer(
      item: item,
      childBuilder: (value) => SwitchListTile(
        title: Text(item.function, style: appTextStyles.bodyLarge),
        subtitle: Text(item.description, style: appTextStyles.body),
        value: value as bool,
        onChanged: onChanged,
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
        trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }

  Widget _buildConsumer({
    required SettingsItem item,
    required Widget Function(Object value) childBuilder,
  }) {
    return Consumer(
      builder: (context, ref, _) {
        final value = ref.watch(
          userPreferencesProvider.select((s) => s.getPrefsField(item)),
        );
        return childBuilder(value);
      },
    );
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

  Widget _buildResetButton(SettingsItem item) {
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
                visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                foregroundColor: appColors.stateResolved(
                  hoverColor: Colors.red,
                  normalColor: Theme.of(context).colorScheme.primary,
                ),
                textStyle: WidgetStatePropertyAll(
                  appTextStyles.bodySmall.nullColor(),
                ),
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
                mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
              ),
              child: Text(item.function),
            ),
          ],
        ),
      ],
    );
  }
}
