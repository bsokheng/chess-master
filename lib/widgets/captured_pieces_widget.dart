import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

/// Widget displaying captured pieces
class CapturedPiecesWidget extends StatelessWidget {
  final bool showWhiteCaptured;

  const CapturedPiecesWidget({
    super.key,
    required this.showWhiteCaptured,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        final pieces = showWhiteCaptured
            ? game.whiteCaptured
            : game.blackCaptured;

        if (pieces.isEmpty) {
          return const SizedBox(height: 24);
        }

        // Group pieces by type for cleaner display
        final grouped = _groupPieces(pieces);

        return Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: grouped.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 20),
                    ),
                    if (entry.value > 1)
                      Text(
                        'x${entry.value}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Map<String, int> _groupPieces(List<String> pieces) {
    final map = <String, int>{};
    for (final piece in pieces) {
      map[piece] = (map[piece] ?? 0) + 1;
    }
    return map;
  }
}

/// Material advantage indicator
class MaterialAdvantageWidget extends StatelessWidget {
  const MaterialAdvantageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        final balance = game.getMaterialBalance();

        if (balance == 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Equal',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final advantage = balance.abs() ~/ 100;
        final isWhiteAdvantage = balance > 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isWhiteAdvantage
                ? Colors.white
                : Colors.black87,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Text(
            '+$advantage',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isWhiteAdvantage ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
