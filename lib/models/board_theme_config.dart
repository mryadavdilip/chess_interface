import 'package:flutter/material.dart';
import 'package:chess_interface/env.dart';

/// This class is used to store the board theme configuration
/// It contains the [boardColor] and the [materialVariety] (should be available in this package's assets)
class BoardThemeConfig {
  Color? boardColor;

  /// To add your own resources, refer to the assets folder structure inside this package.
  /// If your resources includes sparate materials for each color, add to path like this: "assets/your_materials_name/black/king.png" (or /white/ for white pieces). and same for all other pieces.
  /// If you've simple and fillable png recourses, simply add them in "assets/your_materials_name/bishop.png" path.
  String? materialVariety;

  String? directory;

  /// The extension of the image file. Default is png.
  String? extension;
  BoardThemeConfig({
    this.boardColor,
    this.materialVariety,
    this.directory,
    this.extension,
  }) {
    // Set default values if not provided
    boardColor ??= boardColors.first;
    materialVariety ??= materialsResources.keys.first;
    directory ??= 'packages/chess_interface/assets';
    extension ??= 'png';
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
