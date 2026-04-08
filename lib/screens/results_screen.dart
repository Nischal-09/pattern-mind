import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/settings_provider.dart';
import '../providers/stats_provider.dart';
import '../common/gaming_ui.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final int patternsCorrect = args?['patternsCorrect'] ?? 0;
    final int errors = args?['errors'] ?? 0;
    final int totalScore = args?['totalScore'] ?? (patternsCorrect * 100);
    final int maxCombo = args?['maxCombo'] ?? 1;
    final GameMode mode = args?['mode'] ?? GameMode.classic;
    
    final int total = patternsCorrect + errors;
    final double accuracy = total == 0 ? 0 : (patternsCorrect / total * 100);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          // Background glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    primary.withOpacity(0.05),
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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   const Spacer(),
                   
                   // Heading
                   FadeInDown(
                     child: Column(
                       children: [
                         Text(
                           'MISSION COMPLETE',
                           textAlign: TextAlign.center,
                           style: GoogleFonts.orbitron(
                             fontSize: 28,
                             fontWeight: FontWeight.bold,
                             color: primary,
                             letterSpacing: 6,
                             shadows: [
                               Shadow(color: primary.withOpacity(0.5), blurRadius: 20),
                             ],
                           ),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           'DATA EXTRACTION SUCCESSFUL',
                           style: GoogleFonts.shareTechMono(
                             color: Colors.white38,
                             letterSpacing: 2,
                             fontSize: 12,
                           ),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 60),

                   // Results Card
                   FadeInUp(
                     child: NeonCard(
                       opacity: 0.6,
                       child: Column(
                         children: [
                           _CountUpHudRow(
                             label: 'PATTERNS_RESOLVED', 
                             finalValue: patternsCorrect.toDouble(), 
                             color: primary, 
                             isPercent: false,
                           ),
                           const SizedBox(height: 24),
                           _CountUpHudRow(
                             label: 'INTEGRITY_ERRORS', 
                             finalValue: errors.toDouble(), 
                             color: Colors.redAccent, 
                             isPercent: false,
                           ),
                           const Divider(height: 48, color: Colors.white10),
                            _CountUpHudRow(
                              label: 'MISSION_ACCURACY', 
                              finalValue: accuracy, 
                              color: Colors.amberAccent, 
                              isPercent: true,
                              isLarge: true,
                            ),
                            const Divider(height: 32, color: Colors.white10),
                            _CountUpHudRow(
                              label: 'TOTAL_REWARD', 
                              finalValue: totalScore.toDouble(), 
                              color: Colors.greenAccent, 
                              isPercent: false,
                            ),
                            if (mode == GameMode.speedRun) ...[
                              const SizedBox(height: 16),
                              _CountUpHudRow(
                                label: 'HIGHEST_COMBO', 
                                finalValue: maxCombo.toDouble(), 
                                color: primary, 
                                isPercent: false,
                                suffix: 'x',
                              ),
                            ],
                         ],
                       )
                     ),
                   ),
                   const Spacer(),

                   // Actions
                   FadeInUp(
                     delay: const Duration(milliseconds: 400),
                     child: Column(
                       children: [
                         NeonButton(
                           label: 'RE-INITIALIZE',
                           icon: Icons.refresh_rounded,
                           onPressed: () {
                             if (mode == GameMode.numberMemory) {
                               Navigator.of(context).pushReplacementNamed('/game_number');
                             } else {
                               Navigator.of(context).pushReplacementNamed('/game');
                             }
                           },
                         ),
                         const SizedBox(height: 16),
                         TextButton(
                           onPressed: () {
                             ref.read(gameStatsProvider.notifier).updateStats(mode, patternsCorrect, errors);
                             Navigator.of(context).pushReplacementNamed('/home');
                           },
                           child: Text(
                             'RETURN TO TERMINAL',
                             style: GoogleFonts.orbitron(
                               color: Colors.white54,
                               fontSize: 12,
                               letterSpacing: 2,
                             ),
                           ),
                         ),
                       ],
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

class _CountUpHudRow extends StatelessWidget {
  final String label;
  final double finalValue;
  final Color color;
  final bool isPercent;
  final bool isLarge;
  final String? suffix;

  const _CountUpHudRow({
     required this.label,
     required this.finalValue,
     required this.color,
     required this.isPercent,
     this.isLarge = false,
     this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
         Text(
           label, 
           style: GoogleFonts.shareTechMono(
             color: Colors.white70, 
             fontSize: isLarge ? 16 : 14,
             fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
           ),
         ),
         TweenAnimationBuilder<double>(
           tween: Tween<double>(begin: 0, end: finalValue),
           duration: const Duration(milliseconds: 1500),
           curve: Curves.easeOutQuart,
           builder: (context, value, child) {
             final valStr = isPercent ? '${value.toStringAsFixed(0)}%' : value.toInt().toString();
             final displayValue = suffix != null ? '$suffix$valStr' : valStr;
             return Text(
               displayValue,
               style: GoogleFonts.orbitron(
                 fontSize: isLarge ? 28 : 20,
                 fontWeight: FontWeight.bold,
                 color: color,
                 shadows: [
                   Shadow(color: color.withOpacity(0.5), blurRadius: 10),
                 ],
               )
             );
           }
         )
      ]
    );
  }
}
