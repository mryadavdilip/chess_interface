import 'package:chess_interface/utils/color_extension.dart';
import 'package:flutter/material.dart';
import 'package:chess_interface/models/board_theme_config.dart';
import 'package:gradient_circular_progress_indicator/gradient_circular_progress_indicator.dart';
import 'package:chess_interface/logical_interface/interface.dart';
import 'package:chess_interface/logical_interface/piece.dart';

class ChessBoardWidget extends StatefulWidget {
  final ChessBoardInterface game;

  /// It should be used to show the promotion dialog when a pawn reaches the last rank, or pawn on the last rank is tapped. Use [game].promotePawn([Position], [PieceType]) to promote the pawn.
  final ValueChanged<Position>? onPromotion;

  /// [PieceColor] of the player who is in checkmate (losing)
  final ValueChanged<PieceColor>? onCheckmate;

  // Define board size using ScreenUtil for responsive design
  final double boardSize;

  final BoardThemeConfig config;
  const ChessBoardWidget({
    super.key,
    required this.game,
    this.onPromotion,
    this.onCheckmate,
    required this.boardSize,
    required this.config,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  Position? selectedPosition;
  List<Position> validMoves = [];

  void onSquareTap(int row, int col) {
    Position tappedPosition = Position(row: row, col: col);
    ChessPiece? piece = widget.game.getPiece(tappedPosition);

    // If it's your turn and you tap on a pawn on the promotion rank, show the promotion dialog.
    if (piece != null &&
        piece.color == widget.game.turn &&
        piece.type == PieceType.pawn &&
        (tappedPosition.row == 0 || tappedPosition.row == 7)) {
      widget.onPromotion == null
          ? _defaultPromotionDialog(tappedPosition)
          : widget.onPromotion!(tappedPosition);
      return; // Exit so that the normal selection/move logic isn't executed.
    }

    // Normal selection/move process:
    if (selectedPosition == null) {
      if (piece != null && piece.color == widget.game.turn) {
        selectedPosition = tappedPosition;
        validMoves = widget.game.getValidMoves(tappedPosition);
      }
    } else {
      // If a piece is already selected, attempt to move it.
      if (widget.game.move(selectedPosition!, tappedPosition)) {
        checkForPawnPromotion(tappedPosition);
        if (widget.game.isCheckmate()) {
          widget.onCheckmate == null
              ? _defaultCheckmateDialog(widget.game.turn)
              : widget.onCheckmate!(widget.game.turn);
        }
      }
      selectedPosition = null;
      validMoves = [];
    }
    setState(() {});
  }

  void checkForPawnPromotion(Position position) {
    ChessPiece? piece = widget.game.getPiece(position);
    if (piece?.type == PieceType.pawn) {
      if (position.row == 0 || position.row == 7) {
        widget.onPromotion == null
            ? _defaultPromotionDialog(position)
            : widget.onPromotion!(position);
      }
    }
  }

  void _defaultPromotionDialog(Position position) {
    showDialog(
      context: context,
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
                      widget.game.promotePawn(position, type);
                      Navigator.of(context).pop();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
    );
  }

  void _defaultCheckmateDialog(PieceColor turn) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Game Over"),
            content: Text(
              turn == PieceColor.white ? "Black wins!" : "White wins!",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  widget.game.reset();
                  setState(() {});
                  Navigator.of(context).pop();
                },
                child: const Text("Restart"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double boxSize = widget.boardSize / 8;

    return SizedBox(
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
            onTap: () => onSquareTap(row, col),
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
                          widget.config.boardColor!.toMaterialColor()[1] ??
                              Colors.white,
                          widget.config.boardColor!.toMaterialColor()[2] ??
                              Colors.black,
                        ],
                      ),
                    ),
                  FutureBuilder(
                    key: ValueKey('$row-$col-${piece?.type}'),
                    future: piece?.getResource(widget.config.materialVarity!),
                    builder: (context, ss) {
                      return Padding(
                        padding: EdgeInsets.all(
                          piece?.type == PieceType.pawn
                              ? boxSize * 0.2
                              : boxSize * 0.1,
                        ),
                        child: ss.data ?? SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
