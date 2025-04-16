import 'package:chess_interface/arbiter/arbiter.dart';
import 'package:chess_interface/env.dart';
import 'package:chess_interface/logical_interface/piece.dart';
import 'package:chess_interface/models/board_theme_config.dart';
import 'package:flutter/material.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:chess_interface/chess_board_widget.dart';
import 'package:chess_interface/logical_interface/interface.dart';

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
              context: context,
              onGameOver: (gameOverBy) async {
                // handle gameover
                return true;
              },
              onPromotion: (position) async {
                // handle promotion
                return true;
              },
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
