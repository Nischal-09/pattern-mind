import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

enum GamePhase { memorize, recall, evaluation }

class GameState {
  final GamePhase currentPhase;
  final GameMode mode;
  final List<int> activePattern;
  final List<int> userSelection;
  final int patternsCorrect;
  final int errors;
  final int roundNumber;
  final int timeRemaining;
  final double roundTime;
  final int combo;
  final int maxCombo;
  final int totalScore;
  final int gridCount;
  final int litCount;
  final int wrongFeedbackIndex;
  final bool showSuccessOverlay;

  GameState({
    this.currentPhase = GamePhase.memorize,
    this.mode = GameMode.classic,
    this.activePattern = const [],
    this.userSelection = const [],
    this.patternsCorrect = 0,
    this.errors = 0,
    this.roundNumber = 1,
    this.timeRemaining = 60,
    this.roundTime = 5.0,
    this.combo = 1,
    this.maxCombo = 1,
    this.totalScore = 0,
    this.gridCount = 9,
    this.litCount = 3,
    this.wrongFeedbackIndex = -1,
    this.showSuccessOverlay = false,
  });

  GameState copyWith({
    GamePhase? currentPhase,
    GameMode? mode,
    List<int>? activePattern,
    List<int>? userSelection,
    int? patternsCorrect,
    int? errors,
    int? roundNumber,
    int? timeRemaining,
    double? roundTime,
    int? combo,
    int? maxCombo,
    int? totalScore,
    int? gridCount,
    int? litCount,
    int? wrongFeedbackIndex,
    bool? showSuccessOverlay,
  }) {
    return GameState(
      currentPhase: currentPhase ?? this.currentPhase,
      mode: mode ?? this.mode,
      activePattern: activePattern ?? this.activePattern,
      userSelection: userSelection ?? this.userSelection,
      patternsCorrect: patternsCorrect ?? this.patternsCorrect,
      errors: errors ?? this.errors,
      roundNumber: roundNumber ?? this.roundNumber,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      roundTime: roundTime ?? this.roundTime,
      combo: combo ?? this.combo,
      maxCombo: maxCombo ?? this.maxCombo,
      totalScore: totalScore ?? this.totalScore,
      gridCount: gridCount ?? this.gridCount,
      litCount: litCount ?? this.litCount,
      wrongFeedbackIndex: wrongFeedbackIndex ?? this.wrongFeedbackIndex,
      showSuccessOverlay: showSuccessOverlay ?? this.showSuccessOverlay,
    );
  }
}

  class GameNotifier extends AutoDisposeNotifier<GameState> {
  Timer? _gameTimer;
  Timer? _phaseTimer;
  Timer? _roundTimer;
  late GameDifficulty _difficulty;
  late GameMode _mode;

  @override
  GameState build() {
    _difficulty = ref.watch(settingsProvider);
    _mode = ref.watch(gameModeProvider);
    
    ref.onDispose(() {
      _gameTimer?.cancel();
      _phaseTimer?.cancel();
      _roundTimer?.cancel();
    });

    int gridCount = 9;
    int litCount = 3;
    if (_difficulty == GameDifficulty.medium) { gridCount = 16; litCount = 5; }
    else if (_difficulty == GameDifficulty.hard) { gridCount = 16; litCount = 7; }

    return GameState(gridCount: gridCount, litCount: litCount, mode: _mode);
  }

  void startGame() {
    _gameTimer?.cancel();
    _roundTimer?.cancel();
    
    state = state.copyWith(
      timeRemaining: _mode == GameMode.classic ? 60 : 0, 
      roundNumber: 1, 
      patternsCorrect: 0, 
      errors: 0,
      combo: 1,
      maxCombo: 1,
      totalScore: 0,
    );
    
    if (_mode == GameMode.classic) {
      _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.timeRemaining > 0) {
          state = state.copyWith(timeRemaining: state.timeRemaining - 1);
        } else {
          timer.cancel();
        }
      });
    }
    
    _startRound();
  }

  void _startRound() {
    final random = Random();
    final active = <int>{};
    while (active.length < state.litCount) {
      active.add(random.nextInt(state.gridCount));
    }

    double initialRoundTime = 5.0;
    if (_mode == GameMode.speedRun) {
      initialRoundTime = max(1.5, 5.0 - (state.roundNumber - 1) * 0.2);
    }

    state = state.copyWith(
      currentPhase: GamePhase.memorize,
      activePattern: active.toList(),
      userSelection: [],
      wrongFeedbackIndex: -1,
      showSuccessOverlay: false,
      roundTime: initialRoundTime,
    );

    int memorizeMs = 3000;
    if (_difficulty == GameDifficulty.medium) memorizeMs = 2500;
    if (_difficulty == GameDifficulty.hard) memorizeMs = 2000;

    _phaseTimer?.cancel();
    _phaseTimer = Timer(Duration(milliseconds: memorizeMs), () {
      bool canRecall = _mode == GameMode.classic ? state.timeRemaining > 0 : state.roundNumber <= 20;
      if (canRecall) {
        state = state.copyWith(currentPhase: GamePhase.recall);
        if (_mode == GameMode.speedRun) {
          _startRoundCountdown();
        }
      }
    });
  }

  void _startRoundCountdown() {
    _roundTimer?.cancel();
    const tickMs = 50;
    _roundTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      if (state.currentPhase != GamePhase.recall) {
        timer.cancel();
        return;
      }

      if (state.roundTime > 0) {
        state = state.copyWith(roundTime: max(0, state.roundTime - (tickMs / 1000)));
      } else {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    state = state.copyWith(
      currentPhase: GamePhase.evaluation,
      errors: state.errors + 1,
      combo: 1,
      userSelection: state.activePattern, // show what was missed
    );
    _phaseTimer?.cancel();
    _phaseTimer = Timer(const Duration(milliseconds: 800), () {
      _nextRoundOrEnd();
    });
  }

  void _nextRoundOrEnd() {
    if (_mode == GameMode.classic) {
      if (state.timeRemaining > 0) {
        state = state.copyWith(roundNumber: state.roundNumber + 1);
        _startRound();
      }
    } else {
      if (state.roundNumber < 20) {
        state = state.copyWith(roundNumber: state.roundNumber + 1);
        _startRound();
      } else {
        // End of Speed Run (20 rounds)
        state = state.copyWith(timeRemaining: -1); // Signal end for Speed Run
      }
    }
  }

  void handleTileTap(int index) {
    if (state.currentPhase != GamePhase.recall) return;
    if (state.userSelection.contains(index)) return;

    if (state.activePattern.contains(index)) {
      final newSelection = List<int>.from(state.userSelection)..add(index);
      state = state.copyWith(userSelection: newSelection);

      if (newSelection.length == state.activePattern.length) {
        _roundTimer?.cancel();
        
        int nextCombo = state.combo + 1;
        if (nextCombo > 5) nextCombo = 5;
        
        state = state.copyWith(
          currentPhase: GamePhase.evaluation,
          patternsCorrect: state.patternsCorrect + 1,
          combo: nextCombo,
          maxCombo: max(state.maxCombo, state.combo), // record combo BEFORE incrementing? Request said 1->2->3.
          // maxCombo: max(state.maxCombo, nextCombo) makes more sense for "highest combo achieved"
          totalScore: state.totalScore + (100 * state.combo),
          showSuccessOverlay: true,
        );
        // Correcting maxCombo: if they just hit a 2x correctly, current state.combo was 2.
        state = state.copyWith(maxCombo: max(state.maxCombo, state.combo));
        
        _phaseTimer?.cancel();
        _phaseTimer = Timer(const Duration(milliseconds: 500), () {
          _nextRoundOrEnd();
        });
      }
    } else {
      _roundTimer?.cancel();
      state = state.copyWith(
        currentPhase: GamePhase.evaluation,
        errors: state.errors + 1,
        combo: 1,
        wrongFeedbackIndex: index,
        userSelection: state.activePattern, // brief flash correct pattern
      );
      _phaseTimer?.cancel();
      _phaseTimer = Timer(const Duration(milliseconds: 800), () {
        _nextRoundOrEnd();
      });
    }
  }

  void forceStop() {
    _gameTimer?.cancel();
    _phaseTimer?.cancel();
  }
}

final gameStateProvider = AutoDisposeNotifierProvider<GameNotifier, GameState>(() {
  return GameNotifier();
});
