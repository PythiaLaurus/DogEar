import 'dart:math';
import 'package:flutter/painting.dart';

export 'color_hex_extention.dart';

/// Core logic for color handling.
class ColorUtils {
  /// Calculate whether the foreground color should be white to ensure contrast
  /// based on a perceptual brightness heuristic.:<br>
  ///
  /// 0.299 * R + 0.587 * G + 0.114 * B<br>
  ///
  /// This method uses NTSC / Rec.601 coefficients (0.299 R, 0.587 G, 0.114 B)
  /// combined with a root-mean-square (RMS) calculation to approximate perceived brightness.
  ///
  /// - The threshold value of 0.5 is used as an empirical decision point:
  ///   brightness < 0.5 → use white foreground, otherwise use black foreground.
  static bool useWhiteForeground(Color backgroundColor) {
    double v = sqrt(
      pow(backgroundColor.r, 2) * 0.299 +
          pow(backgroundColor.g, 2) * 0.587 +
          pow(backgroundColor.b, 2) * 0.114,
    );

    return v < 0.5;
  }

  /// Extracts and normalizes a valid 8-digit Hex string (RRGGBBAA) from any input.
  ///
  /// Steps:
  /// 1. Removes all non-hex characters (including #).
  /// 2. Truncates to the first 8 characters.
  /// 3. Expands the string based on its length according to specific rules.
  ///
  /// Expansion Rules (Input -> Output RRGGBBAA):
  /// - 1 char  (1)        -> 111111FF (Repeat char for RGB, A=FF)
  /// - 2 chars (12)       -> 121212FF (Repeat sequence for RGB, A=FF)
  /// - 3 chars (123)      -> 112233FF (Standard RGB short, A=FF)
  /// - 4 chars (1234)     -> 11223344 (Standard ARGB short)
  /// - 5 chars (12345)    -> 11223345 (RGB expanded, A=Raw)
  /// - 6 chars (123456)   -> 123456FF (Standard RGB, A=FF)
  /// - 7 chars (1234567)  -> 12345677 (Standard RGB, A=LastChar repeated)
  /// - 8 chars (12345678) -> 12345678 (Full code)
  ///
  /// Returns null if the input contains no valid hex digits.
  static String? extractValidHexCode(String? input) {
    if (input == null || input.isEmpty) return null;

    // Remove all special characters (keep only 0-9, a-f, A-F)
    String clean = input.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');

    if (clean.isEmpty) return null;

    // Truncate to max 8 digits
    if (clean.length > 8) {
      clean = clean.substring(0, 8);
    }

    final StringBuffer sb = StringBuffer();

    // Apply expansion rules
    switch (clean.length) {
      case 1: // 1 -> 111111FF
        sb.write(clean * 6);
        sb.write('FF');
        break;
      case 2: // 12 -> 121212FF
        sb.write(clean * 3);
        sb.write('FF');
        break;
      case 3: // 123 -> 112233FF
        sb.write(clean[0] * 2);
        sb.write(clean[1] * 2);
        sb.write(clean[2] * 2);
        sb.write('FF');
        break;
      case 4: // 1234 -> 11223344
        sb.write(clean[0] * 2);
        sb.write(clean[1] * 2);
        sb.write(clean[2] * 2);
        sb.write(clean[3] * 2);
        break;
      case 5: // 12345 -> 11223345
        // First 3 chars expand to RRGGBB, last 2 chars are AA
        sb.write(clean[0] * 2);
        sb.write(clean[1] * 2);
        sb.write(clean[2] * 2);
        sb.write(clean.substring(3));
        break;
      case 6: // 123456 -> 123456FF
        sb.write(clean);
        sb.write('FF');
        break;
      case 7: // 1234567 -> 12345677
        sb.write(clean.substring(0, 6)); // RRGGBB
        sb.write(clean[6] * 2); // Expand last char for AA
        break;
      case 8: // 12345678 -> 12345678
        sb.write(clean);
        break;
    }

    return sb.toString().toUpperCase();
  }

  /// Parses a color from a flexible Hex string.
  ///
  /// [hex] The input string.
  /// [enableAlpha] If true, uses the alpha value from the parsed hex.
  /// If false, forces the alpha to 1.0 (0xFF), ignoring the input alpha.
  static Color? colorFromHex(String hex, {bool enableAlpha = true}) {
    // Get the normalized 8-digit hex string (RRGGBBAA)
    final String? normalizedHex = extractValidHexCode(hex);
    if (normalizedHex == null) return null;

    // Extract components
    // normalizedHex is strictly RRGGBBAA at this point.
    final String rgbHex = normalizedHex.substring(0, 6);
    final String alphaHex = normalizedHex.substring(6, 8);

    // Construct the ARGB string for parsing
    // Flutter Color(int) expects 0xAARRGGBB.
    final String finalAlpha = enableAlpha ? alphaHex : 'FF';
    final String finalHexColor = '$finalAlpha$rgbHex';

    // Parse
    final int? intVal = int.tryParse(finalHexColor, radix: 16);
    if (intVal == null) return null;

    return Color(intVal);
  }
}
