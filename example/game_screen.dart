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
            boardSize: 300,
            config: BoardThemeConfig(),
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
