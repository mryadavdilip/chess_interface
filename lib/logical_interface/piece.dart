import 'package:flutter/material.dart';
import 'package:chess_interface/env.dart';

enum PieceType { pawn, knight, bishop, rook, queen, king }

enum PieceColor { white, black }

extension PieceColorExtension on PieceColor {
  Color toColor() => switch (this) {
    PieceColor.white => Colors.white,
    PieceColor.black => Colors.black,
  };
}

class ChessPiece {
  final PieceType type;
  final PieceColor color;

  ChessPiece({required this.type, required this.color});
}

extension ChessPieceExtension on ChessPiece {
  Future<Image> getResource(String materialVariety) async {
    bool sameFolderForBothColors =
        materialsResources[materialVariety] is List<String>;
    String path =
        'packages/chess_interface/assets/$materialVariety/${sameFolderForBothColors ? '' : '${color.name}/'}${type.name}.png';

    return Image.asset(
      path,
      color: sameFolderForBothColors ? color.toColor() : null,
      fit: BoxFit.contain,
    );
  }
}
