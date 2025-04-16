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
  /// _defaultPromotionDialog is shown if this field is null and [showDialogs] is true. Callback is made when a pawn reaches the promotion rank. Use [ChessBoardInterface].promotePawn([Position], [PieceType]) to promote the pawn and return the promotion status either true or false.
  final Future<bool> Function(Position position)? onPromotion;

  /// Callback when game is over. must return true/false to check and update state if game is reset or not
  final Future<bool> Function(GameOverBy)? onGameOver;

  /// true by default, show dialogs when arbiter detects a state
  final bool showDialogs;

  /// Required context to show dialogs, if [showDialogs] is true
  final BuildContext? context;

  Arbiter({
    this.onGameOver,
    this.onPromotion,
    this.showDialogs = true,
    this.context,
  });

  /// Countdown for player time, if [game] has [timeLimit].
  /// It is being used in [ChessBoardWidget] to start [countdownSpectator] when widget is created
  void countdownSpectator(ChessBoardInterface game) {
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

  /// Returns true if player chose a piece (isPromoted)
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
      barrierDismissible: false,
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

    if (!isPromoted) {
      game.promotePawn(position, PieceType.queen);
      isPromoted = true;
    }

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
