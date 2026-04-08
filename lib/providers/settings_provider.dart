import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GameDifficulty { easy, medium, hard }
enum GameMode { classic, speedRun, numberMemory }

class DifficultyNotifier extends Notifier<GameDifficulty> {
  @override
  GameDifficulty build() => GameDifficulty.easy;

  void setDifficulty(GameDifficulty difficulty) {
    state = difficulty;
  }
}

class GameModeNotifier extends Notifier<GameMode> {
  @override
  GameMode build() => GameMode.classic;

  void setMode(GameMode mode) {
    state = mode;
  }
}

final settingsProvider = NotifierProvider<DifficultyNotifier, GameDifficulty>(() {
  return DifficultyNotifier();
});

final gameModeProvider = NotifierProvider<GameModeNotifier, GameMode>(() {
  return GameModeNotifier();
});
