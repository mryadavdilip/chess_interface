import 'package:chess_interface/chess_interface_dart.dart';
import 'package:flutter/material.dart';

class ChessBoardProvider extends ChangeNotifier {
  ChessBoardInterface _game = ChessBoardInterface();
  ChessBoardInterface get game => _game;

  void init(ChessBoardInterface newGame) {
    _game = newGame;
    notifyListeners();
  }

  notify() {
    notifyListeners();
  }
}
