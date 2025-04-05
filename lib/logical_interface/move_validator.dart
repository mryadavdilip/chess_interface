import 'interface.dart';
import 'piece.dart';

class MoveValidator {
  static bool isValidMove(
    ChessBoardInterface board,
    Position from,
    Position to,
  ) {
    ChessPiece? piece = board.getPiece(from);
    if (piece == null) return false; // No piece to move

    ChessPiece? targetPiece = board.getPiece(to);
    if (targetPiece != null && targetPiece.color == piece.color) {
      return false; // Cannot capture own piece
    }

    switch (piece.type) {
      case PieceType.pawn:
        return _validatePawnMove(piece, from, to, board);
      case PieceType.knight:
        return _validateKnightMove(from, to);
      case PieceType.bishop:
        return _validateBishopMove(from, to, board);
      case PieceType.rook:
        return _validateRookMove(from, to, board);
      case PieceType.queen:
        return _validateQueenMove(from, to, board);
      case PieceType.king:
        return _validateKingMove(from, to);
    }
  }

  static bool _validatePawnMove(
    ChessPiece piece,
    Position from,
    Position to,
    ChessBoardInterface board,
  ) {
    // Adjust movement based on board indexing:
    // White pawns start at row 6 and move upward (decrease row)
    // Black pawns start at row 1 and move downward (increase row)
    int direction = (piece.color == PieceColor.white) ? -1 : 1;
    int startRow = (piece.color == PieceColor.white) ? 6 : 1;

    // Normal move forward
    if (from.col == to.col && board.getPiece(to) == null) {
      // Single move forward
      if (to.row == from.row + direction) return true;
      // Double move forward from starting row (ensure the intermediate square is empty)
      if (from.row == startRow &&
          to.row == from.row + (2 * direction) &&
          board.getPiece(Position(row: from.row + direction, col: from.col)) ==
              null) {
        return true;
      }
    }

    // Diagonal capture (including en passant)
    if ((to.col - from.col).abs() == 1 && to.row == from.row + direction) {
      // Standard capture if enemy piece is present.
      if (board.getPiece(to) != null) return true;
      // En passant capture: allow move if the target square is the en passant target.
      if (board.enPassantTarget != null && board.enPassantTarget == to) {
        return true;
      }
    }

    return false;
  }

  static bool _validateKnightMove(Position from, Position to) {
    int rowDiff = (to.row - from.row).abs();
    int colDiff = (to.col - from.col).abs();
    return (rowDiff == 2 && colDiff == 1) || (rowDiff == 1 && colDiff == 2);
  }

  static bool _validateBishopMove(
    Position from,
    Position to,
    ChessBoardInterface board,
  ) {
    if ((to.row - from.row).abs() != (to.col - from.col).abs()) return false;

    int rowStep = (to.row > from.row) ? 1 : -1;
    int colStep = (to.col > from.col) ? 1 : -1;
    int steps = (to.row - from.row).abs();

    for (int i = 1; i < steps; i++) {
      if (board.getPiece(
            Position(row: from.row + i * rowStep, col: from.col + i * colStep),
          ) !=
          null) {
        return false;
      }
    }

    return true;
  }

  static bool _validateRookMove(
    Position from,
    Position to,
    ChessBoardInterface board,
  ) {
    if (from.row != to.row && from.col != to.col) return false;

    int rowStep =
        (to.row > from.row)
            ? 1
            : (to.row < from.row)
            ? -1
            : 0;
    int colStep =
        (to.col > from.col)
            ? 1
            : (to.col < from.col)
            ? -1
            : 0;
    int steps =
        (from.row != to.row)
            ? (to.row - from.row).abs()
            : (to.col - from.col).abs();

    for (int i = 1; i < steps; i++) {
      if (board.getPiece(
            Position(row: from.row + i * rowStep, col: from.col + i * colStep),
          ) !=
          null) {
        return false;
      }
    }

    return true;
  }

  static bool _validateQueenMove(
    Position from,
    Position to,
    ChessBoardInterface board,
  ) {
    return _validateBishopMove(from, to, board) ||
        _validateRookMove(from, to, board);
  }

  static bool _validateKingMove(Position from, Position to) {
    return (to.row - from.row).abs() <= 1 && (to.col - from.col).abs() <= 1;
  }

  static bool canCastleKingSide(ChessBoardInterface board, PieceColor color) {
    if (hasLostCastlingRights(board, color, true)) {
      return false; // Castling lost
    }

    int row = (color == PieceColor.white) ? 7 : 0;
    if (board.getPiece(Position(row: row, col: 5)) != null ||
        board.getPiece(Position(row: row, col: 6)) != null) {
      return false;
    }

    if (board.isKingInCheck()) return false;

    ChessBoardInterface tempBoard = board.deepCopy();
    tempBoard.movePiece(Position(row: row, col: 4), Position(row: row, col: 5));
    if (tempBoard.isKingInCheck()) return false;

    tempBoard = board.deepCopy();
    tempBoard.movePiece(Position(row: row, col: 4), Position(row: row, col: 6));
    if (tempBoard.isKingInCheck()) return false;

    return true;
  }

  static bool canCastleQueenSide(ChessBoardInterface board, PieceColor color) {
    if (hasLostCastlingRights(board, color, false)) {
      return false; // Castling lost
    }

    int row = (color == PieceColor.white) ? 7 : 0;
    if (board.getPiece(Position(row: row, col: 1)) != null ||
        board.getPiece(Position(row: row, col: 2)) != null ||
        board.getPiece(Position(row: row, col: 3)) != null) {
      return false;
    }

    if (board.isKingInCheck()) return false;

    ChessBoardInterface tempBoard = board.deepCopy();
    tempBoard.movePiece(Position(row: row, col: 4), Position(row: row, col: 3));
    if (tempBoard.isKingInCheck()) return false;

    tempBoard = board.deepCopy();
    tempBoard.movePiece(Position(row: row, col: 4), Position(row: row, col: 2));
    if (tempBoard.isKingInCheck()) return false;

    return true;
  }

  static bool hasLostCastlingRights(
    ChessBoardInterface board,
    PieceColor color,
    bool kingSide,
  ) {
    for (String fen in board.history) {
      List<String> parts = fen.split(" ");
      if (parts.length < 2) continue; // Invalid FEN format

      String castlingRights = parts[2]; // Extract castling field

      if (color == PieceColor.white) {
        if (kingSide && !castlingRights.contains("K")) return true;
        if (!kingSide && !castlingRights.contains("Q")) return true;
      } else {
        if (kingSide && !castlingRights.contains("k")) return true;
        if (!kingSide && !castlingRights.contains("q")) return true;
      }
    }
    return false;
  }
}
