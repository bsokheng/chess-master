/// Player statistics model for tracking game history
class Statistics {
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final int winsAsWhite;
  final int winsAsBlack;
  final int totalMovesPlayed;
  final int longestWinStreak;
  final int currentWinStreak;
  final Map<String, int> winsPerDifficulty;
  final DateTime? lastPlayed;

  Statistics({
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.winsAsWhite = 0,
    this.winsAsBlack = 0,
    this.totalMovesPlayed = 0,
    this.longestWinStreak = 0,
    this.currentWinStreak = 0,
    this.winsPerDifficulty = const {},
    this.lastPlayed,
  });

  double get winRate => gamesPlayed > 0 ? (wins / gamesPlayed) * 100 : 0;

  Statistics copyWith({
    int? gamesPlayed,
    int? wins,
    int? losses,
    int? draws,
    int? winsAsWhite,
    int? winsAsBlack,
    int? totalMovesPlayed,
    int? longestWinStreak,
    int? currentWinStreak,
    Map<String, int>? winsPerDifficulty,
    DateTime? lastPlayed,
  }) {
    return Statistics(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      winsAsWhite: winsAsWhite ?? this.winsAsWhite,
      winsAsBlack: winsAsBlack ?? this.winsAsBlack,
      totalMovesPlayed: totalMovesPlayed ?? this.totalMovesPlayed,
      longestWinStreak: longestWinStreak ?? this.longestWinStreak,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      winsPerDifficulty: winsPerDifficulty ?? this.winsPerDifficulty,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }

  Map<String, dynamic> toJson() => {
    'gamesPlayed': gamesPlayed,
    'wins': wins,
    'losses': losses,
    'draws': draws,
    'winsAsWhite': winsAsWhite,
    'winsAsBlack': winsAsBlack,
    'totalMovesPlayed': totalMovesPlayed,
    'longestWinStreak': longestWinStreak,
    'currentWinStreak': currentWinStreak,
    'winsPerDifficulty': winsPerDifficulty,
    'lastPlayed': lastPlayed?.toIso8601String(),
  };

  factory Statistics.fromJson(Map<String, dynamic> json) => Statistics(
    gamesPlayed: json['gamesPlayed'] ?? 0,
    wins: json['wins'] ?? 0,
    losses: json['losses'] ?? 0,
    draws: json['draws'] ?? 0,
    winsAsWhite: json['winsAsWhite'] ?? 0,
    winsAsBlack: json['winsAsBlack'] ?? 0,
    totalMovesPlayed: json['totalMovesPlayed'] ?? 0,
    longestWinStreak: json['longestWinStreak'] ?? 0,
    currentWinStreak: json['currentWinStreak'] ?? 0,
    winsPerDifficulty: Map<String, int>.from(json['winsPerDifficulty'] ?? {}),
    lastPlayed: json['lastPlayed'] != null
        ? DateTime.parse(json['lastPlayed'])
        : null,
  );
}
