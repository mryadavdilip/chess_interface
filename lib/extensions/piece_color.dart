import 'package:chess_interface_dart/logical_interface/piece.dart';
import 'package:flutter/material.dart';

extension PieceColorExtension on PieceColor {
  Color toColor() => switch (this) {
    PieceColor.white => Colors.white,
    PieceColor.black => Colors.black,
  };
}
