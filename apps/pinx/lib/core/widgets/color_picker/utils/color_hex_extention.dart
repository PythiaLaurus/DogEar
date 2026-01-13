// ignore_for_file: constant_identifier_names

import 'dart:ui' show Color;

extension ColorHexExtention on Color {
  /// Converts this color to a hex string.
  ///
  /// [order] controls the component order:
  /// - RGB: #RRGGBB (no alpha)
  /// - RGBA: #RRGGBBAA
  /// - ARGB: #AARRGGBB
  ///
  /// [withLeadingHash]: whether to prefix the result with '#'.
  String toHexString({ColorHexOrder order = .RGB, bool withLeadingHash = true}) {
    final argbInt = toARGB32();
    // Extract channels from ARGB integer
    final alphaHex = ((argbInt >> 24) & 0xFF)
        .toRadixString(16)
        .padLeft(2, '0')
        .toUpperCase();
    final redHex = ((argbInt >> 16) & 0xFF)
        .toRadixString(16)
        .padLeft(2, '0')
        .toUpperCase();
    final greenHex = ((argbInt >> 8) & 0xFF)
        .toRadixString(16)
        .padLeft(2, '0')
        .toUpperCase();
    final blueHex = ((argbInt >> 0) & 0xFF)
        .toRadixString(16)
        .padLeft(2, '0')
        .toUpperCase();

    String hex;
    switch (order) {
      case ColorHexOrder.RGB:
        hex = '$redHex$greenHex$blueHex';
        break;
      case ColorHexOrder.RGBA:
        hex = '$redHex$greenHex$blueHex$alphaHex';
        break;
      case ColorHexOrder.ARGB:
        hex = '$alphaHex$redHex$greenHex$blueHex';
        break;
    }

    return withLeadingHash ? '#$hex' : hex;
  }
}

enum ColorHexOrder {
  /// #RRGGBBAA
  RGBA,

  /// #AARRGGBB
  ARGB,

  /// #RRGGBB
  RGB,
}
