import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_provider.dart';
import '../services/database_service.dart';

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

class GameStatsNotifier extends Notifier<Map<GameMode, GameStats>> {
  @override
  Map<GameMode, GameStats> build() {
    _loadSessionStats();
    return {
      GameMode.classic: const GameStats(),
      GameMode.speedRun: const GameStats(),
      GameMode.numberMemory: const GameStats(),
    };
  }

  Future<void> _loadSessionStats() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<GameMode, GameStats> loaded = {};
    for (var mode in GameMode.values) {
      final prefix = 'last_session_${mode.name}';
      loaded[mode] = GameStats(
        patternsCorrect: prefs.getInt('${prefix}_correct') ?? 0,
        errors: prefs.getInt('${prefix}_errors') ?? 0,
      );
    }
    state = loaded;
  }

  Future<void> updateStats(GameMode mode, int correct, int errors) async {
    final prefs = await SharedPreferences.getInstance();
    final newMap = Map<GameMode, GameStats>.from(state);
    newMap[mode] = GameStats(patternsCorrect: correct, errors: errors);
    state = newMap;

    final prefix = 'last_session_${mode.name}';
    await prefs.setInt('${prefix}_correct', correct);
    await prefs.setInt('${prefix}_errors', errors);
  }
}

final gameStatsProvider = NotifierProvider<GameStatsNotifier, Map<GameMode, GameStats>>(() {
  return GameStatsNotifier();
});

class DifficultyStats {
  final int personalBest;
  final int totalPatterns;
  final int winStreak;

  const DifficultyStats({
    this.personalBest = 0,
    this.totalPatterns = 0,
    this.winStreak = 0,
  });

  DifficultyStats copyWith({
    int? personalBest,
    int? totalPatterns,
    int? winStreak,
  }) {
    return DifficultyStats(
      personalBest: personalBest ?? this.personalBest,
      totalPatterns: totalPatterns ?? this.totalPatterns,
      winStreak: winStreak ?? this.winStreak,
    );
  }
}

class PersistentStats {
  final Map<GameMode, Map<GameDifficulty, DifficultyStats>> stats;

  const PersistentStats({
    this.stats = const {
      GameMode.classic: {
        GameDifficulty.easy: DifficultyStats(),
        GameDifficulty.medium: DifficultyStats(),
        GameDifficulty.hard: DifficultyStats(),
      },
      GameMode.speedRun: {
        GameDifficulty.easy: DifficultyStats(),
        GameDifficulty.medium: DifficultyStats(),
        GameDifficulty.hard: DifficultyStats(),
      },
      GameMode.numberMemory: {
        GameDifficulty.easy: DifficultyStats(),
        GameDifficulty.medium: DifficultyStats(),
        GameDifficulty.hard: DifficultyStats(),
      },
    },
  });

  DifficultyStats getFor(GameMode mode, GameDifficulty difficulty) {
    return stats[mode]?[difficulty] ?? const DifficultyStats();
  }

  PersistentStats copyWith({Map<GameMode, Map<GameDifficulty, DifficultyStats>>? stats}) {
    return PersistentStats(stats: stats ?? this.stats);
  }
}

class PersistentStatsNotifier extends Notifier<PersistentStats> {
  @override
  PersistentStats build() {
    _loadStats();
    return const PersistentStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final dbService = DatabaseService();
    final highScores = await dbService.getHighScores();
    final totalPatterns = await dbService.getTotalPatterns();
    
    final Map<GameMode, Map<GameDifficulty, DifficultyStats>> loadedStats = {};

    for (var mode in GameMode.values) {
      final Map<GameDifficulty, DifficultyStats> diffMap = {};
      for (var diff in GameDifficulty.values) {
        final prefix = '${mode.name}_${diff.name}';
        
        // Priority: SQLite High Scores, fallback to SharedPreferences
        final dbPB = highScores[prefix] ?? 0;
        final spPB = prefs.getInt('${prefix}_pb_score') ?? 0;
        
        final dbTotal = totalPatterns[prefix] ?? 0;
        final spTotal = prefs.getInt('${prefix}_total_patterns') ?? 0;

        diffMap[diff] = DifficultyStats(
          personalBest: max(dbPB, spPB),
          totalPatterns: max(dbTotal, spTotal),
          winStreak: prefs.getInt('${prefix}_win_streak') ?? 0,
        );
      }
      loadedStats[mode] = diffMap;
    }

    state = PersistentStats(stats: loadedStats);
  }

  Future<void> recordSession({
    required GameMode mode,
    required GameDifficulty difficulty,
    required int patternsCorrect,
    required double accuracy,
    required int totalScore,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final dbService = DatabaseService();
    
    // 1. Save to SQLite
    await dbService.insertSession(
      mode: mode.name,
      difficulty: difficulty.name,
      patternsCorrect: patternsCorrect,
      accuracy: accuracy,
      totalScore: totalScore,
    );

    // 2. Update local state
    final currentStats = state.getFor(mode, difficulty);
    
    final newBest = max(currentStats.personalBest, totalScore);
    final newTotal = currentStats.totalPatterns + patternsCorrect;
    final newStreak = accuracy >= 80.0 ? currentStats.winStreak + 1 : 0;

    final updatedDifficultyStats = currentStats.copyWith(
      personalBest: newBest,
      totalPatterns: newTotal,
      winStreak: newStreak,
    );

    final newStatsMap = Map<GameMode, Map<GameDifficulty, DifficultyStats>>.from(state.stats);
    final newDiffMap = Map<GameDifficulty, DifficultyStats>.from(newStatsMap[mode]!);
    newDiffMap[difficulty] = updatedDifficultyStats;
    newStatsMap[mode] = newDiffMap;
    
    state = state.copyWith(stats: newStatsMap);

    // 3. Keep SharedPreferences as a lightweight backup/fast cache for streaks
    final prefix = '${mode.name}_${difficulty.name}';
    await prefs.setInt('${prefix}_pb_score', newBest);
    await prefs.setInt('${prefix}_total_patterns', newTotal);
    await prefs.setInt('${prefix}_win_streak', newStreak);
  }
}

final persistentStatsProvider = NotifierProvider<PersistentStatsNotifier, PersistentStats>(() {
  return PersistentStatsNotifier();
});
