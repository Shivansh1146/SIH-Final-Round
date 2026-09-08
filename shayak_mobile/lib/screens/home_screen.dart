import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'clock_canvas_screen.dart';

/// ============================================================================
/// SHAYAK-AI: Accessible Elderly Home Dashboard
/// Dynamic daytime greeting, single-tap primary CTA ("Start Daily Assessment"),
/// daily cognitive status snapshot, and tactile medication/exercise reminders.
/// ============================================================================
class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToGames;

  const HomeScreen({super.key, this.onNavigateToGames});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _morningMedsTaken = true;
  bool _eveningMedsTaken = false;
  bool _fingerStretchesDone = true;

  String _getDynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning, Dadu';
    } else if (hour < 17) {
      return 'Good Afternoon, Dadu';
    } else {
      return 'Good Evening, Dadu';
    }
  }

  String _getDateSubtitle() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dynamic Daytime Greeting Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDateSubtitle(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.warmAmber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDynamicGreeting(),
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready for today’s gentle 5-minute health check?',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.softWarmCream,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. PRIMARY HERO CTA CARD ("Start Daily Assessment")
              // High-visibility, tactile, single-tap entrypoint
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ClockCanvasScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(22.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3E62), Color(0xFF0F2B48)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22.0),
                      border: Border.all(color: AppTheme.warmAmber, width: 3.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppTheme.warmAmber,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.softWarmCream, width: 2.0),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: AppTheme.darkNavy,
                                size: 48,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daily Assessment',
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      color: AppTheme.softWarmCream,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Clock drawing & motor stability check',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.mutedSlate,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ClockCanvasScreen()),
                              );
                            },
                            icon: const Icon(Icons.touch_app, size: 30),
                            label: const Text('Start Daily Assessment Now'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. DAILY COGNITIVE & STABILIZATION STATUS CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: AppTheme.cardNavy,
                  borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
                  border: Border.all(color: AppTheme.cardNavyBorder, width: 2.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded, color: AppTheme.alertCoral, size: 32),
                        const SizedBox(width: 12),
                        Text(
                          'Today’s Wellness Summary',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusMetric(
                            'Tremor Stability',
                            'Optimal (94%)',
                            Icons.speed,
                            AppTheme.successMint,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatusMetric(
                            'Focus Index',
                            'Clear & Calm',
                            Icons.psychology,
                            AppTheme.warmAmber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. MEDICATION & EXERCISE REMINDERS (Large Checkable Tiles)
              Text(
                'Reminders for Today',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),

              _buildReminderTile(
                title: 'Morning Blood Pressure & Heart Medication',
                time: '8:00 AM',
                isCompleted: _morningMedsTaken,
                icon: Icons.medication_rounded,
                onToggle: () {
                  setState(() => _morningMedsTaken = !_morningMedsTaken);
                },
              ),

              const SizedBox(height: 10),

              _buildReminderTile(
                title: 'Finger Tremor & Coordination Stretches',
                time: '11:00 AM',
                isCompleted: _fingerStretchesDone,
                icon: Icons.fitness_center_rounded,
                onToggle: () {
                  setState(() => _fingerStretchesDone = !_fingerStretchesDone);
                },
              ),

              const SizedBox(height: 10),

              _buildReminderTile(
                title: 'Evening Memory & Vitamin Supplement',
                time: '8:00 PM',
                isCompleted: _eveningMedsTaken,
                icon: Icons.nightlight_round,
                onToggle: () {
                  setState(() => _eveningMedsTaken = !_eveningMedsTaken);
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppTheme.darkNavy,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: AppTheme.mutedSlate, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTile({
    required String title,
    required String time,
    required bool isCompleted,
    required IconData icon,
    required VoidCallback onToggle,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: AppTheme.cardNavy,
            borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
            border: Border.all(
              color: isCompleted ? AppTheme.successMint : AppTheme.cardNavyBorder,
              width: 2.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.successMint.withOpacity(0.2) : AppTheme.darkNavy,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? AppTheme.successMint : AppTheme.warmAmber,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isCompleted ? AppTheme.successMint : AppTheme.warmAmber,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? AppTheme.mutedSlate : AppTheme.softWarmCream,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppTheme.mutedSlate,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Accessible checkbox target >= 56x56
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                child: Icon(
                  isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isCompleted ? AppTheme.successMint : AppTheme.softWarmCream,
                  size: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
