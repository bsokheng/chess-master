import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/game_state.dart';

/// Settings screen for app configuration
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Appearance section
              _SectionHeader(title: 'Appearance'),
              _SettingsCard(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark color scheme'),
                    value: settings.isDarkMode,
                    onChanged: (value) => settings.setDarkMode(value),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Board Theme'),
                    subtitle: Text(settings.boardTheme.displayName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showBoardThemeDialog(context, settings),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Game defaults section
              _SectionHeader(title: 'Game Defaults'),
              _SettingsCard(
                children: [
                  ListTile(
                    title: const Text('Default Difficulty'),
                    subtitle: Text(settings.difficulty.displayName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDifficultyDialog(context, settings),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Default Color'),
                    subtitle: Text(settings.playerColor == PlayerColor.white
                        ? 'White'
                        : 'Black'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showColorDialog(context, settings),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Auto-Queen'),
                    subtitle: const Text('Automatically promote pawns to queen'),
                    value: settings.autoQueen,
                    onChanged: (value) => settings.setAutoQueen(value),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Timer section
              _SectionHeader(title: 'Timer'),
              _SettingsCard(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Timer'),
                    subtitle: const Text('Play with time control'),
                    value: settings.timerEnabled,
                    onChanged: (value) => settings.setTimerEnabled(value),
                  ),
                  if (settings.timerEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Time per player'),
                      subtitle: Text('${settings.timerMinutes} minutes'),
                      trailing: SizedBox(
                        width: 150,
                        child: Slider(
                          value: settings.timerMinutes.toDouble(),
                          min: 1,
                          max: 30,
                          divisions: 29,
                          label: '${settings.timerMinutes} min',
                          onChanged: (value) =>
                              settings.setTimerMinutes(value.toInt()),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Visual feedback section
              _SectionHeader(title: 'Visual Feedback'),
              _SettingsCard(
                children: [
                  SwitchListTile(
                    title: const Text('Show Legal Moves'),
                    subtitle: const Text('Highlight possible moves'),
                    value: settings.showLegalMoves,
                    onChanged: (value) => settings.setShowLegalMoves(value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Show Last Move'),
                    subtitle: const Text('Highlight the last move played'),
                    value: settings.showLastMove,
                    onChanged: (value) => settings.setShowLastMove(value),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Audio & Haptics section
              _SectionHeader(title: 'Audio & Haptics'),
              _SettingsCard(
                children: [
                  SwitchListTile(
                    title: const Text('Sound Effects'),
                    subtitle: const Text('Play sounds on moves'),
                    value: settings.soundEnabled,
                    onChanged: (value) => settings.setSoundEnabled(value),
                  ),
                  if (settings.soundEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Volume'),
                      trailing: SizedBox(
                        width: 150,
                        child: Slider(
                          value: settings.soundVolume,
                          onChanged: (value) => settings.setSoundVolume(value),
                        ),
                      ),
                    ),
                  ],
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Haptic Feedback'),
                    subtitle: const Text('Vibrate on piece selection'),
                    value: settings.hapticEnabled,
                    onChanged: (value) => settings.setHapticEnabled(value),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // About section
              _SectionHeader(title: 'About'),
              _SettingsCard(
                children: [
                  ListTile(
                    title: const Text('Chess Master'),
                    subtitle: const Text('Version 1.0.0'),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('♔', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showBoardThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Board Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: BoardTheme.values.map((theme) {
            return ListTile(
              title: Text(theme.displayName),
              leading: _BoardThemePreview(theme: theme),
              selected: settings.boardTheme == theme,
              onTap: () {
                settings.setBoardTheme(theme);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDifficultyDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AIDifficulty.values.map((difficulty) {
            return RadioListTile<AIDifficulty>(
              title: Text(difficulty.displayName),
              subtitle: Text('Search depth: ${difficulty.depth}'),
              value: difficulty,
              groupValue: settings.difficulty,
              onChanged: (value) {
                if (value != null) {
                  settings.setDifficulty(value);
                }
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showColorDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Color'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PlayerColor.values.map((color) {
            return RadioListTile<PlayerColor>(
              title: Text(color == PlayerColor.white ? 'White' : 'Black'),
              secondary: Text(
                color == PlayerColor.white ? '♔' : '♚',
                style: const TextStyle(fontSize: 24),
              ),
              value: color,
              groupValue: settings.playerColor,
              onChanged: (value) {
                if (value != null) {
                  settings.setPlayerColor(value);
                }
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: children,
      ),
    );
  }
}

class _BoardThemePreview extends StatelessWidget {
  final BoardTheme theme;

  const _BoardThemePreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(color: Color(theme.lightSquare)),
          ),
          Expanded(
            child: Container(color: Color(theme.darkSquare)),
          ),
        ],
      ),
    );
  }
}
