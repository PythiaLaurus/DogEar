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

extension ColorBrightnessExtension on Color {
  Color lighten(
    WidgetRef ref, {
    double lightAmount = 0.1,
    double darkAmount = 0,
  }) {
    assert(lightAmount >= 0 && lightAmount <= 1, 'amount must be between 0~1');
    assert(darkAmount >= 0 && darkAmount <= 1, 'amount must be between 0~1');

    final brightness = ref.read(platformBrightnessProvider);

    if (brightness == Brightness.light && lightAmount > 0) {
      return _adjustLightness(color: this, amount: lightAmount);
    }

    if (brightness == Brightness.dark && darkAmount > 0) {
      return _adjustLightness(color: this, amount: darkAmount);
    }

    return this;
  }

  Color darken(
    WidgetRef ref, {
    double lightAmount = 0.2,
    double darkAmount = 0,
  }) {
    assert(lightAmount >= 0 && lightAmount <= 1, 'amount must be between 0~1');
    assert(darkAmount >= 0 && darkAmount <= 1, 'amount must be between 0~1');

    final brightness = ref.read(platformBrightnessProvider);

    if (brightness == Brightness.light && lightAmount > 0) {
      return _adjustLightness(color: this, amount: -lightAmount);
    }

    if (brightness == Brightness.dark && darkAmount > 0) {
      return _adjustLightness(color: this, amount: -darkAmount);
    }

    return this;
  }

  Color _adjustLightness({required Color color, required double amount}) {
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }
}
