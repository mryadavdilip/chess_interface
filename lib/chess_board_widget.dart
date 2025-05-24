import 'dart:math';
import 'package:chess_interface/arbiter/flutter_arbiter.dart';
import 'package:chess_interface/chess_interface_dart.dart';
import 'package:chess_interface/extensions/chess_piece.dart';
import 'package:chess_interface/extensions/color.dart';
import 'package:chess_interface/extensions/piece_color.dart';
import 'package:chess_interface/providers/chess_board_provider.dart';
import 'package:flutter/material.dart';
import 'package:chess_interface/models/board_theme_config.dart';
import 'package:gradient_circular_progress_indicator/gradient_circular_progress_indicator.dart';
import 'package:provider/provider.dart';

class ChessBoardWidget extends StatefulWidget {
  final ChessBoardInterface game;

  final FlutterArbiter arbiter;

  /// Define which side the player has to play, black or white and the other pieces will be no longer be interactive for the player. Keep this null when both players are playing in same device (i.e. in case of offline match).
  final PieceColor? playAs;

  /// Callback when player moves. (if playAs is null, this function is called for both players moves, otherwise for only for the [playAs]). E.g. if the player is playing as white, this method receives callbacks only for white's moves.
  final Function(Position, Position)? onMove;

  /// Whether to rotate the board after each move is made. false by default
  final bool rotateBoard;

  /// If true, arbiter will spectate the game and check for checkmate or stalemate.
  /// If false, the game will be played without arbiter's intervention.
  /// This is useful for testing purposes or if you want to handle game logic manually.
  final bool spectateInitially;

  // Define board size using ScreenUtil for responsive design
  final double boardSize;

  final BoardThemeConfig config;
  const ChessBoardWidget({
    super.key,
    required this.game,
    required this.arbiter,
    this.playAs,
    this.onMove,
    this.rotateBoard = false,
    this.spectateInitially = true,
    required this.boardSize,
    required this.config,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  Position? selectedPosition;
  List<Position> validMoves = [];

  double get angle =>
      (widget.rotateBoard && widget.game.turn == PieceColor.black) ||
              widget.playAs == PieceColor.black
          ? pi
          : 0; // pi for 180 degree rotation

  // Helper to attempt a move and reset selection
  void attemptMove(Position from, Position to) {
    if (widget.game.move(from, to)) {
      widget.arbiter.promotionCheck(widget.game, to).then((v) {
        if (v) setState(() {});
      });
      widget.arbiter.showDialogOnGameOver(widget.game).then((v) {
        if (v) setState(() {});
      });
      if (widget.onMove != null) {
        widget.onMove!(from, to);
      }
    }
    selectedPosition = null;
    validMoves = [];
    setState(() {});
  }

  // Helper to select a piece and show valid moves
  void select(Position pos) {
    selectedPosition = pos;
    validMoves = widget.game.getValidMoves(pos);
    setState(() {});
  }

  void _onSquareTap(int row, int col) {
    Position tappedPosition = Position(row: row, col: col);
    ChessPiece? piece = widget.game.getPiece(tappedPosition);

    bool isOnline = widget.playAs != null;
    bool isPlayerPiece = piece != null && piece.color == widget.playAs;
    bool isTurnPiece = piece != null && piece.color == widget.game.turn;

    if (selectedPosition == null) {
      if ((isOnline && isPlayerPiece) || (!isOnline && isTurnPiece)) {
        select(tappedPosition);
      }
    } else {
      attemptMove(selectedPosition!, tappedPosition);
    }
  }

  @override
  void initState() {
    if (widget.spectateInitially) {
      widget.arbiter.checkForGameEnd(widget.game); // handler for game over
    }

    widget.arbiter.countdownSpectator(widget.game); // timeout handler
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double boxSize = widget.boardSize / 8;

    return Consumer<ChessBoardProvider>(
      builder: (_, chessBoardProvider, __) {
        return Transform.rotate(
          angle: angle,
          child: SizedBox(
            height: widget.boardSize,
            width: widget.boardSize,
            child: GridView.builder(
              itemCount: 64,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1,
                mainAxisExtent: boxSize,
              ),
              itemBuilder: (context, index) {
                int row = index ~/ 8;
                int col = index % 8;
                bool isWhite = (row + col) % 2 == 0;

                Position pos = Position(row: row, col: col);
                ChessPiece? piece = widget.game.getPiece(pos);

                return GestureDetector(
                  onTap: () => _onSquareTap(row, col),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isWhite
                              ? widget.config.boardColor!.toMaterialColor()[1]
                              : widget.config.boardColor!.toMaterialColor()[2],
                      border:
                          selectedPosition == pos
                              ? Border.all(
                                color: widget.game.turn.toColor(),
                                width: boxSize * 0.1,
                              )
                              : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (validMoves.contains(pos))
                          GradientCircularProgressIndicator(
                            progress: 100,
                            stroke: boxSize * 0.1,
                            size:
                                widget.game.board[row][col] == null
                                    ? boxSize * 0.9
                                    : boxSize * 0.75,
                            gradient: SweepGradient(
                              transform: GradientRotation(45),
                              colors: [
                                widget.game.turn.toColor(),
                                widget.config.boardColor!
                                        .toMaterialColor()[1] ??
                                    Colors.white,
                                widget.config.boardColor!
                                        .toMaterialColor()[2] ??
                                    Colors.black,
                              ],
                            ),
                          ),
                        FutureBuilder(
                          key: ValueKey('$row-$col-${piece?.type}'),
                          future: piece?.getResource(
                            widget.config.materialVariety!,
                            directory: widget.config.directory!,
                            extension: widget.config.extension!,
                          ),
                          builder: (context, ss) {
                            return Transform.rotate(
                              angle: angle,
                              child: Padding(
                                padding: EdgeInsets.all(
                                  piece?.type == PieceType.pawn
                                      ? boxSize * 0.2
                                      : boxSize * 0.1,
                                ),
                                child: ss.data ?? SizedBox.shrink(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
