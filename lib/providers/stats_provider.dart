import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameStats {
  final int patternsCorrect;
  final int errors;

  const GameStats({this.patternsCorrect = 0, this.errors = 0});

  double get accuracy {
    final total = patternsCorrect + errors;
    if (total == 0) return 0.0;
    return (patternsCorrect / total) * 100.0;
  }
}

class GameStatsNotifier extends Notifier<GameStats> {
  @override
  GameStats build() => const GameStats();

  void updateStats(int correct, int errors) {
    state = GameStats(patternsCorrect: correct, errors: errors);
  }
}

final gameStatsProvider = NotifierProvider<GameStatsNotifier, GameStats>(() {
  return GameStatsNotifier();
});
