import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../app_colors/app_colors.dart';

export 'text_style_extension.dart';

part 'app_text_styles.g.dart';

/// Text Styles.
class AppTextStyles {
  final Ref ref;
  late final AppColors colors;
  static const String _fontFamily = "NotoSans";
  static const String _fontFamilyFallback = "NotoSansSC";
  AppTextStyles(this.ref) {
    colors = ref.watch(appColorsProvider);
  }

  TextStyle get body {
    return TextStyle(
      fontSize: 14,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.normal,
      color: colors.textPrimary,
      fontFamily: _fontFamily,
      fontFamilyFallback: [_fontFamilyFallback],
    );
  }

  // Body Large Text
  TextStyle get bodyLarge {
    return body.copyWith(fontSize: 16);
  }

  TextStyle get bodyExtraLarge {
    return body.copyWith(fontSize: 18);
  }

  // Body Small Text
  TextStyle get bodySmall {
    return body.copyWith(fontSize: 12);
  }

  TextStyle get bodyExtraSmall {
    return body.copyWith(fontSize: 10);
  }

  // Title && Larger Text
  TextStyle get title {
    return body.copyWith(fontSize: 20);
  }

  TextStyle get titleLarge {
    return body.copyWith(fontSize: 24);
  }

  // Headline && Larger Text
  TextStyle get headline {
    return body.copyWith(fontSize: 32);
  }

  TextStyle get headlineLarge {
    return body.copyWith(fontSize: 48);
  }
}

@riverpod
AppTextStyles appTextStyles(Ref ref) {
  return AppTextStyles(ref);
}
