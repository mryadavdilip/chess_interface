import 'package:flutter/material.dart';
import 'package:chess_interface/env.dart';

class BoardThemeConfig {
  Color? boardColor;
  String? materialVarity;
  BoardThemeConfig({this.boardColor, this.materialVarity}) {
    boardColor ??= boardColors.first;
    materialVarity ??= materialsResources.keys.first;
  }

  factory BoardThemeConfig.fromMap(Map<String, dynamic> map) =>
      BoardThemeConfig(
        boardColor: Color(
          map['boardColor'] as int? ?? boardColors.first.toARGB32(),
        ),
        materialVarity: map['materialVarity'] ?? materialsResources.keys.first,
      );

  Map<String, dynamic> toMap() => {
    'boardColor': boardColor?.toARGB32(),
    'materialVarity': materialVarity,
  };
}
