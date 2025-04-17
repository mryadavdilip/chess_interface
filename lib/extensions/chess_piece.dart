import 'package:chess_interface/env.dart';
import 'package:chess_interface/extensions/piece_color.dart';
import 'package:chess_interface_dart/logical_interface/piece.dart';
import 'package:flutter/widgets.dart';

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
