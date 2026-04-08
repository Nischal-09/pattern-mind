import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/settings_provider.dart';
import '../providers/number_memory_provider.dart';
import '../providers/stats_provider.dart';
import '../common/gaming_ui.dart';

class NumberMemoryScreen extends ConsumerStatefulWidget {
  const NumberMemoryScreen({super.key});

  @override
  ConsumerState<NumberMemoryScreen> createState() => _NumberMemoryScreenState();
}

class _NumberMemoryScreenState extends ConsumerState<NumberMemoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(numberMemoryProvider.notifier).startGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(numberMemoryProvider);
    final primary = Theme.of(context).colorScheme.primary;

    // Listen for game end
    ref.listen(numberMemoryProvider, (prev, next) {
      if (prev != null && prev.timeRemaining > 0 && next.timeRemaining == 0) {
        final total = next.roundsCorrect + next.errors;
        final accuracy = total == 0 ? 0.0 : (next.roundsCorrect / total * 100);
        
        ref.read(gameStatsProvider.notifier).updateStats(GameMode.numberMemory, next.roundsCorrect, next.errors);
        ref.read(persistentStatsProvider.notifier).recordSession(
          mode: GameMode.numberMemory,
          difficulty: ref.read(settingsProvider),
          patternsCorrect: next.roundsCorrect,
          accuracy: accuracy,
          totalScore: next.score,
        );

        Navigator.of(context).pushReplacementNamed('/results', arguments: {
          'patternsCorrect': next.roundsCorrect,
          'errors': next.errors,
          'totalScore': next.score,
          'maxCombo': 1, // Number memory doesn't have combo currently
          'mode': GameMode.numberMemory,
        });
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OP_MODE: NUM_MEM',
                            style: GoogleFonts.shareTechMono(color: primary, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SCORE: ${state.score}',
                            style: GoogleFonts.orbitron(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          '00:${state.timeRemaining.toString().padLeft(2, '0')}',
                          style: GoogleFonts.orbitron(
                            color: state.timeRemaining < 10 ? Colors.redAccent : primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: _buildMainContent(state, primary),
                  ),
                ),

                if (state.phase == NumberMemoryPhase.recall)
                  FadeInUp(
                    child: _NumberPad(
                      onDigit: (d) => ref.read(numberMemoryProvider.notifier).appendDigit(d),
                      onBackspace: () => ref.read(numberMemoryProvider.notifier).backspace(),
                      onSubmit: () => ref.read(numberMemoryProvider.notifier).submit(),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          
          if (state.showSuccessOverlay)
            Positioned.fill(child: SuccessOverlay()),
          if (state.showErrorOverlay)
            Positioned.fill(child: ErrorOverlay()),
        ],
      ),
    );
  }

  Widget _buildMainContent(NumberMemoryState state, Color primary) {
    switch (state.phase) {
      case NumberMemoryPhase.memorize:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MEMORIZE SEQUENCE',
              style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 14, letterSpacing: 4),
            ),
            const SizedBox(height: 40),
            Text(
              state.targetNumber,
              style: GoogleFonts.orbitron(
                color: primary,
                fontSize: 64,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: state.memorizeTimeRemaining / (max(1500, 3000 - ((state.roundNumber - 1) ~/ 3) * 200)),
                backgroundColor: Colors.white10,
                color: primary,
              ),
            ),
          ],
        );
      case NumberMemoryPhase.recall:
      case NumberMemoryPhase.evaluation:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'INPUT SEQUENCE',
              style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 14, letterSpacing: 4),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: primary, width: 2)),
              ),
              child: Text(
                state.userInput.isEmpty ? '?' : state.userInput,
                style: GoogleFonts.orbitron(
                  color: state.userInput.isEmpty ? Colors.white10 : Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _NumberPad extends StatelessWidget {
  final Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;

  const _NumberPad({
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            children: [
              _buildKey('1'), _buildKey('2'), _buildKey('3'),
            ],
          ),
          Row(
            children: [
              _buildKey('4'), _buildKey('5'), _buildKey('6'),
            ],
          ),
          Row(
            children: [
              _buildKey('7'), _buildKey('8'), _buildKey('9'),
            ],
          ),
          Row(
            children: [
              _buildActionKey(Icons.backspace_outlined, onBackspace, Colors.redAccent),
              _buildKey('0'),
              _buildActionKey(Icons.check_circle_outline, onSubmit, Colors.greenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onDigit(label),
        child: Container(
          margin: const EdgeInsets.all(6),
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, VoidCallback onTap, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(6),
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}
