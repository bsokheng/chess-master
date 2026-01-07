# Chess Master

A fully functional chess game with AI opponent for Android and iOS devices, built with Flutter.

## Features

### Core Game Features
- Complete chess implementation with all standard rules
- Legal move validation for all pieces
- Special moves: castling, en passant, pawn promotion
- Check, checkmate, and stalemate detection
- Move history with algebraic notation

### AI Opponent
- Minimax algorithm with alpha-beta pruning
- Three difficulty levels:
  - **Easy** (depth 2) - Good for beginners
  - **Medium** (depth 4) - Moderate challenge
  - **Hard** (depth 6) - Strong play
- Position evaluation using:
  - Material value
  - Piece-square tables
  - Mobility bonus
  - Quiescence search to avoid horizon effect

### User Interface
- Clean, modern Material Design 3 styling
- Responsive board that adapts to different screen sizes
- Support for both portrait and landscape orientations
- Light and dark theme support
- Multiple board themes (Classic, Blue, Green, Purple, Wood)

### Game Features
- Player vs AI mode
- Choose to play as White or Black
- Undo last move
- Flip board view
- Move hints (shows best move)
- Material advantage indicator
- Captured pieces display
- Optional game timer
- Visual feedback for:
  - Legal moves (highlighted when piece selected)
  - Last move (from/to squares highlighted)
  - Check status
  - AI "thinking" indicator

### Data & Statistics
- Auto-save game state
- Continue incomplete games
- Track statistics:
  - Games played, wins, losses, draws
  - Win rate percentage
  - Win streak tracking
  - Wins by color and difficulty
- Export games in PGN format

## Project Structure

```
chess_master/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   ├── game_state.dart       # Game state and move models
│   │   └── statistics.dart       # Player statistics model
│   ├── providers/
│   │   ├── game_provider.dart    # Main game state management
│   │   ├── settings_provider.dart # App settings
│   │   └── statistics_provider.dart # Statistics management
│   ├── screens/
│   │   ├── home_screen.dart      # Main menu
│   │   ├── game_screen.dart      # Chess game screen
│   │   ├── settings_screen.dart  # Settings configuration
│   │   └── statistics_screen.dart # Statistics display
│   ├── services/
│   │   ├── chess_ai_service.dart # AI with minimax algorithm
│   │   ├── sound_service.dart    # Sound effects
│   │   └── storage_service.dart  # Data persistence
│   ├── utils/
│   │   └── constants.dart        # App constants
│   └── widgets/
│       ├── chess_board_widget.dart    # Main chess board
│       ├── move_history_widget.dart   # Move history display
│       ├── game_controls_widget.dart  # Game control buttons
│       ├── timer_widget.dart          # Chess clock
│       ├── captured_pieces_widget.dart # Captured pieces display
│       └── game_status_widget.dart    # Game status indicator
├── test/
│   └── chess_ai_test.dart        # Unit tests
├── assets/
│   ├── sounds/                   # Sound effect files
│   └── images/                   # Image assets
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio or VS Code with Flutter extensions
- Android SDK (for Android builds)
- Xcode (for iOS builds, macOS only)

### Installation

1. **Clone or navigate to the project:**
   ```bash
   cd chess_master
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

### Build APK (Android)

1. **Debug APK:**
   ```bash
   flutter build apk --debug
   ```
   Output: `build/app/outputs/flutter-apk/app-debug.apk`

2. **Release APK:**
   ```bash
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`

3. **App Bundle (for Play Store):**
   ```bash
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`

### Build iOS

1. **Debug build:**
   ```bash
   flutter build ios --debug
   ```

2. **Release build:**
   ```bash
   flutter build ios --release
   ```

3. **Open in Xcode for archive:**
   ```bash
   open ios/Runner.xcworkspace
   ```

## AI Algorithm Explanation

### Minimax with Alpha-Beta Pruning

The chess AI uses the **minimax algorithm** enhanced with **alpha-beta pruning** to find the best move.

#### How it works:

1. **Game Tree Search**: The algorithm explores possible future positions by simulating moves for both players.

2. **Minimax Principle**:
   - At positions where AI moves, it picks the move with maximum evaluation (best for AI)
   - At positions where opponent moves, it assumes opponent picks minimum evaluation (best for opponent)

3. **Alpha-Beta Pruning**: Eliminates branches that can't affect the final decision:
   - **Alpha**: Best value the maximizer (AI) can guarantee
   - **Beta**: Best value the minimizer (opponent) can guarantee
   - If beta ≤ alpha, we can prune (skip) the remaining branches

4. **Quiescence Search**: Extends search at positions with captures to avoid the "horizon effect" (misjudging tactical positions).

#### Position Evaluation:

The AI evaluates positions based on:

1. **Material Value**:
   - Pawn: 100
   - Knight: 320
   - Bishop: 330
   - Rook: 500
   - Queen: 900

2. **Piece-Square Tables**: Bonuses/penalties based on piece location
   - Pawns: Encouraged to advance and control center
   - Knights: Best in center, worst on edges
   - Bishops: Favor long diagonals
   - Rooks: Favor 7th rank and open files
   - King: Safe position in middlegame, active in endgame

3. **Mobility**: Bonus for having more legal moves

4. **Check Penalty**: Penalty for being in check

## Testing

Run the test suite:
```bash
flutter test
```

Run a specific test file:
```bash
flutter test test/chess_ai_test.dart
```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| chess | ^0.8.0 | Chess logic and move validation |
| provider | ^6.1.1 | State management |
| shared_preferences | ^2.2.2 | Local data persistence |
| audioplayers | ^5.2.1 | Sound effects |
| vibration | ^1.8.4 | Haptic feedback |
| flutter_svg | ^2.0.9 | SVG rendering |
| google_fonts | ^6.1.0 | Custom typography |

## Future Improvements

- [ ] Online multiplayer
- [ ] Opening book database
- [ ] Endgame tablebases
- [ ] Puzzle mode
- [ ] Analysis board
- [ ] Game import/export from clipboard
- [ ] Multiple time controls (Fischer, Bronstein)
- [ ] Stockfish engine integration (via UCI)

## License

This project is provided for educational purposes.

## Acknowledgments

- Chess piece Unicode characters for cross-platform rendering
- The `chess` Dart package for chess logic
- Material Design 3 for UI guidelines
