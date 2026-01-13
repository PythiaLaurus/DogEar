import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme.dart';

class ThemeModelSelector extends ConsumerStatefulWidget {
  const ThemeModelSelector({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ThemeModelSelectorState();
}

class _ThemeModelSelectorState extends ConsumerState<ThemeModelSelector> {
  @override
  Widget build(BuildContext context) {
    final appColors = ref.watch(appColorsProvider);
    final appTextStyles = ref.watch(appTextStylesProvider);

    final themeModeStateController = ref.read(
      platformBrightnessProvider.notifier,
    );

    return IntrinsicWidth(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: CupertinoSlidingSegmentedControl<ThemeMode>(
          onValueChanged: (ThemeMode? newThemeMode) {
            if (newThemeMode == null) return;
            themeModeStateController.setByThemeMode(newThemeMode);
            setState(() {});
          },
          // Currently selected value
          groupValue: themeModeStateController.themeMode,
          thumbColor: appColors.background,
          backgroundColor: appColors.primary,
          children: {
            for (var themeMode in ThemeMode.values)
              themeMode: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  themeMode.name,
                  style: appTextStyles.body,
                ),
              ),
          },
        ),
      ),
    );
  }
}
