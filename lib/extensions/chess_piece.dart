import 'package:chess_interface/env.dart';
import 'package:chess_interface/extensions/piece_color.dart';
import 'package:chess_interface_dart/logical_interface/piece.dart';
import 'package:flutter/widgets.dart';

extension ChessPieceExtension on ChessPiece {
  /// Provide [directory] (e.g, 'assets' or 'assets/materials') if you want to use custom resources.
  /// Provide [extension] (e.g, png, jpg, jpeg) for the images you've inside the resource structured directory.
  Future<Image> getResource(
    String materialVariety, {
    required String directory,
    required String extension,
  }) async {
    bool sameFolderForBothColors =
        materialsResources[materialVariety] is List<String>;
    String path =
        '$directory/$materialVariety/${sameFolderForBothColors ? '' : '${color.name}/'}${type.name}.$extension';

    return Image.asset(
      path,
      color: sameFolderForBothColors ? color.toColor() : null,
      fit: BoxFit.contain,
    );
  }
}
