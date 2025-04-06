[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://www.buymeacoffee.com/mryadavdilip)


# chess_interface

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
  chess_interface: ^1.0.2
```

Then import these:

```dart
import 'package:chess_board_widget/chess_board_widget.dart';
import 'package:chess_board_widget/logical_interface/interface.dart';
import 'package:chess_board_widget/models/BoardThemeConfig.dart';
```

## Example

```dart
ChessBoardWidget(
  game: ChessBoardInterface(
    // optional
    fen: 'fen state'
  ),
  
  // optional
  onPromotion: (Position pos) { // pawn position on rank 8
    // Handle promote pawn
  },

  // optional
  onCheckmate: (PieceColor turn) { // Player in checkmate (loosing)
    // Handle checkmate
  }
  
  boardTheme: BoardThemeConfig(
    boardColor: Colors.brown[300],
    materialVariety: 'modern_minimalist', // or check for materialResources.keys in env.dart
  ),
);
```

## Configuration

### Theme Customization

Customize the board and pieces using `BoardThemeConfig`. You can define your own colors and piece styles via the asset directory:

```dart
BoardThemeConfig(
  boardColor: Colors.green[700],
  materialVariety: 'wooden',
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

### Arbiter

Arbiter to handle events like game over, time out and pawn promotion:

## And more..

## File Structure

- `chess_board_widget.dart` – Main UI and logic
- `move_validator.dart` – Move legality checker
- `piece.dart` – Piece model and asset loader
- `arbiter.dart` – Game over, timOut, and promotion handler
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
Contributions are welcome! Please open issues and pull requests to help improve this [![Package]](https://www.github.com/mryadavdilip/chess_interface.git).

## License

MIT License. See [LICENSE](LICENSE) for details.
