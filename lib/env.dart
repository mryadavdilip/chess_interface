import 'package:chess_interface/chess_interface_dart.dart';
import 'package:flutter/material.dart';

/// To add your own resources, refer to the assets folder structure inside this package.
/// If your resources includes sparate materials for each color, add to path like this: "assets/your_materials_name/black/king.png" (or /white/ for white pieces). and same for all other pieces.
/// If you've simple and fillable png recourses, simply add them in "assets/your_materials_name/bishop.png" path.
Map<String, dynamic> materialsResources = {
  'silhoutte_minimalist': {
    'black': PieceType.values.map((e) => '${e.name}.png').toList(),
    'white': PieceType.values.map((e) => '${e.name}.png').toList(),
  },
  'modern_minimalist': PieceType.values.map((e) => '${e.name}.png').toList(),
};

List<Color> boardColors = [Colors.brown, Colors.green, Colors.red];
