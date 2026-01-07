import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/statistics_provider.dart';
import '../models/game_state.dart';
import '../widgets/chess_board_widget.dart';
import '../widgets/move_history_widget.dart';
import '../widgets/game_controls_widget.dart';
import '../widgets/timer_widget.dart';
import '../widgets/captured_pieces_widget.dart';
import '../widgets/game_status_widget.dart';

/// Main game screen
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  bool _gameOverDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final game = context.read<GameProvider>();
    if (state == AppLifecycleState.paused) {
      game.pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      game.resumeTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        // Show game over dialog when game ends
        if (game.isGameOver && !_gameOverDialogShown) {
          _gameOverDialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showGameOverDialog(context, game);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chess Master'),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showGameMenu(context),
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate available space
                final isLandscape = constraints.maxWidth > constraints.maxHeight;

                if (isLandscape) {
                  return _buildLandscapeLayout(context, game, constraints);
                } else {
                  return _buildPortraitLayout(context, game, constraints);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    GameProvider game,
    BoxConstraints constraints,
  ) {
    return Column(
      children: [
        // Top player info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Expanded(child: PlayerInfoWidget(isTop: true)),
              const SizedBox(width: 8),
              TimerWidget(isWhite: game.isBoardFlipped),
            ],
          ),
        ),

        // Captured pieces (opponent's captures)
        CapturedPiecesWidget(showWhiteCaptured: !game.isBoardFlipped),

        // Chess board
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const ChessBoardWidget(),
        ),

        // Captured pieces (player's captures)
        CapturedPiecesWidget(showWhiteCaptured: game.isBoardFlipped),

        // Bottom player info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Expanded(child: PlayerInfoWidget(isTop: false)),
              const SizedBox(width: 8),
              TimerWidget(isWhite: !game.isBoardFlipped),
            ],
          ),
        ),

        const Spacer(),

        // Game status
        const GameStatusWidget(),

        const SizedBox(height: 16),

        // Controls
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: GameControlsWidget(),
        ),

        const SizedBox(height: 16),

        // Move history (expandable)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ExpansionTile(
            title: Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                const Text('Move History'),
                const Spacer(),
                Text(
                  '${game.moveHistory.length} moves',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            children: const [
              SizedBox(
                height: 100,
                child: MoveHistoryWidget(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    GameProvider game,
    BoxConstraints constraints,
  ) {
    return Row(
      children: [
        // Board section
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: const ChessBoardWidget(),
                ),
              ),
            ],
          ),
        ),

        // Info panel
        Expanded(
          flex: 2,
          child: Column(
            children: [
              const SizedBox(height: 16),
              const PlayerInfoWidget(isTop: true),
              const SizedBox(height: 8),
              const DualTimerWidget(),
              const SizedBox(height: 8),
              const PlayerInfoWidget(isTop: false),
              const Divider(),
              const GameStatusWidget(),
              const SizedBox(height: 8),
              const CompactGameControlsWidget(),
              const Divider(),
              Expanded(
                child: MoveHistoryWidget(maxHeight: double.infinity),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showGameMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('New Game'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmNewGame(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flip),
                title: const Text('Flip Board'),
                onTap: () {
                  Navigator.pop(context);
                  context.read<GameProvider>().flipBoard();
                },
              ),
              Consumer<GameProvider>(
                builder: (context, game, _) {
                  return ListTile(
                    leading: const Icon(Icons.file_download),
                    title: const Text('Export PGN'),
                    onTap: () {
                      Navigator.pop(context);
                      _exportPGN(context, game);
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Resign'),
                enabled: !context.read<GameProvider>().isGameOver,
                onTap: () {
                  Navigator.pop(context);
                  _confirmResign(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _confirmNewGame(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Game'),
        content: const Text('Start a new game? Current progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _gameOverDialogShown = false;
              context.read<GameProvider>().newGame();
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  void _confirmResign(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resign'),
        content: const Text('Are you sure you want to resign?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Resign logic would go here
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
  }

  void _exportPGN(BuildContext context, GameProvider game) {
    final pgn = game.exportPGN();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PGN Export'),
        content: SingleChildScrollView(
          child: SelectableText(
            pgn,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, GameProvider game) {
    final playerColor = game.playerColor;
    final result = game.gameResult;

    String title;
    String message;
    IconData icon;
    Color? iconColor;

    final playerWon = (result == GameResult.whiteWins && playerColor == PlayerColor.white) ||
        (result == GameResult.blackWins && playerColor == PlayerColor.black);

    if (playerWon) {
      title = 'Victory!';
      message = 'Congratulations! You defeated the AI.';
      icon = Icons.emoji_events;
      iconColor = Colors.amber;
    } else if (result == GameResult.draw || result == GameResult.stalemate) {
      title = result == GameResult.stalemate ? 'Stalemate' : 'Draw';
      message = 'The game ended in a draw.';
      icon = Icons.handshake;
      iconColor = Colors.orange;
    } else {
      title = 'Defeat';
      message = 'The AI won this time. Try again!';
      icon = Icons.sentiment_dissatisfied;
      iconColor = Colors.red;
    }

    // Record statistics
    context.read<StatisticsProvider>().recordGame(
      result: result,
      playerColor: playerColor,
      difficulty: game.difficulty,
      moveCount: game.moveHistory.length,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Icon(icon, size: 64, color: iconColor ?? Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Moves: ${game.moveHistory.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Home'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _gameOverDialogShown = false;
              context.read<GameProvider>().newGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }
}
