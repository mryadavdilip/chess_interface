import 'dart:async';
import 'package:chess_interface/chess_board_widget.dart';

import 'move_validator.dart';
import 'piece.dart';

class Position {
  final int row;
  final int col;

  Position({required this.row, required this.col});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

class ChessBoardInterface {
  List<List<ChessPiece?>> get _emptyBoard =>
      List.generate(8, (_) => List.filled(8, null));

  final String? fen;
  final Duration? timeLimit; // Optional time limit for the game

  /// Adjust the initial state FEN so that the first rank ([board].[0]) corresponds
  /// to the first row in the FEN and the last rank ([board].[7]) corresponds to the last row.
  /// For example, if you want white pieces at the bottom ([board].[0]), then your FEN might look like:
  /// 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w'
  String initialFENState =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  List<List<ChessPiece?>> board = []; // Being initialized in initFEN

  PieceColor turn = PieceColor.white;

  /// Useful for generating PGN and other custom formats. Stores previous FEN states for operations like undo and more
  List<String> history = [];

  /// Stores undone moves for redo
  List<String> redoHistory = [];

  /// En passant target [Position] (if any)
  Position? enPassantTarget;

  /// Halfmove clock for draw conditions
  int halfMoveClock = 0;

  /// Fullmove number for draw conditions
  int fullMoveNumber = 1;

  /// Flag for draw by consent
  bool isDraw = false;

  /// Register resignation. (Player who resigned)
  PieceColor? resign;

  final Stopwatch _stopwatchWhite = Stopwatch(); // not for use
  final Stopwatch _stopwatchBlack = Stopwatch(); // not for use

  int get _whiteRemainingTime =>
      (timeLimit?.inMilliseconds ?? 0) - _stopwatchWhite.elapsedMilliseconds;
  int get _blackRemainingTime =>
      (timeLimit?.inMilliseconds ?? 0) - _stopwatchBlack.elapsedMilliseconds;

  Timer? _timer; // not for use
  final _whiteTimeController = StreamController<int>.broadcast();
  final _blackTimeController = StreamController<int>.broadcast();

  /// countdown timers to listen times for both the players
  Stream<int> get whiteTimeStream => _whiteTimeController.stream;
  Stream<int> get blackTimeStream => _blackTimeController.stream;

  ChessBoardInterface({this.fen, this.timeLimit}) {
    initFEN(fen ?? initialFENState);
    if (timeLimit != null) switchTimer();
  }

  void setDraw(bool draw) {
    isDraw = draw;
  }

  void setResign(PieceColor color) {
    resign = color;
  }

  /// Moves a piece on the board without validation.
  bool movePiece(Position from, Position to) {
    ChessPiece? piece = getPiece(from);
    if (piece == null) return false;

    // Move the piece to the new position
    board[to.row][to.col] = piece;
    board[from.row][from.col] = null;

    return true;
  }

  static String getPieceChar(ChessPiece piece) {
    Map<PieceType, String> whitePieces = {
      PieceType.pawn: "P",
      PieceType.knight: "N",
      PieceType.bishop: "B",
      PieceType.rook: "R",
      PieceType.queen: "Q",
      PieceType.king: "K",
    };
    Map<PieceType, String> blackPieces = {
      PieceType.pawn: "p",
      PieceType.knight: "n",
      PieceType.bishop: "b",
      PieceType.rook: "r",
      PieceType.queen: "q",
      PieceType.king: "k",
    };
    return (piece.color == PieceColor.white
        ? whitePieces[piece.type]
        : blackPieces[piece.type])!;
  }

  static ChessPiece getPieceFromChar(String char) {
    Map<String, ChessPiece> pieceMap = {
      "P": ChessPiece(type: PieceType.pawn, color: PieceColor.white),
      "N": ChessPiece(type: PieceType.knight, color: PieceColor.white),
      "B": ChessPiece(type: PieceType.bishop, color: PieceColor.white),
      "R": ChessPiece(type: PieceType.rook, color: PieceColor.white),
      "Q": ChessPiece(type: PieceType.queen, color: PieceColor.white),
      "K": ChessPiece(type: PieceType.king, color: PieceColor.white),
      "p": ChessPiece(type: PieceType.pawn, color: PieceColor.black),
      "n": ChessPiece(type: PieceType.knight, color: PieceColor.black),
      "b": ChessPiece(type: PieceType.bishop, color: PieceColor.black),
      "r": ChessPiece(type: PieceType.rook, color: PieceColor.black),
      "q": ChessPiece(type: PieceType.queen, color: PieceColor.black),
      "k": ChessPiece(type: PieceType.king, color: PieceColor.black),
    };
    return pieceMap[char]!;
  }
}

extension ChessBoardInterfaceExtension on ChessBoardInterface {
  String getCastlingRights() {
    String rights = "";

    // White castling rights:
    if (!MoveValidator.hasLostCastlingRights(this, PieceColor.white, true)) {
      rights += "K"; // White king-side available
    }
    if (!MoveValidator.hasLostCastlingRights(this, PieceColor.white, false)) {
      rights += "Q"; // White queen-side available
    }

    // Black castling rights:
    if (!MoveValidator.hasLostCastlingRights(this, PieceColor.black, true)) {
      rights += "k"; // Black king-side available
    }
    if (!MoveValidator.hasLostCastlingRights(this, PieceColor.black, false)) {
      rights += "q"; // Black queen-side available
    }

    return rights.isEmpty ? "-" : rights;
  }

  // int countPieces(String row) {
  //   return row.replaceAll(RegExp(r'[^KQRBNPkpqrbnp]'), '').length;
  // }

  /// Checks if a piece is eligible for promotion.
  bool isEligibleForPromotion(Position position) {
    ChessPiece? piece = getPiece(position);
    if (piece?.type == PieceType.pawn) {
      if (position.row == 0 || position.row == 7) {
        return true;
      }
    }
    return false;
  }

  /// Checks if the king is in check.
  bool isKingInCheck() {
    int kingRow = -1, kingCol = -1;

    // Locate the king.
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = getPiece(Position(row: row, col: col));
        if (piece != null &&
            piece.type == PieceType.king &&
            piece.color == turn) {
          kingRow = row;
          kingCol = col;
          break;
        }
      }
    }

    // Check if any opponent's piece can attack the king.
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = getPiece(Position(row: row, col: col));
        if (piece != null && piece.color != turn) {
          if (MoveValidator.isValidMove(
            this,
            Position(row: row, col: col),
            Position(row: kingRow, col: kingCol),
          )) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Checks if the game is in a checkmate state. [turn] is the player loses the game
  bool isCheckmate() {
    if (!isKingInCheck()) return false;

    // Try all possible moves for the king's color to see if any escape check.
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = getPiece(Position(row: row, col: col));
        if (piece != null && piece.color == turn) {
          for (int newRow = 0; newRow < 8; newRow++) {
            for (int newCol = 0; newCol < 8; newCol++) {
              if (MoveValidator.isValidMove(
                this,
                Position(row: row, col: col),
                Position(row: newRow, col: newCol),
              )) {
                ChessPiece? capturedPiece = getPiece(
                  Position(row: newRow, col: newCol),
                );
                movePiece(
                  Position(row: row, col: col),
                  Position(row: newRow, col: newCol),
                );
                bool stillInCheck = isKingInCheck();
                movePiece(
                  Position(row: newRow, col: newCol),
                  Position(row: row, col: col),
                );
                board[newRow][newCol] = capturedPiece; // Restore piece
                if (!stillInCheck) return false;
              }
            }
          }
        }
      }
    }
    return true;
  }

  /// Checks if the game is in a stalemate state.
  bool isStalemate() {
    for (int fromRow = 0; fromRow < 8; fromRow++) {
      for (int fromCol = 0; fromCol < 8; fromCol++) {
        ChessPiece? piece = getPiece(Position(row: fromRow, col: fromCol));
        if (piece == null || piece.color != turn) continue;
        for (int toRow = 0; toRow < 8; toRow++) {
          for (int toCol = 0; toCol < 8; toCol++) {
            if (MoveValidator.isValidMove(
              this,
              Position(row: fromRow, col: fromCol),
              Position(row: toRow, col: toCol),
            )) {
              return false;
            }
          }
        }
      }
    }
    return !isKingInCheck();
  }

  /// Checks if the game is in a draw state due to insufficient material.
  bool isInsufficientMaterial() {
    List<ChessPiece> remainingPieces = [];

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = getPiece(Position(row: row, col: col));
        if (piece != null) {
          remainingPieces.add(piece);
        }
      }
    }

    // Only kings left
    if (remainingPieces.length == 2) {
      return remainingPieces.every((p) => p.type == PieceType.king);
    }

    // King and bishop or knight vs king
    if (remainingPieces.length == 3) {
      bool hasOneMinor =
          remainingPieces
              .where(
                (p) => p.type == PieceType.bishop || p.type == PieceType.knight,
              )
              .length ==
          1;
      return hasOneMinor;
    }

    // King and bishop vs king and bishop (same color bishops)
    if (remainingPieces.length == 4) {
      List<ChessPiece> bishops =
          remainingPieces.where((p) => p.type == PieceType.bishop).toList();

      if (bishops.length == 2) {
        // Get their positions to compare bishop square colors
        List<Position> positions = [];

        for (int row = 0; row < 8; row++) {
          for (int col = 0; col < 8; col++) {
            ChessPiece? piece = getPiece(Position(row: row, col: col));
            if (piece != null && piece.type == PieceType.bishop) {
              positions.add(Position(row: row, col: col));
            }
          }
        }

        if (positions.length == 2) {
          bool sameColorSquares =
              (positions[0].row + positions[0].col) % 2 ==
              (positions[1].row + positions[1].col) % 2;
          return sameColorSquares;
        }
      }
    }

    return false;
  }

  /// Checks if the game is in a draw state due to threefold repetition.
  bool isThreefoldRepetition() {
    String stripIrrelevantFENParts(String fen) {
      // FEN format: piece_positions active_color castling_avail en_passant halfmove fullmove
      List<String> parts = fen.split(' ');
      if (parts.length < 4) return fen;

      // Keep only parts 0 to 3: board, turn, castling rights, en passant
      return '${parts[0]} ${parts[1]} ${parts[2]} ${parts[3]}';
    }

    Map<String, int> repetitionCount = {};

    for (String fen in history) {
      // Remove move clocks and turn data to avoid false negatives
      String key = stripIrrelevantFENParts(fen);

      repetitionCount[key] = (repetitionCount[key] ?? 0) + 1;

      if (repetitionCount[key]! >= 3) {
        return true;
      }
    }

    return false;
  }

  /// Checks if the game is in a draw state due to the fifty-move rule.
  bool isFiftyMoveDraw() {
    // Check if the half-move clock has reached 50
    return halfMoveClock >= 100;
  }

  /// Checks if the game is in time out. [turn] is the player loses the game
  bool isTimeOut() {
    return _blackRemainingTime <= 0 || _whiteRemainingTime <= 0;
  }

  /// Returns a list of valid moves for the selected piece, to render in the [ChessBoardWidget].
  List<Position> getValidMoves(Position from) {
    ChessPiece? piece = getPiece(from);
    if (piece == null || piece.color != turn) return [];

    List<Position> validMoves = [];

    // Existing valid move logic: iterate over board squares and check if a move is valid.
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        Position target = Position(row: row, col: col);
        if (MoveValidator.isValidMove(this, from, target)) {
          // (Optional: simulate the move to ensure the king does not end up in check.)
          validMoves.add(target);
        }
      }
    }

    // If the selected piece is the king, add castling moves.
    if (piece.type == PieceType.king) {
      // King‑side castling: king should move to column 6.
      if (MoveValidator.canCastleKingSide(this, piece.color)) {
        validMoves.add(Position(row: from.row, col: 6));
      }
      // Queen‑side castling: king should move to column 2.
      if (MoveValidator.canCastleQueenSide(this, piece.color)) {
        validMoves.add(Position(row: from.row, col: 2));
      }
    }

    return validMoves;
  }

  /// Promotes [PieceType.pawn] to the specified [type].
  void promotePawn(Position position, PieceType type) {
    ChessPiece? piece = getPiece(position);
    // Ensure the piece is a pawn on the final rank.
    if (piece == null || piece.type != PieceType.pawn) return;
    if ((piece.color == PieceColor.white && position.row != 0) ||
        (piece.color == PieceColor.black && position.row != 7)) {
      return;
    }

    // Promote the pawn.
    board[position.row][position.col] = ChessPiece(
      type: type,
      color: piece.color,
    );
  }

  /// Check if user can undo the last move.
  bool canUndo() => history.isNotEmpty;

  /// Check if user can redo the last undone move.
  bool canRedo() => redoHistory.isNotEmpty;

  /// Undo the last move and restore the previous state.
  void undo() {
    if (history.isNotEmpty) {
      String currentFEN = toFEN();
      // If the last state in history is identical to the current state,
      // remove it so that we actually restore a different state.
      if (history.last == currentFEN) {
        history.removeLast();
        return;
      }
      redoHistory.add(currentFEN);
      initFEN(history.removeLast());
    }
  }

  /// Redo the last undone move and restore the forth state.
  void redo() {
    if (redoHistory.isNotEmpty) {
      String currentFEN = toFEN();
      if (redoHistory.last == currentFEN) {
        redoHistory.removeLast();
        return;
      }
      history.add(currentFEN);
      initFEN(redoHistory.removeLast());
    }
  }

  /// Switch [turn] to the opposite [ChessPiece.color] / player.
  void switchTurn() {
    turn = (turn == PieceColor.white) ? PieceColor.black : PieceColor.white;
    switchTimer();
  }

  /// Get the piece at the specified position.
  ChessPiece? getPiece(Position position) {
    return board[position.row][position.col];
  }

  /// Move a piece from one position to another, with complete validations.
  bool move(Position from, Position to) {
    ChessPiece? piece = getPiece(from);
    if (piece == null || piece.color != turn) {
      return false; // No piece or wrong turn.
    }

    // Check for castling move: king moving two squares horizontally.
    bool isCastlingMove =
        piece.type == PieceType.king &&
        (to.col - from.col).abs() == 2 &&
        from.row == to.row;

    // For normal moves, use the validator.
    if (!isCastlingMove && !MoveValidator.isValidMove(this, from, to)) {
      return false; // Illegal move.
    }

    // Save current state for undo.
    history.add(toFEN());

    // Handle castling separately.
    if (isCastlingMove) {
      // Determine kingside or queenside castling.
      if (to.col > from.col) {
        // Kingside castling.
        if (!MoveValidator.canCastleKingSide(this, piece.color)) {
          return false;
        }
        // Move the king.
        movePiece(from, to);
        // Move the rook: from the corner to the square adjacent to the king.
        Position rookFrom = Position(row: from.row, col: 7);
        Position rookTo = Position(row: from.row, col: 5);
        movePiece(rookFrom, rookTo);
      } else {
        // Queenside castling.
        if (!MoveValidator.canCastleQueenSide(this, piece.color)) {
          return false;
        }
        // Move the king.
        movePiece(from, to);
        // Move the rook: from the corner to the square adjacent to the king.
        Position rookFrom = Position(row: from.row, col: 0);
        Position rookTo = Position(row: from.row, col: 3);
        movePiece(rookFrom, rookTo);
      }
    } else {
      // Normal move: handle en passant, captures, etc.
      // Handle En Passant capture (if applicable).
      if (piece.type == PieceType.pawn &&
          enPassantTarget != null &&
          to == enPassantTarget) {
        int captureRow =
            piece.color == PieceColor.white ? to.row + 1 : to.row - 1;
        board[captureRow][to.col] = null;
      }

      // Set en passant target if pawn moves two squares.
      enPassantTarget =
          (piece.type == PieceType.pawn && (from.row - to.row).abs() == 2)
              ? Position(row: (from.row + to.row) ~/ 2, col: from.col)
              : null;

      // Capture any piece on the destination and move the piece.
      ChessPiece? capturedPiece = getPiece(to);
      movePiece(from, to);

      // Validate that the move doesn't leave the king in check.
      if (isKingInCheck()) {
        // Undo the move if it puts the king in check.
        movePiece(to, from);
        board[to.row][to.col] = capturedPiece;
        return false;
      }
    }

    // Update half-move clock and full-move number (using your existing logic)...
    // For example:
    // if (move resets half-move clock) halfMoveClock = 0; else halfMoveClock++;
    // if (turn == PieceColor.black) fullMoveNumber++;

    // Switch turn after a successful move.
    switchTurn();

    // Clear redo history.
    redoHistory.clear();

    return true;
  }
}

extension LastMoveGetter on ChessBoardInterface {
  /// Returns the [Position] from which a [ChessPiece] was moved,
  /// deduced by comparing the second last and last FEN strings.
  Position? get lastMoveFrom {
    if (history.length < 2) return null;
    String previousFen = history[history.length - 2];
    String currentFen = history.last;
    List<List<ChessPiece?>> prevBoard = _decodeBoard(previousFen);
    List<List<ChessPiece?>> currBoard = _decodeBoard(currentFen);
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        // If a square had a piece and now is empty,
        // we assume that's where the piece moved from.
        if (prevBoard[row][col] != null && currBoard[row][col] == null) {
          return Position(row: row, col: col);
        }
      }
    }
    return null;
  }

  /// Returns the "to [Position] square" where a [ChessPiece] was moved,
  /// deduced by comparing the second last and last FEN strings.
  Position? get lastMoveTo {
    if (history.length < 2) return null;
    String previousFen = history[history.length - 2];
    String currentFen = history.last;
    List<List<ChessPiece?>> prevBoard = _decodeBoard(previousFen);
    List<List<ChessPiece?>> currBoard = _decodeBoard(currentFen);
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        // If a square was empty and now holds a piece,
        // that square is the destination.
        if (prevBoard[row][col] == null && currBoard[row][col] != null) {
          return Position(row: row, col: col);
        }
      }
    }
    return null;
  }

  // Helper method to decode the board portion of a FEN string into a 2D list.
  List<List<ChessPiece?>> _decodeBoard(String fen) {
    List<List<ChessPiece?>> board = List.generate(
      8,
      (_) => List.filled(8, null),
    );
    List<String> parts = fen.split(" ");
    List<String> rows = parts[0].split("/");
    for (int row = 0; row < 8; row++) {
      int col = 0;
      for (int i = 0; i < rows[row].length; i++) {
        String charAt = rows[row][i];
        if (RegExp(r'[1-8]').hasMatch(charAt)) {
          col += int.parse(charAt);
        } else {
          board[row][col] = ChessBoardInterface.getPieceFromChar(charAt);
          col++;
        }
      }
    }
    return board;
  }
}

extension BoardUtils on ChessBoardInterface {
  /// initializes the board with the given FEN string.
  void initFEN(String fen) {
    board = _emptyBoard;

    List<String> parts = fen.split(" ");
    List<String> rows = parts[0].split("/");

    // Determine turn from FEN.
    turn = (parts[1] == "w") ? PieceColor.white : PieceColor.black;

    // En-passant target square (if any).
    if (parts[3] != "-") {
      String targetSquare = parts[3];
      int col = targetSquare.codeUnitAt(0) - 'a'.codeUnitAt(0);
      int row = 8 - int.parse(targetSquare[1]);
      enPassantTarget = Position(row: row, col: col);
    } else {
      enPassantTarget = null;
    }

    halfMoveClock = int.tryParse(parts[4]) ?? 0; // Halfmove clock from FEN
    fullMoveNumber = int.tryParse(parts[5]) ?? 1; // Fullmove number from FEN

    // Here we assume the FEN rows correspond directly to board rows (0 to 7).
    for (int row = 0; row < 8; row++) {
      int col = 0;
      String fenRow = rows[row]; // no reversal
      for (int i = 0; i < fenRow.length; i++) {
        String charAt = fenRow[i];
        if (RegExp(r'[1-8]').hasMatch(charAt)) {
          col += int.parse(charAt);
        } else {
          board[row][col] = ChessBoardInterface.getPieceFromChar(charAt);
          col++;
        }
      }
    }
  }

  String toFEN() {
    StringBuffer fenBuffer = StringBuffer();
    // Piece placement
    for (int row = 0; row < 8; row++) {
      int emptyCount = 0;
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = board[row][col];
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            fenBuffer.write(emptyCount);
            emptyCount = 0;
          }
          fenBuffer.write(ChessBoardInterface.getPieceChar(piece));
        }
      }
      if (emptyCount > 0) fenBuffer.write(emptyCount);
      if (row < 7) fenBuffer.write("/");
    }

    // Active color (turn)
    fenBuffer.write(" ");
    fenBuffer.write(turn == PieceColor.white ? "w" : "b");

    // Castling availability
    fenBuffer.write(" ");
    fenBuffer.write(getCastlingRights());

    // En passant target square (using "-" as default, modify if you have one)
    fenBuffer.write(" ");
    fenBuffer.write(
      enPassantTarget != null
          ? "${String.fromCharCode('a'.codeUnitAt(0) + enPassantTarget!.col)}${8 - enPassantTarget!.row}"
          : "-",
    );

    // Halfmove clock and fullmove number (defaults here)
    fenBuffer.write(" ");
    fenBuffer.write(halfMoveClock);
    fenBuffer.write(" ");
    fenBuffer.write(fullMoveNumber);

    return fenBuffer.toString();
  }

  void switchTimer({bool stop = false}) {
    _timer?.cancel();
    if (stop) {
      _stopwatchWhite.stop();
      _stopwatchBlack.stop();
      _timer?.cancel();
    } else if (turn == PieceColor.white) {
      _stopwatchWhite.start();
      _stopwatchBlack.stop();

      /// adjust duration according to your clock speed
      _timer = Timer.periodic(Duration(milliseconds: 100), (_) {
        _whiteTimeController.add(_whiteRemainingTime);
      });
    } else if (turn == PieceColor.black) {
      _stopwatchBlack.start();
      _stopwatchWhite.stop();

      /// adjust duration according to your clock speed
      _timer = Timer.periodic(Duration(milliseconds: 100), (_) {
        _blackTimeController.add(_blackRemainingTime);
      });
    }
  }

  /// Resets the board to its [initialFENState].
  void reset() {
    board = _emptyBoard;
    initFEN(initialFENState);
    isDraw = false;
    resign = null;
    _stopwatchWhite.reset();
    _stopwatchBlack.reset();
    _timer?.cancel();
    history.clear();
    redoHistory.clear();
  }

  /// Returns a deep copy of the current [ChessBoardInterface] instance.
  ChessBoardInterface deepCopy() {
    ChessBoardInterface newBoard = ChessBoardInterface(fen: fen);
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        newBoard.board[row][col] = board[row][col];
      }
    }
    newBoard.turn = turn;
    newBoard.enPassantTarget = enPassantTarget;
    newBoard.history = List.from(history);
    newBoard.redoHistory = List.from(redoHistory);
    return newBoard;
  }
}
