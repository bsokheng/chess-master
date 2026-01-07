import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';

/// Statistics screen showing player's game history
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Reset statistics',
            onPressed: () => _confirmReset(context),
          ),
        ],
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, statsProvider, child) {
          final stats = statsProvider.statistics;

          if (stats.gamesPlayed == 0) {
            return _buildEmptyState(context);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Overview card
              _buildOverviewCard(context, stats),
              const SizedBox(height: 16),

              // Win/Loss breakdown
              _buildWinLossCard(context, stats),
              const SizedBox(height: 16),

              // Detailed stats
              _buildDetailedStatsCard(context, stats),
              const SizedBox(height: 16),

              // Wins by difficulty
              if (stats.winsPerDifficulty.isNotEmpty)
                _buildDifficultyCard(context, stats),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No games played yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Play your first game to see statistics',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  value: stats.gamesPlayed.toString(),
                  label: 'Games',
                  icon: Icons.sports_esports,
                  color: Theme.of(context).colorScheme.primary,
                ),
                _StatItem(
                  value: '${stats.winRate.toStringAsFixed(1)}%',
                  label: 'Win Rate',
                  icon: Icons.percent,
                  color: stats.winRate >= 50 ? Colors.green : Colors.orange,
                ),
                _StatItem(
                  value: stats.longestWinStreak.toString(),
                  label: 'Best Streak',
                  icon: Icons.local_fire_department,
                  color: Colors.deepOrange,
                ),
              ],
            ),
            if (stats.currentWinStreak > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Current streak: ${stats.currentWinStreak} wins',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWinLossCard(BuildContext context, stats) {
    final total = stats.wins + stats.losses + stats.draws;
    final winPercent = total > 0 ? stats.wins / total : 0.0;
    final lossPercent = total > 0 ? stats.losses / total : 0.0;
    final drawPercent = total > 0 ? stats.draws / total : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Stacked bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 24,
                child: Row(
                  children: [
                    if (winPercent > 0)
                      Expanded(
                        flex: (winPercent * 100).round(),
                        child: Container(
                          color: Colors.green,
                          child: winPercent > 0.1
                              ? Center(
                                  child: Text(
                                    '${stats.wins}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    if (drawPercent > 0)
                      Expanded(
                        flex: (drawPercent * 100).round(),
                        child: Container(
                          color: Colors.orange,
                          child: drawPercent > 0.1
                              ? Center(
                                  child: Text(
                                    '${stats.draws}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    if (lossPercent > 0)
                      Expanded(
                        flex: (lossPercent * 100).round(),
                        child: Container(
                          color: Colors.red,
                          child: lossPercent > 0.1
                              ? Center(
                                  child: Text(
                                    '${stats.losses}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LegendItem(color: Colors.green, label: 'Wins', value: stats.wins),
                _LegendItem(color: Colors.orange, label: 'Draws', value: stats.draws),
                _LegendItem(color: Colors.red, label: 'Losses', value: stats.losses),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatsCard(BuildContext context, stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Stats',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Wins as White',
              value: stats.winsAsWhite.toString(),
              icon: Icons.circle_outlined,
            ),
            _DetailRow(
              label: 'Wins as Black',
              value: stats.winsAsBlack.toString(),
              icon: Icons.circle,
            ),
            _DetailRow(
              label: 'Total Moves Played',
              value: stats.totalMovesPlayed.toString(),
              icon: Icons.swap_horiz,
            ),
            _DetailRow(
              label: 'Avg Moves per Game',
              value: stats.gamesPlayed > 0
                  ? (stats.totalMovesPlayed / stats.gamesPlayed).toStringAsFixed(1)
                  : '0',
              icon: Icons.timeline,
            ),
            if (stats.lastPlayed != null)
              _DetailRow(
                label: 'Last Played',
                value: _formatDate(stats.lastPlayed!),
                icon: Icons.calendar_today,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(BuildContext context, stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wins by Difficulty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.winsPerDifficulty.entries.map((entry) {
              IconData icon;
              switch (entry.key) {
                case 'easy':
                  icon = Icons.child_care;
                  break;
                case 'medium':
                  icon = Icons.person;
                  break;
                case 'hard':
                  icon = Icons.psychology;
                  break;
                default:
                  icon = Icons.emoji_events;
              }
              return _DetailRow(
                label: entry.key[0].toUpperCase() + entry.key.substring(1),
                value: entry.value.toString(),
                icon: icon,
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Statistics'),
        content: const Text(
          'Are you sure you want to reset all statistics? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<StatisticsProvider>().resetStatistics();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Statistics reset')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($value)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
