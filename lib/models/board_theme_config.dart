import 'package:flutter/material.dart';
import 'package:chess_interface/env.dart';

/// This class is used to store the board theme configuration
/// It contains the [boardColor] and the [materialVariety] (should be available in this package's assets)
class BoardThemeConfig {
  Color? boardColor;
  String? materialVariety;
  BoardThemeConfig({this.boardColor, this.materialVariety}) {
    boardColor ??= boardColors.first;
    materialVariety ??= materialsResources.keys.first;
  }

  factory BoardThemeConfig.fromMap(Map<String, dynamic> map) =>
      BoardThemeConfig(
        boardColor: Color(
          map['boardColor'] as int? ?? boardColors.first.toARGB32(),
        ),
        materialVariety:
            map['materialVariety'] ?? materialsResources.keys.first,
      );

  Map<String, dynamic> toMap() => {
    'boardColor': boardColor?.toARGB32(),
    'materialVariety': materialVariety,
  };
}
