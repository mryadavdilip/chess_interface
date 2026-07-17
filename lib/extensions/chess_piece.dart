import 'package:chess_interface/chess_interface_dart.dart';
import 'package:chess_interface/env.dart';
import 'package:chess_interface/extensions/piece_color.dart';
import 'package:flutter/widgets.dart';

extension ChessPieceExtension on ChessPiece {
  /// Default asset-path based resource loader.
  ///
  /// Host apps should generally prefer passing [BoardThemeConfig.pieceImageProvider]
  /// instead of relying on this method.
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
