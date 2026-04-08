import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';
import 'stats_provider.dart';

enum NumberMemoryPhase { memorize, recall, evaluation }

class NumberMemoryState {
  final NumberMemoryPhase phase;
  final String targetNumber;
  final String userInput;
  final int timeRemaining;
  final int memorizeTimeRemaining; // Milliseconds
  final int roundNumber;
  final int score;
  final int roundsCorrect;
  final int errors;
  final bool showSuccessOverlay;
  final bool showErrorOverlay;

  const NumberMemoryState({
    this.phase = NumberMemoryPhase.memorize,
    this.targetNumber = '',
    this.userInput = '',
    this.timeRemaining = 60,
    this.memorizeTimeRemaining = 3000,
    this.roundNumber = 1,
    this.score = 0,
    this.roundsCorrect = 0,
    this.errors = 0,
    this.showSuccessOverlay = false,
    this.showErrorOverlay = false,
  });

  NumberMemoryState copyWith({
    NumberMemoryPhase? phase,
    String? targetNumber,
    String? userInput,
    int? timeRemaining,
    int? memorizeTimeRemaining,
    int? roundNumber,
    int? score,
    int? roundsCorrect,
    int? errors,
    bool? showSuccessOverlay,
    bool? showErrorOverlay,
  }) {
    return NumberMemoryState(
      phase: phase ?? this.phase,
      targetNumber: targetNumber ?? this.targetNumber,
      userInput: userInput ?? this.userInput,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      memorizeTimeRemaining: memorizeTimeRemaining ?? this.memorizeTimeRemaining,
      roundNumber: roundNumber ?? this.roundNumber,
      score: score ?? this.score,
      roundsCorrect: roundsCorrect ?? this.roundsCorrect,
      errors: errors ?? this.errors,
      showSuccessOverlay: showSuccessOverlay ?? this.showSuccessOverlay,
      showErrorOverlay: showErrorOverlay ?? this.showErrorOverlay,
    );
  }
}

class NumberMemoryNotifier extends Notifier<NumberMemoryState> {
  Timer? _globalTimer;
  Timer? _memorizeTimer;

  @override
  NumberMemoryState build() {
    ref.onDispose(() {
      _globalTimer?.cancel();
      _memorizeTimer?.cancel();
    });
    return const NumberMemoryState();
  }

  void startGame() {
    _globalTimer?.cancel();
    _memorizeTimer?.cancel();
    state = const NumberMemoryState();
    _startRound();
    _startGlobalTimer();
  }

  void _startGlobalTimer() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining > 0) {
        state = state.copyWith(timeRemaining: state.timeRemaining - 1);
      } else {
        _endGame();
      }
    });
  }

  void _startRound() {
    final digitCount = 3 + (state.roundNumber - 1) ~/ 3;
    final random = Random();
    String newNumber = '';
    for (int i = 0; i < digitCount; i++) {
      newNumber += random.nextInt(10).toString();
    }

    // Memorize time: 3s - 0.2s every 3 rounds, min 1.5s
    final memorizeMs = max(1500, (3000 - ((state.roundNumber - 1) ~/ 3) * 200));

    state = state.copyWith(
      phase: NumberMemoryPhase.memorize,
      targetNumber: newNumber,
      userInput: '',
      memorizeTimeRemaining: memorizeMs,
      showSuccessOverlay: false,
      showErrorOverlay: false,
    );

    _startMemorizeTimer();
  }

  void _startMemorizeTimer() {
    _memorizeTimer?.cancel();
    _memorizeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (state.memorizeTimeRemaining > 0) {
        state = state.copyWith(memorizeTimeRemaining: state.memorizeTimeRemaining - 100);
      } else {
        timer.cancel();
        state = state.copyWith(phase: NumberMemoryPhase.recall);
      }
    });
  }

  void appendDigit(String digit) {
    if (state.phase != NumberMemoryPhase.recall) return;
    state = state.copyWith(userInput: state.userInput + digit);
  }

  void backspace() {
    if (state.phase != NumberMemoryPhase.recall || state.userInput.isEmpty) return;
    state = state.copyWith(userInput: state.userInput.substring(0, state.userInput.length - 1));
  }

  void submit() {
    if (state.phase != NumberMemoryPhase.recall) return;

    if (state.userInput == state.targetNumber) {
      state = state.copyWith(
        phase: NumberMemoryPhase.evaluation,
        roundsCorrect: state.roundsCorrect + 1,
        score: state.score + 100,
        showSuccessOverlay: true,
      );
    } else {
      state = state.copyWith(
        phase: NumberMemoryPhase.evaluation,
        errors: state.errors + 1,
        showErrorOverlay: true,
      );
    }

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (state.timeRemaining > 0) {
        state = state.copyWith(roundNumber: state.roundNumber + 1);
        _startRound();
      }
    });
  }

  void _endGame() {
    _globalTimer?.cancel();
    _memorizeTimer?.cancel();
    // Logic to navigate or signal end - expected to be handled by UI listener
    state = state.copyWith(timeRemaining: 0);
  }
}

final numberMemoryProvider = NotifierProvider<NumberMemoryNotifier, NumberMemoryState>(() {
  return NumberMemoryNotifier();
});
