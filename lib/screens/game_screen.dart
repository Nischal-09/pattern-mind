import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/settings_provider.dart';
import '../providers/game_state_provider.dart';
import '../providers/stats_provider.dart';
import '../common/gaming_ui.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameStateProvider.notifier).startGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final username = user?.userMetadata?['username'] ?? 'RECRUIT';
    final primary = Theme.of(context).colorScheme.primary;

    ref.listen(gameStateProvider, (prev, next) {
      bool isClassicEnd = next.mode == GameMode.classic && prev != null && prev.timeRemaining > 0 && next.timeRemaining == 0;
      bool isSpeedRunEnd = next.mode == GameMode.speedRun && prev != null && prev.timeRemaining != -1 && next.timeRemaining == -1;
      
      if (isClassicEnd || isSpeedRunEnd) {
        final total = next.patternsCorrect + next.errors;
        final accuracy = total == 0 ? 0.0 : (next.patternsCorrect / total * 100);
        
        ref.read(gameStatsProvider.notifier).updateStats(next.mode, next.patternsCorrect, next.errors);
        ref.read(persistentStatsProvider.notifier).recordSession(
          mode: next.mode,
          difficulty: ref.read(settingsProvider),
          patternsCorrect: next.patternsCorrect, 
          accuracy: accuracy, 
          totalScore: next.totalScore,
        );
        
        Navigator.of(context).pushReplacementNamed('/results', arguments: {
          'patternsCorrect': next.patternsCorrect,
          'errors': next.errors,
          'totalScore': next.totalScore,
          'maxCombo': next.maxCombo,
          'mode': next.mode,
        });
      }
    });

    String timeStr = '${(state.timeRemaining ~/ 60).toString().padLeft(2, '0')}:${(state.timeRemaining % 60).toString().padLeft(2, '0')}';
    Color timerColor = primary;
    if (state.timeRemaining <= 5) {
      timerColor = const Color(0xFFFF4444);
    } else if (state.timeRemaining <= 15) {
      timerColor = Colors.orangeAccent;
    }

    Widget? labelWidget;
    if (state.currentPhase == GamePhase.memorize) {
      labelWidget = BounceInDown(
        child: Text(
          'MEMORIZING...',
          style: GoogleFonts.orbitron(
            color: timerColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      );
    } else if (state.currentPhase == GamePhase.recall) {
      labelWidget = Flash(
        child: Text(
          'RECALL ACTIVE',
          style: GoogleFonts.orbitron(
            color: primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      );
    }

    final crossAxisCount = state.gridCount == 9 ? 3 : 4;

    return Scaffold(
      body: Stack(
        children: [
          // Background subtle scanlines
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/carbon-fibre.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Technical HUD Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: NeonCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    opacity: 0.7,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username.toUpperCase(),
                              style: GoogleFonts.shareTechMono(
                                fontSize: 12,
                                color: primary.withOpacity(0.7),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SCORE: ${state.mode == GameMode.classic ? state.patternsCorrect * 100 : state.totalScore}',
                              style: GoogleFonts.orbitron(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (state.mode == GameMode.speedRun)
                          Column(
                            children: [
                              Text(
                                'COMBO',
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 10,
                                  color: primary.withOpacity(0.5),
                                ),
                              ),
                              Text(
                                'x${state.combo}',
                                style: GoogleFonts.orbitron(
                                  color: primary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        Column(
                          children: [
                            Text(
                              state.mode == GameMode.classic ? 'CORE_TIME' : 'ROUND_TIME',
                              style: GoogleFonts.shareTechMono(
                                fontSize: 10,
                                color: timerColor.withOpacity(0.5),
                              ),
                            ),
                            if (state.mode == GameMode.classic)
                              Text(
                                timeStr,
                                style: GoogleFonts.shareTechMono(
                                  color: timerColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: timerColor.withOpacity(0.5),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              )
                            else
                              SizedBox(
                                width: 80,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: state.roundTime / (max(1.5, 5.0 - (state.roundNumber - 1) * 0.2)),
                                        backgroundColor: Colors.white10,
                                        valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${state.roundTime.toStringAsFixed(1)}s',
                                      style: GoogleFonts.shareTechMono(
                                        color: timerColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ROUND',
                              style: GoogleFonts.shareTechMono(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                            Text(
                              '${state.roundNumber.toString().padLeft(2, '0')}${state.mode == GameMode.speedRun ? "/20" : ""}',
                              style: GoogleFonts.orbitron(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Status Alert Label
                SizedBox(height: 30, child: Center(child: labelWidget)),
                const SizedBox(height: 24),
                
                // Game Grid with HUD frame
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Stack(
                    children: [
                      // Decorative HUD Brackets can go here if needed
                      AspectRatio(
                        aspectRatio: 1,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.gridCount,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            return AnimatedTile(
                              index: index,
                              gameState: state,
                              onTap: () {
                                ref.read(gameStateProvider.notifier).handleTileTap(index);
                              },
                            );
                          },
                        ),
                      ),
                      if (state.showSuccessOverlay)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.2),
                                border: Border.all(color: primary, width: 2),
                              ),
                              child: const Center(
                                child: Icon(Icons.check_circle_outline, color: Colors.white, size: 48),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const Spacer(),
                
                // Bottom HUD Stats
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _BottomHudChip(
                        label: 'ERRORS', 
                        value: '${state.errors}',
                        color: Colors.redAccent,
                      ),
                      _BottomHudChip(
                        label: 'SYSTEM_STATUS', 
                        value: 'STABLE',
                        color: Colors.greenAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomHudChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BottomHudChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10),
        ),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class AnimatedTile extends StatefulWidget {
  final int index;
  final GameState gameState;
  final VoidCallback onTap;

  const AnimatedTile({super.key, required this.index, required this.gameState, required this.onTap});

  @override
  State<AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<AnimatedTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLit = false;
    bool isError = widget.gameState.wrongFeedbackIndex == widget.index;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    
    if (widget.gameState.currentPhase == GamePhase.memorize) {
      isLit = widget.gameState.activePattern.contains(widget.index);
    } else if (widget.gameState.currentPhase == GamePhase.recall || widget.gameState.currentPhase == GamePhase.evaluation) {
      isLit = widget.gameState.userSelection.contains(widget.index);
    }

    Color color = Colors.white.withOpacity(0.05);
    BoxDecoration decoration = BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
    );

    if (isError) {
      decoration = decoration.copyWith(
        color: Colors.redAccent.withOpacity(0.6),
        border: Border.all(color: Colors.redAccent, width: 2),
      );
    } else if (isLit) {
      decoration = decoration.copyWith(
        color: primary.withOpacity(0.8),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.6),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      );
    }

    Widget content = Container(
      decoration: decoration,
      child: isLit && !isError 
        ? Center(child: Icon(Icons.bolt, color: Colors.white.withOpacity(0.5), size: 16))
        : null,
    );

    // Apply continuous subtle pulse via animate_do when lit
    if (isLit && !isError) {
      content = Pulse(duration: const Duration(seconds: 1), child: content);
    }

    return GestureDetector(
      onTapDown: (_) {
        if (widget.gameState.currentPhase == GamePhase.recall) {
           _controller.forward();
        }
      },
      onTapUp: (_) {
         _controller.reverse();
         if (widget.gameState.currentPhase == GamePhase.recall) {
           widget.onTap();
         }
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: content,
      ),
    );
  }
}
