import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';

extension TextStyleExtension on TextStyle {
  TextStyle bold() => copyWith(fontWeight: FontWeight.bold);

  TextStyle disabledColor(WidgetRef ref) {
    final colors = ref.read(appColorsProvider);
    return copyWith(color: colors.textDisabled);
  }

  TextStyle contextColor(BuildContext context) =>
      copyWith(color: Theme.of(context).colorScheme.primary);

  TextStyle alertColor() => copyWith(color: Colors.red);

  TextStyle nullColor() => copyWith(color: null);
}
