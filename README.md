[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://www.buymeacoffee.com/mryadavdilip)

# chess_interface

This is a flutter package and doesn't support pure dart based project. For dart / backend project, checkout [chess_interface_dart](https://www.pub.dev/packages/chess_interface_dart) Package.

A customizable, feature-rich chess board widget built in Flutter. This package offers a robust foundation for integrating chess gameplay into your Flutter apps — complete with piece rendering, move validation, theming, and more.

## Features

- ♟️ Full chess piece support with images
- ✅ Built-in move validation for all standard piece types
- ♻️ Customizable board themes and piece materials
- 🔄 Supports en passant, castling, and pawn promotion logic
- 📐 Interface-driven board interaction for flexible state management
- 🎨 Material Design color extensions for theming

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  chess_interface:
    git:
      url: https://github.com/mryadavdilip/chess_interface.git
```

OR

```yaml
dependencies:
  chess_interface: ^1.1.6
```

Then import these:

```dart
import 'package:chess_board_widget/chess_board_widget.dart';
import 'package:chess_board_widget/logical_interface/interface.dart';
import 'package:chess_board_widget/models/BoardThemeConfig.dart';
```

Initialize ChessBoardProvider in your project

```dart
MultiProvider(
  providers: [
    ListenableProvider<ChessBoardProvider>(create: (_) => ChessBoardProvider()),
  ],
  child: Scaffold(
    body: ChessBoardWidget(),
  ),
);
```

## Example

See [Example](example/main.dart) for more details and refer to comments in the code

```dart
import 'dart:math';
import 'package:chess_interface/arbiter/flutter_arbiter.dart';
import 'package:chess_interface/extensions/chess_piece.dart';
import 'package:chess_interface/extensions/color.dart';
import 'package:chess_interface/extensions/piece_color.dart';
import 'package:chess_interface/chess_interface_dart.dart';
import 'package:flutter/material.dart';
import 'package:chess_interface/models/board_theme_config.dart';

/// initialize game
Provider.of<ChessBoardProvider>(context, listen: false).init(
  ChessBoardInterface(
    fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    timeLimit: const Duration(minutes: 10),
  ),
);

/// use chess board widget
ChessBoardWidget(
  game: Provider.of<ChessBoardProvider>(context, listen: true).game,

  // optional
  onMove: (Position from, Position to) {},

  // optional
  playAs: PieceColor.black,

  // false by default
  rotateBoard: true,

  arbiter: FlutterArbiter(
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


/// call this to rebuild ChessBoardWidget, when some change is made to the [ChessBoardInterface]
Provider.of<ChessBoardProvider>(context, listen: false).notify();
```

## Configuration

### Theme Customization

Customize the board and pieces using `BoardThemeConfig`. You can define your own colors and piece styles via the asset directory:

```dart
BoardThemeConfig(
  boardColor: Colors.green[700],
  materialVariety: 'modern_minimalist',
);
```

### Piece Rendering

The `ChessPiece` class loads the appropriate asset based on the type, color, and selected material style:

```dart
ChessPiece(type: PieceType.queen, color: PieceColor.black)
  .getResource('classic');
```

### Move Validation

Use `MoveValidator.isValidMove()` to validate legal chess moves:

```dart
bool isValid = MoveValidator.isValidMove(ChessBoardInterface game, Position from, Position to);
```

It supports:

- All standard chess moves
- Pawn special rules
- Castling logic (including history tracking)
- En passant and double pawn pushes

### FlutterArbiter (extends Arbiter)

FlutterArbiter to handle events like game over, time out and pawn promotion:

## And more..

## File Structure

- `chess_board_widget.dart` – Main UI and logic
- `move_validator.dart` – Move legality checker
- `piece.dart` – Piece model and asset loader
- `arbiter.dart` – Game over, timeOut, and promotion handler
- `board_theme_config.dart` – Customization config
- `color_extension.dart` – Color manipulation utilities
- `interface.dart` – Board interaction interface
- `env.dart` – Environment configuration for materials and colors

## Assets

Ensure your `pubspec.yaml` declares your assets like so:

```yaml
flutter:
  assets:
    - assets/classic/pawn.png
    - assets/wooden/king.png
```

## Contributing

Contributions are welcome! Please open issues and pull requests to help improve this [Package](https://www.github.com/mryadavdilip/chess_interface.git).

## License

MIT License. See [LICENSE](LICENSE) for details.
