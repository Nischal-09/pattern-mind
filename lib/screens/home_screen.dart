import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/settings_provider.dart';
import '../providers/stats_provider.dart';
import '../common/gaming_ui.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final username = user?.userMetadata?['username'] ?? 'RECRUIT';
    final difficulty = ref.watch(settingsProvider);
    final mode = ref.watch(gameModeProvider);
    final stats = ref.watch(gameStatsProvider);
    final pStats = ref.watch(persistentStatsProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          // Background subtle technical grid or gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withOpacity(0.02),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HUD Header
                  HudHeader(
                    title: 'SYSTEM TERMINAL',
                    subtitle: 'USER: ${username.toUpperCase()}',
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings_power, color: Colors.white38),
                        onPressed: () async {
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/login');
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Lifetime Persistent Stats HUD
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: Builder(
                      builder: (context) {
                        final currentStats = pStats.getFor(mode, difficulty);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatHudChip(
                              label: 'LIFETIME_BEST',
                              value: '${currentStats.personalBest}',
                              color: primary,
                            ),
                            _StatHudChip(
                              label: 'TOTAL_PATTERNS',
                              value: '${currentStats.totalPatterns}',
                              color: Colors.cyanAccent,
                            ),
                            _StatHudChip(
                              label: 'WIN_STREAK',
                              value: '${currentStats.winStreak}',
                              color: Colors.greenAccent,
                            ),
                          ],
                        );
                      }
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Last Session Stats - Tech HUD Style
                  FadeInLeft(
                    child: NeonCard(
                      opacity: 0.6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PREVIOUS MISSION REPORT',
                            style: GoogleFonts.shareTechMono(
                              fontSize: 12,
                              color: primary.withOpacity(0.7),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Builder(
                            builder: (context) {
                              final currentSession = stats[mode] ?? const GameStats();
                              return Column(
                                children: [
                                  _StatHudRow(
                                    label: mode == GameMode.numberMemory ? 'ROUNDS_RESOLVED' : 'PATTERNS_RESOLVED', 
                                    value: '${currentSession.patternsCorrect}',
                                    color: primary,
                                  ),
                                  const SizedBox(height: 12),
                                  _StatHudRow(
                                    label: 'CORE_ERRORS', 
                                    value: '${currentSession.errors}',
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(height: 12),
                                  _StatHudRow(
                                    label: 'SYSTEM_ACCURACY', 
                                    value: '${currentSession.accuracy.toStringAsFixed(0)}%',
                                    color: Colors.amberAccent,
                                  ),
                                ],
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  const SizedBox(height: 24),

                  // Difficulty Selector
                  FadeInUp(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECT MISSION DIFFICULTY',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 12,
                            color: Colors.white38,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: GameDifficulty.values.map((diff) {
                            final isSelected = difficulty == diff;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => ref.read(settingsProvider.notifier).setDifficulty(diff),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? primary : Colors.white10,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    diff.name.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.orbitron(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? primary : Colors.white38,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mode Selector
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECT OPERATION MODE',
                          style: GoogleFonts.shareTechMono(
                            fontSize: 12,
                            color: Colors.white38,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: GameMode.values.map((m) {
                            final isSelected = mode == m;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => ref.read(gameModeProvider.notifier).setMode(m),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? primary : Colors.white10,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        m.name.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.orbitron(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? primary : Colors.white38,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        m == GameMode.classic 
                                          ? '60S CHALLENGE' 
                                          : (m == GameMode.speedRun ? '20 ROUNDS BLITZ' : 'DIGIT SEQUENCE'),
                                        style: GoogleFonts.shareTechMono(
                                          fontSize: 8,
                                          color: isSelected ? primary.withOpacity(0.7) : Colors.white24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Main Action Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: NeonButton(
                      label: 'INITIALIZE MISSION',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () {
                        if (mode == GameMode.numberMemory) {
                          Navigator.of(context).pushNamed('/game_number');
                        } else {
                          Navigator.of(context).pushNamed('/game');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatHudChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatHudChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 8),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.orbitron(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                shadows: [Shadow(color: color.withOpacity(0.4), blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatHudRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatHudRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [
              Shadow(
                color: color.withOpacity(0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
