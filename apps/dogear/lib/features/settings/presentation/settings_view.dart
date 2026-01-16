import '../../../core/theme/theme.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/user_preferences_body.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final appColors = ref.watch(appColorsProvider);

    return Scaffold(
      backgroundColor: appColors.background,
      body: Container(
        color: appColors.background,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Status
            _statusCard(),
            const SizedBox(height: 24),
            UserPreferencesBody(),
          ],
        ),
      ),
    );
  }

  Widget _statusCard({int pinnedWindowsCount = 0}) {
    final appTextStyles = ref.watch(appTextStylesProvider);

    return Container(
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
              Text('Running Active', style: appTextStyles.body.bold()),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pinned Windows: $pinnedWindowsCount',
            style: appTextStyles.body,
          ),
          const SizedBox(height: 8),
          Text(
            'Overlay indicators are managed natively.',
            style: appTextStyles.bodyExtraSmall.disabledColor(ref),
          ),
        ],
      ),
    );
  }
}
