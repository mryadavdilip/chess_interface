import 'package:flutter/material.dart';

extension ColorExtension on Color {
  MaterialColor toMaterialColor() {
    return MaterialColor(toARGB32(), {
      // lighten colors
      1: this + 0.5,
      2: this + 0.1,
    });
  }

  Color operator +(double lightness) {
    HSLColor hsl = HSLColor.fromColor(this);

    return hsl
        .withLightness((hsl.lightness + lightness).clamp(0.0, 1.0).toDouble())
        .toColor();
  }

  Color operator -(double lightness) {
    HSLColor hsl = HSLColor.fromColor(this);

    return hsl
        .withLightness((hsl.lightness - lightness).clamp(0.0, 1.0).toDouble())
        .toColor();
  }
}
