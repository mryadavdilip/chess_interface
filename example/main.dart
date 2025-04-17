import 'package:chess_interface/arbiter/arbiter.dart';
import 'package:chess_interface/env.dart';
import 'package:chess_interface/logical_interface/move_validator.dart';
import 'package:chess_interface/logical_interface/piece.dart';
import 'package:chess_interface/models/board_theme_config.dart';
import 'package:flutter/material.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:chess_interface/chess_board_widget.dart';
import 'package:chess_interface/logical_interface/interface.dart';

ChessBoardInterface game = ChessBoardInterface(
  // optional
  fen: 'qkN/p7/8/8/8...',

  // optional
  timeLimit: Duration(minutes: 10),
);

Arbiter arbiter = Arbiter(
  onGameOver: (GameOverBy gameOverBy) {
    if (gameOverBy == GameOverBy.resign) {
      debugPrint(game.turn.name); // player resigned
    }
  },
);

someFunc() {
  MoveValidator.canCastleKingSide(game, PieceColor.black);
  MoveValidator.canCastleQueenSide(game, PieceColor.black);

  // start spectation for countdown
  arbiter.countdownSpectator(game);

  // check whether game is over for any reason, draw, checkmate, time-over, etc. It shows provided or default dialog accordingly
  arbiter.checkForGameEnd(game);

  // get legal moves for a particular ChessPiece
  game.getValidMoves(Position(row: 5, col: 3));

  // Use this to move a piece with validations
  game.move(Position(row: 3, col: 2), Position(row: 6, col: 2));

  // Use this to move a piece without validation
  game.movePiece(Position(row: 3, col: 2), Position(row: 7, col: 5));

  // Read black player's time left (in seconds)
  game.blackTimeStream.listen((time) {
    debugPrint('Black\'s time left: $time');
  });

  // Read white player's time left (in seconds)
  game.whiteTimeStream.listen((time) {
    debugPrint('White\'s time left: $time');
  });

  game.resign =
      PieceColor
          .black; // set resignation, and then call arbiter.checkForGameEnd method if countdownSpectator is not spectating already.

  // Which player is to move
  game.turn;

  // To access arrangement of board pieces in 2D List
  game.board;

  // FEN of the current game state
  game.toFEN();

  // En-passant target (when a pawn moves two boxes, e.g., from initial (2nd) rank to 4th rank , it becomes en-passant target)
  game.enPassantTarget;

  // get half move clock (int)
  game.halfMoveClock;

  // get full move number (int)
  game.fullMoveNumber;

  // List of full FEN strings. Doesn't includes current state
  game.history;

  // List of full FEN strings
  game.redoHistory;

  // whether it's draw for any reason
  game.isDraw;

  // verify checkmate state
  game.isCheckmate();

  // check whether pawn on a position, eligible for promotion
  game.isEligibleForPromotion(Position(row: 7, col: 1));

  // check if game state complies with fifty-move draw rule
  game.isFiftyMoveDraw();

  // check whether board has insufficient materials left
  game.isInsufficientMaterial();

  // check whether king is in check
  game.isKingInCheck();

  // check whether it's stalemate
  game.isStalemate();

  // check whether it's threefold repetition
  game.isThreefoldRepetition();

  // check whether timeout for any player
  game.isTimeOut();
}

void main(List<String> args) {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: GameScreen());
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  ChessBoardInterface game = ChessBoardInterface();
  Position? selectedPosition;
  List<Position> validMoves = [];

  void _saveGame() async {
    // await StorageService.saveGameState(game.toFEN());
  }

  void _resetGame() {
    game = ChessBoardInterface();
    setState(() {});
  }

  void _shareGame() {
    // Share.share("Check out my chess game:\n${game.toFEN()}");
  }

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Chess"),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveGame),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetGame),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareGame),
        ],
      ),
      body: Column(
        children: [
          ChessBoardWidget(
            game: game,
            // optional
            onMove: (Position from, Position to) {},
            // optional
            playAs: PieceColor.black,

            // false by default
            rotateBoard: true,
            arbiter: Arbiter(
              showDialogs: true,
              context: context,
              onGameOver: (gameOverBy) {
                // todo: handle gameOver
              },

              // optional
              onReachingPromotionRank: (position) async {
                // todo: show pieces to player to promote and must return whether player chose a piece or not, if returns false (i.e, player doesn't choose a piece), default promotion is made to queen.
                return true;
              },

              // callback when either player chose a piece or promoted to default (queen)
              onPromoted: (position, promotedTo) {},
            ),
            // true by default
            spectateInitially: false,
            boardSize: 300,
            config: BoardThemeConfig(
              boardColor: Colors.limeAccent,

              /// To add your own resources, refer to the assets folder structure inside this package. If your resources includes sparate materials for each color, add to path like this: "assets/your_materials_name/black/king.png" (or /white/ for white pieces). and same for all other pieces. If you've simple and fillable png recourses, simply add them in "assets/your_materials_name/bishop.png" path.
              materialVariety: materialsResources.keys.first,
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MaterialButton(
                onPressed:
                    game.canUndo()
                        ? () {
                          game.undo();
                          selectedPosition = null;
                          validMoves.clear();
                          setState(() {});
                        }
                        : null,
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              MaterialButton(
                onPressed:
                    game.canRedo()
                        ? () {
                          game.redo();
                          selectedPosition = null;
                          validMoves.clear();
                          setState(() {});
                        }
                        : null,
                child: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
