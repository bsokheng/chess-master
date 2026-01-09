import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../models/game_state.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import '../services/chess_ai_service.dart';
import 'settings_provider.dart';

/// Main game state provider managing all chess game logic
class GameProvider extends ChangeNotifier {
  final StorageService _storageService;
  final SoundService _soundService;
  final SettingsProvider _settingsProvider;
  final ChessAIService _aiService = ChessAIService();

  // Core game state
  late chess_lib.Chess _chess;
  List<ChessMove> _moveHistory = [];
  PlayerColor _playerColor = PlayerColor.white;
  AIDifficulty _difficulty = AIDifficulty.medium;
  GameResult _gameResult = GameResult.ongoing;
  DateTime _startTime = DateTime.now();

  // UI state
  String? _selectedSquare;
  List<String> _legalMoves = [];
  String? _lastMoveFrom;
  String? _lastMoveTo;
  bool _isAIThinking = false;
  bool _isBoardFlipped = false;
  String? _pendingPromotion;
  String? _promotionFrom;
  String? _promotionTo;

  // Timer state
  int _whiteTimeSeconds = 600;
  int _blackTimeSeconds = 600;
  Timer? _timer;
  bool _timerRunning = false;

  // Captured pieces
  List<String> _whiteCaptured = [];
  List<String> _blackCaptured = [];

  // Hint
  Map<String, dynamic>? _hintMoveInfo;

  GameProvider({
    required StorageService storageService,
    required SoundService soundService,
    required SettingsProvider settingsProvider,
  })  : _storageService = storageService,
        _soundService = soundService,
        _settingsProvider = settingsProvider {
    _chess = chess_lib.Chess();
    _loadSavedGame();
  }

  // Getters
  chess_lib.Chess get chess => _chess;
  List<ChessMove> get moveHistory => List.unmodifiable(_moveHistory);
  PlayerColor get playerColor => _playerColor;
  AIDifficulty get difficulty => _difficulty;
  GameResult get gameResult => _gameResult;
  String? get selectedSquare => _selectedSquare;
  List<String> get legalMoves => _legalMoves;
  String? get lastMoveFrom => _lastMoveFrom;
  String? get lastMoveTo => _lastMoveTo;
  bool get isAIThinking => _isAIThinking;
  bool get isBoardFlipped => _isBoardFlipped;
  bool get isPlayerTurn => _isPlayerTurnNow();
  bool get isGameOver => _gameResult != GameResult.ongoing;
  bool get isInCheck => _chess.in_check;
  int get whiteTimeSeconds => _whiteTimeSeconds;
  int get blackTimeSeconds => _blackTimeSeconds;
  List<String> get whiteCaptured => List.unmodifiable(_whiteCaptured);
  List<String> get blackCaptured => List.unmodifiable(_blackCaptured);
  String? get hintFrom => _hintMoveInfo?['from'] as String?;
  String? get hintTo => _hintMoveInfo?['to'] as String?;
  bool get hasPendingPromotion => _pendingPromotion != null;
  String get currentFen => _chess.fen;
  bool get canUndo => _moveHistory.isNotEmpty && _gameResult == GameResult.ongoing;

  bool _isPlayerTurnNow() {
    final isWhiteTurn = _chess.turn == chess_lib.Color.WHITE;
    return (_playerColor == PlayerColor.white && isWhiteTurn) ||
        (_playerColor == PlayerColor.black && !isWhiteTurn);
  }

  /// Load any saved game state
  Future<void> _loadSavedGame() async {
    final savedState = await _storageService.loadGameState();
    if (savedState != null && savedState.result == GameResult.ongoing) {
      _chess = chess_lib.Chess.fromFEN(savedState.fen);
      _moveHistory = savedState.moveHistory;
      _playerColor = savedState.playerColor;
      _difficulty = savedState.difficulty;
      _gameResult = savedState.result;
      _startTime = savedState.startTime;
      _whiteTimeSeconds = savedState.whiteTimeSeconds;
      _blackTimeSeconds = savedState.blackTimeSeconds;
      _recalculateCapturedPieces();
      notifyListeners();

      // If it's AI's turn, make AI move
      if (!_isPlayerTurnNow() && _gameResult == GameResult.ongoing) {
        _makeAIMove();
      }
    }
  }

  /// Start a new game
  Future<void> newGame({
    PlayerColor? playerColor,
    AIDifficulty? difficulty,
  }) async {
    _timer?.cancel();
    _timerRunning = false;

    _playerColor = playerColor ?? _settingsProvider.playerColor;
    _difficulty = difficulty ?? _settingsProvider.difficulty;

    _chess = chess_lib.Chess();
    _moveHistory.clear();
    _gameResult = GameResult.ongoing;
    _startTime = DateTime.now();
    _selectedSquare = null;
    _legalMoves.clear();
    _lastMoveFrom = null;
    _lastMoveTo = null;
    _isAIThinking = false;
    _hintMoveInfo = null;
    _whiteCaptured.clear();
    _blackCaptured.clear();
    _pendingPromotion = null;

    // Reset timer
    final minutes = _settingsProvider.timerMinutes;
    _whiteTimeSeconds = minutes * 60;
    _blackTimeSeconds = minutes * 60;

    await _storageService.clearGameState();
    _soundService.play(SoundType.gameStart);

    notifyListeners();

    // Flip board if player is black
    if (_playerColor == PlayerColor.black) {
      _isBoardFlipped = true;
    } else {
      _isBoardFlipped = false;
    }

    // Start timer if enabled
    if (_settingsProvider.timerEnabled) {
      _startTimer();
    }

    // If player is black, AI moves first
    if (_playerColor == PlayerColor.black) {
      await _makeAIMove();
    }
  }

  /// Handle square tap
  void onSquareTap(String square) {
    if (_gameResult != GameResult.ongoing) return;
    if (_pendingPromotion != null) return;

    // Safety: if it's player's turn but AI thinking is stuck, reset it
    if (_isPlayerTurnNow() && _isAIThinking) {
      _isAIThinking = false;
    }

    if (_isAIThinking) return;
    if (!_isPlayerTurnNow()) return;

    final piece = _chess.get(square);

    // If a piece is already selected
    if (_selectedSquare != null) {
      // If tapping the same square, deselect
      if (_selectedSquare == square) {
        _clearSelection();
        return;
      }

      // If tapping another own piece, select it instead
      if (piece != null && _isOwnPiece(piece)) {
        _selectSquare(square);
        return;
      }

      // Try to move to the tapped square
      if (_legalMoves.contains(square)) {
        _tryMove(_selectedSquare!, square);
      } else {
        _clearSelection();
        _playHaptic();
        _soundService.play(SoundType.illegal);
      }
    } else {
      // No piece selected - select if it's own piece
      if (piece != null && _isOwnPiece(piece)) {
        _selectSquare(square);
      }
    }
  }

  bool _isOwnPiece(chess_lib.Piece piece) {
    final isWhitePiece = piece.color == chess_lib.Color.WHITE;
    final playerIsWhite = _playerColor == PlayerColor.white;
    final isWhiteTurn = _chess.turn == chess_lib.Color.WHITE;

    // Must be player's piece AND player's turn
    final isPlayersPiece = isWhitePiece == playerIsWhite;
    final isPlayersTurn = isWhiteTurn == playerIsWhite;

    return isPlayersPiece && isPlayersTurn;
  }

  void _selectSquare(String square) {
    _selectedSquare = square;
    _legalMoves = _getLegalMovesFrom(square);
    _hintMoveInfo = null;
    _playHaptic();
    notifyListeners();
  }

  void _clearSelection() {
    _selectedSquare = null;
    _legalMoves.clear();
    notifyListeners();
  }

  List<String> _getLegalMovesFrom(String square) {
    final moves = _chess.moves({'square': square, 'verbose': true});
    return moves.map<String>((m) => m['to'] as String).toList();
  }

  /// Attempt to make a move
  void _tryMove(String from, String to) {
    final piece = _chess.get(from);
    if (piece == null) return;

    // Check for pawn promotion
    final isPromotion = _isPromotionMove(piece, from, to);

    if (isPromotion && !_settingsProvider.autoQueen) {
      // Show promotion dialog
      _pendingPromotion = 'pending';
      _promotionFrom = from;
      _promotionTo = to;
      notifyListeners();
      return;
    }

    // Make the move (auto-queen if promotion)
    final promotion = isPromotion ? 'q' : null;
    _executeMove(from, to, promotion);
  }

  bool _isPromotionMove(chess_lib.Piece piece, String from, String to) {
    if (piece.type != chess_lib.PieceType.PAWN) return false;

    final toRank = int.parse(to[1]);
    return (piece.color == chess_lib.Color.WHITE && toRank == 8) ||
        (piece.color == chess_lib.Color.BLACK && toRank == 1);
  }

  /// Complete promotion with chosen piece
  void completePromotion(String pieceType) {
    if (_promotionFrom == null || _promotionTo == null) return;

    _executeMove(_promotionFrom!, _promotionTo!, pieceType);
    _pendingPromotion = null;
    _promotionFrom = null;
    _promotionTo = null;
  }

  /// Cancel promotion
  void cancelPromotion() {
    _pendingPromotion = null;
    _promotionFrom = null;
    _promotionTo = null;
    _clearSelection();
  }

  /// Execute a move
  void _executeMove(String from, String to, String? promotion) {
    // Get move info before executing
    Map<String, dynamic>? moveInfo;
    final verboseMoves = _chess.moves({'verbose': true});
    for (final m in verboseMoves) {
      final move = m as Map;
      if (move['from'] == from && move['to'] == to) {
        if (promotion == null || move['promotion'] == promotion) {
          moveInfo = Map<String, dynamic>.from(move);
          break;
        }
      }
    }

    final moveColor = _chess.turn;

    // Try to make the move
    final moveSuccess = _chess.move({
      'from': from,
      'to': to,
      if (promotion != null) 'promotion': promotion,
    });

    if (moveSuccess == null || moveSuccess == false) {
      _soundService.play(SoundType.illegal);
      _clearSelection();
      return;
    }

    final san = moveInfo?['san'] as String? ?? '$from$to';
    // captured can be PieceType or String depending on chess library version
    final captured = _getCapturedPieceChar(moveInfo?['captured']);
    final flags = moveInfo?['flags'] as String? ?? '';

    // Record the move
    final chessMove = ChessMove(
      from: from,
      to: to,
      promotion: promotion,
      algebraicNotation: san,
      capturedPiece: captured,
      isCheck: _chess.in_check,
      isCheckmate: _chess.in_checkmate,
      isCastling: flags.contains('k') || flags.contains('q'),
      isEnPassant: flags.contains('e'),
    );
    _moveHistory.add(chessMove);

    // Update captured pieces
    if (captured != null) {
      final capturedPieceType = _getPieceTypeFromChar(captured);
      if (capturedPieceType != null) {
        final capturedPiece = _getPieceSymbol(capturedPieceType, moveColor == chess_lib.Color.WHITE ? chess_lib.Color.BLACK : chess_lib.Color.WHITE);
        if (moveColor == chess_lib.Color.WHITE) {
          _blackCaptured.add(capturedPiece);
        } else {
          _whiteCaptured.add(capturedPiece);
        }
      }
    }

    // Update UI state
    _lastMoveFrom = from;
    _lastMoveTo = to;
    _clearSelection();
    _hintMoveInfo = null;

    // Play appropriate sound
    _playMoveSoundFromInfo(san, captured, flags);
    _playHaptic();

    // Check for game end
    _checkGameEnd();

    // Save game state
    _saveGame();

    notifyListeners();

    // Make AI move if game is still ongoing
    if (_gameResult == GameResult.ongoing && !_isPlayerTurnNow()) {
      // Use delayed to ensure UI updates first
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_gameResult == GameResult.ongoing) {
          _makeAIMove();
        }
      });
    }
  }

  /// Convert captured piece info to single character (handles both PieceType and String)
  String? _getCapturedPieceChar(dynamic captured) {
    if (captured == null) return null;

    // If it's already a string like "p", "n", etc.
    if (captured is String) {
      return captured.isNotEmpty ? captured[0].toLowerCase() : null;
    }

    // If it's a PieceType enum
    if (captured is chess_lib.PieceType) {
      switch (captured) {
        case chess_lib.PieceType.PAWN: return 'p';
        case chess_lib.PieceType.KNIGHT: return 'n';
        case chess_lib.PieceType.BISHOP: return 'b';
        case chess_lib.PieceType.ROOK: return 'r';
        case chess_lib.PieceType.QUEEN: return 'q';
        case chess_lib.PieceType.KING: return 'k';
      }
    }

    // Fallback: try to extract from toString()
    final str = captured.toString().toLowerCase();
    if (str.contains('pawn')) return 'p';
    if (str.contains('knight')) return 'n';
    if (str.contains('bishop')) return 'b';
    if (str.contains('rook')) return 'r';
    if (str.contains('queen')) return 'q';
    if (str.contains('king')) return 'k';

    return null;
  }

  chess_lib.PieceType? _getPieceTypeFromChar(String char) {
    switch (char.toLowerCase()) {
      case 'p': return chess_lib.PieceType.PAWN;
      case 'n': return chess_lib.PieceType.KNIGHT;
      case 'b': return chess_lib.PieceType.BISHOP;
      case 'r': return chess_lib.PieceType.ROOK;
      case 'q': return chess_lib.PieceType.QUEEN;
      case 'k': return chess_lib.PieceType.KING;
      default: return null;
    }
  }

  void _playMoveSoundFromInfo(String san, String? captured, String flags) {
    if (_chess.in_checkmate) {
      _soundService.play(SoundType.checkmate);
    } else if (_chess.in_check) {
      _soundService.play(SoundType.check);
    } else if (flags.contains('k') || flags.contains('q')) {
      _soundService.play(SoundType.castle);
    } else if (captured != null) {
      _soundService.play(SoundType.capture);
    } else {
      _soundService.play(SoundType.move);
    }
  }

  void _playHaptic() {
    if (_settingsProvider.hapticEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Make AI move using the minimax algorithm
  Future<void> _makeAIMove() async {
    if (_gameResult != GameResult.ongoing) return;
    if (_isPlayerTurnNow()) return; // Safety check

    _isAIThinking = true;
    notifyListeners();

    try {
      // Small delay so UI shows "thinking"
      await Future.delayed(const Duration(milliseconds: 100));

      // Use the AI service to find the best move based on difficulty
      final bestMoveInfo = await _aiService.findBestMoveInfo(_chess, _difficulty);

      if (bestMoveInfo == null) {
        // No valid moves - game might be over
        return;
      }

      // Execute the AI's chosen move
      _executeAIMoveFromInfo(bestMoveInfo);
    } catch (e) {
      print('AI move error: $e');
      // Fallback to random move if AI fails
      final moves = _chess.moves();
      if (moves.isNotEmpty) {
        final randomIndex = DateTime.now().millisecondsSinceEpoch % moves.length;
        final selectedSan = moves[randomIndex] as String;
        _executeAIMoveSan(selectedSan);
      }
    } finally {
      // Always reset AI thinking state
      _isAIThinking = false;
      notifyListeners();
    }
  }

  void _executeAIMoveSan(String san) {
    // Get move details before executing
    final verboseMoves = _chess.moves({'verbose': true});
    Map<String, dynamic>? moveInfo;
    for (final m in verboseMoves) {
      if ((m as Map)['san'] == san) {
        moveInfo = Map<String, dynamic>.from(m);
        break;
      }
    }

    final moveColor = _chess.turn;
    final success = _chess.move(san);

    if (success == null || success == false) return;

    final from = moveInfo?['from'] as String? ?? '';
    final to = moveInfo?['to'] as String? ?? '';
    // captured can be PieceType or String depending on chess library version
    final captured = _getCapturedPieceChar(moveInfo?['captured']);

    // Record the move
    final chessMove = ChessMove(
      from: from,
      to: to,
      promotion: moveInfo?['promotion'] as String?,
      algebraicNotation: san,
      capturedPiece: captured,
      isCheck: _chess.in_check,
      isCheckmate: _chess.in_checkmate,
      isCastling: san.contains('O-O'),
      isEnPassant: false,
    );
    _moveHistory.add(chessMove);

    // Update captured pieces
    if (captured != null) {
      final pieceType = _getPieceTypeFromChar(captured);
      if (pieceType != null) {
        final capturedPiece = _getPieceSymbol(pieceType, moveColor == chess_lib.Color.WHITE ? chess_lib.Color.BLACK : chess_lib.Color.WHITE);
        if (moveColor == chess_lib.Color.WHITE) {
          _blackCaptured.add(capturedPiece);
        } else {
          _whiteCaptured.add(capturedPiece);
        }
      }
    }

    _lastMoveFrom = from;
    _lastMoveTo = to;

    _playMoveSoundFromInfo(san, captured, '');
    _checkGameEnd();
    _saveGame();
    notifyListeners();
  }

  void _executeAIMoveFromInfo(Map<String, dynamic> moveInfo) {
    final from = moveInfo['from'] as String;
    final to = moveInfo['to'] as String;
    final promotion = moveInfo['promotion'] as String?;
    final san = moveInfo['san'] as String? ?? '';
    // captured can be PieceType or String depending on chess library version
    final captured = _getCapturedPieceChar(moveInfo['captured']);
    final flags = moveInfo['flags'] as String? ?? '';

    final moveColor = _chess.turn;

    // Try using SAN notation first (more reliable)
    bool moveSuccess = false;
    if (san.isNotEmpty) {
      moveSuccess = _chess.move(san) != null;
    }

    // Fallback to from/to format
    if (!moveSuccess) {
      final result = _chess.move({
        'from': from,
        'to': to,
        if (promotion != null) 'promotion': promotion,
      });
      moveSuccess = result != null && result != false;
    }

    if (!moveSuccess) return;

    // Record the move
    final chessMove = ChessMove(
      from: from,
      to: to,
      promotion: promotion,
      algebraicNotation: san,
      capturedPiece: captured,
      isCheck: _chess.in_check,
      isCheckmate: _chess.in_checkmate,
      isCastling: flags.contains('k') || flags.contains('q'),
      isEnPassant: flags.contains('e'),
    );
    _moveHistory.add(chessMove);

    // Update captured pieces
    if (captured != null) {
      final capturedPieceType = _getPieceTypeFromChar(captured);
      if (capturedPieceType != null) {
        final capturedPiece = _getPieceSymbol(capturedPieceType, moveColor == chess_lib.Color.WHITE ? chess_lib.Color.BLACK : chess_lib.Color.WHITE);
        if (moveColor == chess_lib.Color.WHITE) {
          _blackCaptured.add(capturedPiece);
        } else {
          _whiteCaptured.add(capturedPiece);
        }
      }
    }

    _lastMoveFrom = from;
    _lastMoveTo = to;

    _playMoveSoundFromInfo(san, captured, flags);
    _checkGameEnd();
    _saveGame();
    notifyListeners();
  }

  String _getPieceSymbol(chess_lib.PieceType type, chess_lib.Color color) {
    final isWhite = color == chess_lib.Color.WHITE;
    switch (type) {
      case chess_lib.PieceType.PAWN:
        return isWhite ? '♙' : '♟';
      case chess_lib.PieceType.KNIGHT:
        return isWhite ? '♘' : '♞';
      case chess_lib.PieceType.BISHOP:
        return isWhite ? '♗' : '♝';
      case chess_lib.PieceType.ROOK:
        return isWhite ? '♖' : '♜';
      case chess_lib.PieceType.QUEEN:
        return isWhite ? '♕' : '♛';
      case chess_lib.PieceType.KING:
        return isWhite ? '♔' : '♚';
      default:
        return '';
    }
  }

  void _recalculateCapturedPieces() {
    _whiteCaptured.clear();
    _blackCaptured.clear();

    for (final move in _moveHistory) {
      if (move.capturedPiece != null) {
        // Determine which side captured based on move
        // This is a simplified approach
      }
    }
  }

  /// Check if game has ended
  void _checkGameEnd() {
    if (_chess.in_checkmate) {
      _gameResult = _chess.turn == chess_lib.Color.WHITE
          ? GameResult.blackWins
          : GameResult.whiteWins;
      _timer?.cancel();
      _soundService.play(SoundType.gameEnd);
    } else if (_chess.in_stalemate) {
      _gameResult = GameResult.stalemate;
      _timer?.cancel();
      _soundService.play(SoundType.gameEnd);
    } else if (_chess.in_draw) {
      _gameResult = GameResult.draw;
      _timer?.cancel();
      _soundService.play(SoundType.gameEnd);
    }
  }

  /// Undo the last move (player's last move)
  void undoMove() {
    if (_moveHistory.isEmpty) return;
    if (_gameResult != GameResult.ongoing) return;
    if (_isAIThinking) return;

    // Undo AI's move and player's move
    if (_moveHistory.length >= 2) {
      _chess.undo();
      _chess.undo();
      _moveHistory.removeLast();
      _moveHistory.removeLast();
    } else if (_moveHistory.length == 1 && _playerColor == PlayerColor.black) {
      _chess.undo();
      _moveHistory.removeLast();
    }

    _lastMoveFrom = _moveHistory.isNotEmpty ? _moveHistory.last.from : null;
    _lastMoveTo = _moveHistory.isNotEmpty ? _moveHistory.last.to : null;
    _clearSelection();
    _hintMoveInfo = null;
    _recalculateCapturedPieces();
    _saveGame();
    notifyListeners();
  }

  /// Flip the board view
  void flipBoard() {
    _isBoardFlipped = !_isBoardFlipped;
    notifyListeners();
  }

  /// Get a hint for the best move
  Future<void> getHint() async {
    if (_gameResult != GameResult.ongoing) return;
    if (!_isPlayerTurnNow()) return;
    if (_isAIThinking) return;

    _isAIThinking = true;
    notifyListeners();

    try {
      _hintMoveInfo = await _aiService.getHintInfo(_chess);
    } catch (e) {
      _hintMoveInfo = null;
    }

    _isAIThinking = false;
    notifyListeners();
  }

  /// Clear the hint
  void clearHint() {
    _hintMoveInfo = null;
    notifyListeners();
  }

  /// Get material balance (positive = white advantage)
  int getMaterialBalance() {
    return _aiService.getMaterialBalance(_chess);
  }

  /// Timer management
  void _startTimer() {
    _timer?.cancel();
    _timerRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameResult != GameResult.ongoing) {
        timer.cancel();
        return;
      }

      final isWhiteTurn = _chess.turn == chess_lib.Color.WHITE;

      if (isWhiteTurn) {
        _whiteTimeSeconds--;
        if (_whiteTimeSeconds <= 0) {
          _whiteTimeSeconds = 0;
          _gameResult = GameResult.blackWins;
          timer.cancel();
          _soundService.play(SoundType.gameEnd);
        }
      } else {
        _blackTimeSeconds--;
        if (_blackTimeSeconds <= 0) {
          _blackTimeSeconds = 0;
          _gameResult = GameResult.whiteWins;
          timer.cancel();
          _soundService.play(SoundType.gameEnd);
        }
      }

      notifyListeners();
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _timerRunning = false;
  }

  void resumeTimer() {
    if (_settingsProvider.timerEnabled && _gameResult == GameResult.ongoing) {
      _startTimer();
    }
  }

  /// Save current game state
  Future<void> _saveGame() async {
    if (_gameResult != GameResult.ongoing) {
      await _storageService.clearGameState();
      return;
    }

    final state = GameState(
      fen: _chess.fen,
      moveHistory: _moveHistory,
      playerColor: _playerColor,
      difficulty: _difficulty,
      result: _gameResult,
      startTime: _startTime,
      whiteTimeSeconds: _whiteTimeSeconds,
      blackTimeSeconds: _blackTimeSeconds,
    );

    await _storageService.saveGameState(state);
  }

  /// Export game as PGN
  String exportPGN() {
    final buffer = StringBuffer();

    buffer.writeln('[Event "Chess Master Game"]');
    buffer.writeln('[Site "Mobile"]');
    buffer.writeln('[Date "${_startTime.toIso8601String().split('T')[0]}"]');
    buffer.writeln('[White "${_playerColor == PlayerColor.white ? 'Player' : 'AI (${_difficulty.displayName})'}"]');
    buffer.writeln('[Black "${_playerColor == PlayerColor.black ? 'Player' : 'AI (${_difficulty.displayName})'}"]');

    String result;
    switch (_gameResult) {
      case GameResult.whiteWins:
        result = '1-0';
        break;
      case GameResult.blackWins:
        result = '0-1';
        break;
      case GameResult.draw:
      case GameResult.stalemate:
        result = '1/2-1/2';
        break;
      case GameResult.ongoing:
        result = '*';
        break;
    }
    buffer.writeln('[Result "$result"]');
    buffer.writeln();

    // Write moves
    for (int i = 0; i < _moveHistory.length; i++) {
      if (i % 2 == 0) {
        buffer.write('${(i ~/ 2) + 1}. ');
      }
      buffer.write('${_moveHistory[i].algebraicNotation} ');
    }

    if (_gameResult != GameResult.ongoing) {
      buffer.write(result);
    }

    return buffer.toString();
  }

  bool hasSavedGame() {
    return _storageService.hasSavedGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
