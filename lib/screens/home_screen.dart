import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/statistics_provider.dart';
import '../models/game_state.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

/// Home screen with main menu
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Logo and title
            _buildHeader(context),
            const SizedBox(height: 48),
            // Menu options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  _buildMenuButton(
                    context,
                    icon: Icons.play_arrow,
                    label: 'New Game',
                    onTap: () => _showNewGameDialog(context),
                  ),
                  const SizedBox(height: 16),
                  Consumer<GameProvider>(
                    builder: (context, game, child) {
                      if (!game.hasSavedGame()) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _buildMenuButton(
                            context,
                            icon: Icons.play_circle_outline,
                            label: 'Continue Game',
                            onTap: () => _continueGame(context),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                  _buildMenuButton(
                    context,
                    icon: Icons.bar_chart,
                    label: 'Statistics',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StatisticsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuButton(
                    context,
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Version info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Chess Master v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '♔',
              style: TextStyle(fontSize: 56),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Chess Master',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Challenge the AI',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewGameDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _NewGameSheet(),
    );
  }

  void _continueGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GameScreen(),
      ),
    );
  }
}

/// New game configuration sheet
class _NewGameSheet extends StatefulWidget {
  const _NewGameSheet();

  @override
  State<_NewGameSheet> createState() => _NewGameSheetState();
}

class _NewGameSheetState extends State<_NewGameSheet> {
  PlayerColor _selectedColor = PlayerColor.white;
  AIDifficulty _selectedDifficulty = AIDifficulty.medium;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _selectedColor = settings.playerColor;
    _selectedDifficulty = settings.difficulty;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'New Game',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Color selection
          Text(
            'Play as',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ColorOption(
                  color: PlayerColor.white,
                  isSelected: _selectedColor == PlayerColor.white,
                  onTap: () => setState(() => _selectedColor = PlayerColor.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ColorOption(
                  color: PlayerColor.black,
                  isSelected: _selectedColor == PlayerColor.black,
                  onTap: () => setState(() => _selectedColor = PlayerColor.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Difficulty selection
          Text(
            'Difficulty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: AIDifficulty.values.map((difficulty) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: difficulty != AIDifficulty.values.last ? 8 : 0,
                  ),
                  child: _DifficultyOption(
                    difficulty: difficulty,
                    isSelected: _selectedDifficulty == difficulty,
                    onTap: () => setState(() => _selectedDifficulty = difficulty),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Start button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _startGame(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Game',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startGame(BuildContext context) {
    final game = context.read<GameProvider>();
    game.newGame(
      playerColor: _selectedColor,
      difficulty: _selectedDifficulty,
    );

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GameScreen(),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final PlayerColor color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color == PlayerColor.white ? Colors.white : Colors.black87,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Center(
                child: Text(
                  color == PlayerColor.white ? '♔' : '♚',
                  style: TextStyle(
                    fontSize: 28,
                    color: color == PlayerColor.white ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              color == PlayerColor.white ? 'White' : 'Black',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyOption extends StatelessWidget {
  final AIDifficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyOption({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getDifficultyIcon(),
              size: 24,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              difficulty.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDifficultyIcon() {
    switch (difficulty) {
      case AIDifficulty.easy:
        return Icons.child_care;
      case AIDifficulty.medium:
        return Icons.person;
      case AIDifficulty.hard:
        return Icons.psychology;
    }
  }
}
