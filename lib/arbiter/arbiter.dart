import 'dart:async';

import 'package:chess_interface/chess_board_widget.dart';
import 'package:chess_interface/logical_interface/interface.dart';
import 'package:chess_interface/logical_interface/piece.dart';
import 'package:flutter/material.dart';

enum GameOverBy {
  checkmate,
  stalemate,
  insufficientMaterial,
  threefoldRepetition,
  fiftyMoveRule,
  draw,
  resign,
  timeOut,
}

class Arbiter {
  /// show your custom dialog or handle your code when pawn promotion is needed, it must return true/false to check and update state if pawn is promoted or not
  final Future<bool> Function(Position position)? onPromotion;

  /// callback when game is over. must return true/false to check and update state if game is reset or not
  final Future<bool> Function(GameOverBy)? onGameOver;

  /// true by default, show dialogs when arbiter detects a state
  final bool showDialogs;

  /// required context to show dialogs, if [showDialogs] is true
  final BuildContext? context;

  Arbiter({
    this.onGameOver,
    this.onPromotion,
    this.showDialogs = true,
    this.context,
  });

  /// countdown for player time, if [game] has [timeLimit]
  /// is being used in [ChessBoardWidget] to start [countdownSpectator] when widget is created
  void countdownSpectator(game) {
    StreamSubscription<int>? whiteTimeSubscription;
    StreamSubscription<int>? blackTimeSubscription;

    if (game.timeLimit != null) {
      whiteTimeSubscription = game.whiteTimeStream.listen((countdown) {
        if (countdown <= 0) {
          game.switchTimer(stop: true);
          whiteTimeSubscription?.cancel();

          spectateForGameEnd(game);
        }
      });

      blackTimeSubscription = game.blackTimeStream.listen((countdown) {
        if (countdown <= 0) {
          game.switchTimer(stop: true);
          blackTimeSubscription?.cancel();

          spectateForGameEnd(game);
        }
      });
    }
  }

  /// returns if player chose a piece (isPromoted)
  Future<bool> promotionCheck(
    ChessBoardInterface game,
    Position position,
  ) async {
    if (game.isEligibleForPromotion(position)) {
      if (onPromotion != null) {
        return await onPromotion!(position);
      } else if (showDialogs) {
        return await _defaultPromotionDialog(game, position);
      }
    }
    return false;
  }

  /// returns if game is over (isReset)
  Future<bool> spectateForGameEnd(ChessBoardInterface game) async {
    GameOverBy? gameOverBy;

    if (game.isCheckmate()) {
      gameOverBy = GameOverBy.checkmate;
    } else if (game.isStalemate()) {
      gameOverBy = GameOverBy.stalemate;
    } else if (game.isDraw) {
      gameOverBy = GameOverBy.draw;
    } else if (game.resign != null) {
      gameOverBy = GameOverBy.resign;
    } else if (game.isTimeOut()) {
      gameOverBy = GameOverBy.timeOut;
    } else if (game.isInsufficientMaterial()) {
      gameOverBy = GameOverBy.insufficientMaterial;
    } else if (game.isThreefoldRepetition()) {
      gameOverBy = GameOverBy.threefoldRepetition;
    } else if (game.isFiftyMoveDraw()) {
      gameOverBy = GameOverBy.fiftyMoveRule;
    }

    if (gameOverBy != null) {
      if (onGameOver != null) {
        onGameOver!(gameOverBy);
      } else if (showDialogs) {
        return await _defaultGameOverDialog(game, gameOverBy);
      }
    }

    return false;
  }

  Future<bool> _defaultPromotionDialog(
    ChessBoardInterface game,
    Position position,
  ) async {
    assert(context != null, "context is required to show dialogs");
    bool isPromoted = false;

    await showDialog(
      context: context!,
      builder:
          (context) => AlertDialog(
            title: const Text("Promote Pawn"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var type in [
                  PieceType.queen,
                  PieceType.rook,
                  PieceType.bishop,
                  PieceType.knight,
                ])
                  ListTile(
                    title: Text(type.toString().split('.').last),
                    onTap: () {
                      game.promotePawn(position, type);
                      Navigator.of(context).pop();
                      isPromoted = true;
                    },
                  ),
              ],
            ),
          ),
    );

    return isPromoted;
  }

  Future<bool> _defaultGameOverDialog(
    ChessBoardInterface game,
    GameOverBy gameOverBy,
  ) async {
    assert(context != null, "context is required to show dialogs");

    bool isReset = false;

    PieceColor? looser =
        gameOverBy == GameOverBy.checkmate
            ? game.turn
            : gameOverBy == GameOverBy.resign
            ? game.resign
            : null;

    showDialog(
      context: context!,
      builder:
          (context) => AlertDialog(
            title: Text(
              "${looser == null
                  ? "Draw"
                  : looser == PieceColor.white
                  ? "Black wins!"
                  : "White wins!"} by ${gameOverBy.name}",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  game.reset();
                  Navigator.of(context).pop();
                  isReset = true;
                },
                child: const Text("Restart"),
              ),
            ],
          ),
    );

    return isReset;
  }
}
