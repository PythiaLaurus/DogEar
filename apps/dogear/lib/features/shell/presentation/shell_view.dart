import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            const Icon(Icons.push_pin, size: 20),
            const SizedBox(width: 12),
            Text(
              'Dog Ear Settings',
              style: appTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: widget.child,
    );
  }
}
