import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../configs/app_config.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/normal_app_bar.dart';

class ShellView extends ConsumerStatefulWidget {
  final Widget child;

  const ShellView({super.key, required this.child});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ShellViewState();
}

class _ShellViewState extends ConsumerState<ShellView> {
  @override
  Widget build(BuildContext context) {
    final appColors = ref.watch(appColorsProvider);
    final appTextStyles = ref.watch(appTextStylesProvider);

    return Scaffold(
      backgroundColor: appColors.primary,
      appBar: NormalAppBar(
        title: Row(
          children: [
            Image.asset(AppConfig.iconPath, width: 22, height: 22),
            const SizedBox(width: 12),
            Text('DogEar Settings', style: appTextStyles.body.bold()),
          ],
        ),
      ),
      body: widget.child,
    );
  }
}
