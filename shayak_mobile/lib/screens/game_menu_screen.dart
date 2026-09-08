import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'clock_canvas_screen.dart';

/// ============================================================================
/// SHAYAK-AI: Cognitive Activities & Games Menu Screen
/// Large visual cards with regional cultural resonance designed specifically
/// for elderly patients. Minimum 56x56 touch targets with prominent labels.
/// ============================================================================
class GameMenuScreen extends StatelessWidget {
  const GameMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavy,
        elevation: 0,
        title: Text(
          'Daily Activities',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // Guidance Banner
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: AppTheme.cardNavy,
                borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
                border: Border.all(color: AppTheme.cardNavyBorder, width: 2.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_esports, color: AppTheme.warmAmber, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brain & Hand Exercises',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.warmAmber,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose an exercise to keep your mind sharp and hands steady.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Card 1: Clock Drawing Test (Navigates to ClockCanvasScreen)
            _buildActivityCard(
              context: context,
              title: 'Clock Drawing Test',
              subtitle: 'Draw numbers and clock hands on screen. Assesses planning and fine motor tremor.',
              badgeText: 'CLINICAL CORE',
              badgeColor: AppTheme.warmAmber,
              icon: Icons.access_time_filled,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ClockCanvasScreen()),
                );
              },
            ),

            const SizedBox(height: 16),

            // Card 2: Memory Recall (Pairs & Symbols)
            _buildActivityCard(
              context: context,
              title: 'Memory Recall',
              subtitle: 'Match familiar regional household items and cultural symbols in pairs.',
              badgeText: 'SHORT-TERM MEMORY',
              badgeColor: AppTheme.vibrantCyan,
              icon: Icons.psychology,
              onTap: () {
                _showActivityDemoDialog(
                  context,
                  title: 'Memory Recall Exercise',
                  description:
                      'In this exercise, you flip cards to find matching pairs of traditional objects (like an earthen Diya, clay teapot, brass bell, and betel leaf).\n\nDesigned to strengthen associative memory.',
                );
              },
            ),

            const SizedBox(height: 16),

            // Card 3: Pattern Sequence (Regional Cultural Motifs)
            _buildActivityCard(
              context: context,
              title: 'Pattern Sequence',
              subtitle: 'Follow rhythmic repeating sequences of Warli, Rangoli, and Gamusa border motifs.',
              badgeText: 'ATTENTION FOCUS',
              badgeColor: AppTheme.successMint,
              icon: Icons.auto_awesome_mosaic,
              onTap: () {
                _showActivityDemoDialog(
                  context,
                  title: 'Pattern Sequence Exercise',
                  description:
                      'Tap the motifs in the order they light up. Featuring traditional Indian folk patterns that resonate with cultural familiarity, lowering cognitive anxiety.',
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardNavy,
            borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
            border: Border.all(color: AppTheme.cardNavyBorder, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Prominent High-Contrast Icon Container (> 56px)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.darkNavy,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: badgeColor, width: 2.0),
                    ),
                    child: Icon(icon, color: badgeColor, size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.softWarmCream,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 36,
                    color: AppTheme.softWarmCream,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.mutedSlate,
                ),
              ),
              const SizedBox(height: 16),
              // Prominent Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: badgeColor,
                    foregroundColor: AppTheme.darkNavy,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, size: 28),
                      const SizedBox(width: 8),
                      Text('Start $title'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityDemoDialog(BuildContext context, {required String title, required String description}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.warmAmber, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
        content: Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }
}
