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
    final stats = ref.watch(gameStatsProvider);
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
                          _StatHudRow(
                            label: 'PATTERNS_RESOLVED', 
                            value: '${stats.patternsCorrect}',
                            color: primary,
                          ),
                          const SizedBox(height: 12),
                          _StatHudRow(
                            label: 'CORE_ERRORS', 
                            value: '${stats.errors}',
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12),
                          _StatHudRow(
                            label: 'SYSTEM_ACCURACY', 
                            value: '${stats.accuracy.toStringAsFixed(0)}%',
                            color: Colors.amberAccent,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Difficulty Selector - Mission Parameters
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

                  const SizedBox(height: 32),

                  // Main Action Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: NeonButton(
                      label: 'INITIALIZE MISSION',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () {
                        Navigator.of(context).pushNamed('/game', arguments: difficulty);
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
