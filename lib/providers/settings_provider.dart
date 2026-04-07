import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GameDifficulty { easy, medium, hard }

class DifficultyNotifier extends Notifier<GameDifficulty> {
  @override
  GameDifficulty build() => GameDifficulty.easy;

  void setDifficulty(GameDifficulty difficulty) {
    state = difficulty;
  }
}

final settingsProvider = NotifierProvider<DifficultyNotifier, GameDifficulty>(() {
  return DifficultyNotifier();
});
