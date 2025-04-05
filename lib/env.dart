import 'package:flutter/material.dart';
import 'package:chess_interface/logical_interface/piece.dart';

Map<String, dynamic> materialsResources = {
  'silhoutte_minimalist': {
    'black': PieceType.values.map((e) => '${e.name}.png').toList(),
    'white': PieceType.values.map((e) => '${e.name}.png').toList(),
  },
  'modern_minimalist': PieceType.values.map((e) => '${e.name}.png').toList(),
};

List<Color> boardColors = [Colors.brown, Colors.green, Colors.red];
