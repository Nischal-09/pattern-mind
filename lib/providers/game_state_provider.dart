import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

enum GamePhase { memorize, recall, evaluation }

class GameState {
  final GamePhase currentPhase;
  final List<int> activePattern;
  final List<int> userSelection;
  final int patternsCorrect;
  final int errors;
  final int roundNumber;
  final int timeRemaining;
  final int gridCount;
  final int litCount;
  final int wrongFeedbackIndex;
  final bool showSuccessOverlay;

  GameState({
    this.currentPhase = GamePhase.memorize,
    this.activePattern = const [],
    this.userSelection = const [],
    this.patternsCorrect = 0,
    this.errors = 0,
    this.roundNumber = 1,
    this.timeRemaining = 60,
    this.gridCount = 9,
    this.litCount = 3,
    this.wrongFeedbackIndex = -1,
    this.showSuccessOverlay = false,
  });

  GameState copyWith({
    GamePhase? currentPhase,
    List<int>? activePattern,
    List<int>? userSelection,
    int? patternsCorrect,
    int? errors,
    int? roundNumber,
    int? timeRemaining,
    int? gridCount,
    int? litCount,
    int? wrongFeedbackIndex,
    bool? showSuccessOverlay,
  }) {
    return GameState(
      currentPhase: currentPhase ?? this.currentPhase,
      activePattern: activePattern ?? this.activePattern,
      userSelection: userSelection ?? this.userSelection,
      patternsCorrect: patternsCorrect ?? this.patternsCorrect,
      errors: errors ?? this.errors,
      roundNumber: roundNumber ?? this.roundNumber,
      timeRemaining: timeRemaining ?? this.timeRemaining,
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
  late GameDifficulty _difficulty;

  @override
  GameState build() {
    _difficulty = ref.watch(settingsProvider);
    
    ref.onDispose(() {
      _gameTimer?.cancel();
      _phaseTimer?.cancel();
    });

    int gridCount = 9;
    int litCount = 3;
    if (_difficulty == GameDifficulty.medium) { gridCount = 16; litCount = 5; }
    else if (_difficulty == GameDifficulty.hard) { gridCount = 16; litCount = 7; }

    return GameState(gridCount: gridCount, litCount: litCount);
  }

  void startGame() {
    _gameTimer?.cancel();
    state = state.copyWith(timeRemaining: 60, roundNumber: 1, patternsCorrect: 0, errors: 0);
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining > 0) {
        state = state.copyWith(timeRemaining: state.timeRemaining - 1);
      } else {
        timer.cancel();
      }
    });
    _startRound();
  }

  void _startRound() {
    final random = Random();
    final active = <int>{};
    while (active.length < state.litCount) {
      active.add(random.nextInt(state.gridCount));
    }

    state = state.copyWith(
      currentPhase: GamePhase.memorize,
      activePattern: active.toList(),
      userSelection: [],
      wrongFeedbackIndex: -1,
      showSuccessOverlay: false,
    );

    int memorizeMs = 3000;
    if (_difficulty == GameDifficulty.medium) memorizeMs = 2500;
    if (_difficulty == GameDifficulty.hard) memorizeMs = 2000;

    _phaseTimer?.cancel();
    _phaseTimer = Timer(Duration(milliseconds: memorizeMs), () {
      if (state.timeRemaining > 0) {
        state = state.copyWith(currentPhase: GamePhase.recall);
      }
    });
  }

  void handleTileTap(int index) {
    if (state.currentPhase != GamePhase.recall) return;
    if (state.userSelection.contains(index)) return;

    if (state.activePattern.contains(index)) {
      final newSelection = List<int>.from(state.userSelection)..add(index);
      state = state.copyWith(userSelection: newSelection);

      if (newSelection.length == state.activePattern.length) {
        state = state.copyWith(
          currentPhase: GamePhase.evaluation,
          patternsCorrect: state.patternsCorrect + 1,
          showSuccessOverlay: true,
        );
        _phaseTimer?.cancel();
        _phaseTimer = Timer(const Duration(milliseconds: 500), () {
          if (state.timeRemaining > 0) {
            state = state.copyWith(roundNumber: state.roundNumber + 1);
            _startRound();
          }
        });
      }
    } else {
      state = state.copyWith(
        currentPhase: GamePhase.evaluation,
        errors: state.errors + 1,
        wrongFeedbackIndex: index,
        userSelection: state.activePattern, // brief flash correct pattern
      );
      _phaseTimer?.cancel();
      _phaseTimer = Timer(const Duration(milliseconds: 800), () {
        if (state.timeRemaining > 0) {
           state = state.copyWith(roundNumber: state.roundNumber + 1);
           _startRound();
        }
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
