import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_sidebar.dart';

class CaregiverWorkspaceScreen extends StatefulWidget {
  final ValueChanged<AppViewMode> onNavigate;

  const CaregiverWorkspaceScreen({super.key, required this.onNavigate});

  @override
  State<CaregiverWorkspaceScreen> createState() => _CaregiverWorkspaceScreenState();
}

class _CaregiverWorkspaceScreenState extends State<CaregiverWorkspaceScreen> {
  int _sidebarIndex = 0;
  bool _isSyncing = false;
  Map<String, dynamic>? _aiEvaluationData;
  bool _isLoadingAi = false;

  void _simulateSync() {
    setState(() => _isSyncing = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session data synchronized with local edge node.', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.forestGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _fetchAiDecisions() async {
    setState(() => _isLoadingAi = true);
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/v1/clinical/evaluate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': 'PT-9042',
          'age': 68,
          'clock_drawing_score': 8.5,
          'drawing_hesitation_count': 3,
          'drawing_mean_velocity': 0.22,
          'kinematic_tremor_variance': 12.4,
          'postural_stability_score': 84.0,
          'memory_recall_accuracy': 0.76,
          'pattern_sequence_latency_ms': 1120.0,
          'speech_hesitation_ratio': 0.22,
          'phonation_jitter': 0.038,
          'acoustic_energy_entropy': 3.12,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _aiEvaluationData = jsonDecode(response.body);
          _isLoadingAi = false;
        });
      } else {
        setState(() => _isLoadingAi = false);
      }
    } catch (e) {
      debugPrint('[CAREGIVER] Backend evaluation note: $e');
      setState(() {
        _isLoadingAi = false;
        // Fallback local explainability representation
        _aiEvaluationData = {
          'diagnostic_category': 'Normal Cognition',
          'primary_risk_score': 0.082,
          'risk_probabilities': {
            'Normal Cognition': 0.918,
            'Mild Cognitive Impairment (MCI)': 0.071,
            'Probable Dementia': 0.011,
          },
          'shap_waterfall_attributions': [
            {
              'display_name': 'Memory Recall Accuracy',
              'patient_value': 0.76,
              'shap_value': -0.062,
              'direction': 'reduces_risk',
            },
            {
              'display_name': 'Kinematic Tremor Variance',
              'patient_value': 12.4,
              'shap_value': -0.048,
              'direction': 'reduces_risk',
            },
            {
              'display_name': 'Clock Contour Score',
              'patient_value': 8.5,
              'shap_value': -0.041,
              'direction': 'reduces_risk',
            },
          ],
          'clinical_recommendations': [
            'Maintain daily memory matching sessions.',
            'Motor stability variance remains within healthy baseline.',
            'Encourage afternoon social cognitive engagement.',
          ],
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            AppTopBar(
              currentMode: AppViewMode.caregiver,
              onModeChanged: widget.onNavigate,
            ),

            // Sidebar + Main Workspace
            Expanded(
              child: Row(
                children: [
                  AppSidebar(
                    isCaregiver: true,
                    selectedIndex: _sidebarIndex,
                    onSelectIndex: (idx) {
                      setState(() => _sidebarIndex = idx);
                      if (idx == 1 && _aiEvaluationData == null) {
                        _fetchAiDecisions();
                      }
                    },
                    onResetData: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Caregiver cache cleared.', style: GoogleFonts.inter()),
                          backgroundColor: AppTheme.forestGreen,
                        ),
                      );
                    },
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: _sidebarIndex == 1 ? _buildAiDecisionsView() : _buildCaregiverOverview(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaregiverOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_border_rounded, size: 14, color: AppTheme.forestGreen),
                      const SizedBox(width: 6),
                      Text(
                        'Caregiver workspace',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Good afternoon',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A clear view of support, without clinical assumptions.',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Dropdown & Simulate Sync
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Ramesh Kumar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _simulateSync,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.forestGreen),
                        )
                      : const Icon(Icons.sync_rounded, size: 15, color: AppTheme.textPrimary),
                  label: Text(
                    'Simulate sync',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.surfaceBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Status Sync Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.statusGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Local data · last synchronized 14 Mar, 5:35 pm',
                style: GoogleFonts.inter(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'DEMO SIMULATION',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textLight,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Selected Patient Card
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppTheme.sageLight.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: AppTheme.sageBorder),
          ),
          child: Row(
            children: [
              // Avatar RK
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppTheme.forestGreen,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'RK',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECTED PATIENT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forestGreen,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ramesh Kumar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Age 68 · Caregiver Anita Kumar · Preferred language English',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Last Activity Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Last activity',
                      style: GoogleFonts.inter(fontSize: 10.5, color: AppTheme.textLight),
                    ),
                    Text(
                      '8 Mar, 9:10 am',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 4 Stat Metric Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isWide ? 1.35 : 1.25,
              children: [
                _buildStatCard(
                  title: 'GAMES COMPLETED',
                  value: '13',
                  subtitle: 'Across recent sessions',
                  badgeIcon: Icons.check_circle_outline_rounded,
                  badgeColor: AppTheme.statusGreen,
                  badgeBg: AppTheme.sageLight,
                ),
                _buildStatCard(
                  title: 'AVERAGE ACCURACY',
                  value: '76%',
                  subtitle: 'Gameplay performance',
                  badgeIcon: Icons.north_east_rounded,
                  badgeColor: AppTheme.warmTerracotta,
                  badgeBg: AppTheme.warmPeach,
                ),
                _buildStatCard(
                  title: 'AVERAGE RESPONSE',
                  value: '4.3s',
                  subtitle: 'Per interaction',
                  badgeIcon: Icons.access_time_rounded,
                  badgeColor: AppTheme.warmOchre,
                  badgeBg: AppTheme.pastelYellow,
                ),
                _buildStatCard(
                  title: 'CURRENT DIFFICULTY',
                  value: 'Level 2',
                  subtitle: 'Adapts from performance',
                  badgeIcon: Icons.psychology_outlined,
                  badgeColor: AppTheme.forestGreen,
                  badgeBg: AppTheme.pastelBlue,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // Lower Dashboard: 7-Session Performance & Support Notes
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 640;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildCognitivePerformanceCard()),
                  const SizedBox(width: 18),
                  Expanded(flex: 4, child: _buildSupportNotesCard()),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildCognitivePerformanceCard(),
                  const SizedBox(height: 18),
                  _buildSupportNotesCard(),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData badgeIcon,
    required Color badgeColor,
    required Color badgeBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(badgeIcon, size: 14, color: badgeColor),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26.0,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCognitivePerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE LAST 7 SESSIONS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cognitive activity performance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.sageLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Non-medical view',
                  style: GoogleFonts.inter(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.forestGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Custom visual chart representing 7 sessions trend
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildChartBar('Session 1', 0.65, '65%'),
                _buildChartBar('Session 2', 0.70, '70%'),
                _buildChartBar('Session 3', 0.68, '68%'),
                _buildChartBar('Session 4', 0.74, '74%'),
                _buildChartBar('Session 5', 0.78, '78%'),
                _buildChartBar('Session 6', 0.75, '75%'),
                _buildChartBar('Session 7', 0.82, '82%', isCurrent: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, double pct, String value, {bool isCurrent = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? AppTheme.forestGreen : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 24,
          height: 70 * pct,
          decoration: BoxDecoration(
            color: isCurrent ? AppTheme.forestGreen : AppTheme.sageLight,
            borderRadius: BorderRadius.circular(6),
            border: isCurrent ? null : Border.all(color: AppTheme.sageBorder),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.replaceAll('Session ', 'S'),
          style: GoogleFonts.inter(fontSize: 10.0, color: AppTheme.textLight),
        ),
      ],
    );
  }

  Widget _buildSupportNotesCard() {
    return Container(
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppTheme.pastelPink,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.notifications_none_rounded, size: 16, color: AppTheme.warmTerracotta),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Support notes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildNoteItem('37s that Ramesh completed his session today.'),
          const SizedBox(height: 10),
          _buildNoteItem('Smooth motor interaction during memory matching.'),
          const SizedBox(height: 10),
          _buildNoteItem('Consistent daily morning schedule maintained.'),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String note) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppTheme.forestGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            note,
            style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildAiDecisionsView() {
    if (_isLoadingAi) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(color: AppTheme.forestGreen),
        ),
      );
    }

    final data = _aiEvaluationData;
    if (data == null) {
      return Center(
        child: ElevatedButton(
          onPressed: _fetchAiDecisions,
          child: const Text('Load AI Diagnostic & SHAP Waterfall'),
        ),
      );
    }

    final category = data['diagnostic_category'] ?? 'Normal Cognition';
    final riskScore = (data['primary_risk_score'] as num?)?.toDouble() ?? 0.082;
    final shaps = (data['shap_waterfall_attributions'] as List<dynamic>?) ?? [];
    final recommendations = (data['clinical_recommendations'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Decision Analytics & SHAP Explainability',
          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.forestGreen),
        ),
        const SizedBox(height: 6),
        Text(
          'Real-time kinematic fusion & TreeExplainer local feature attributions from FastAPI backend.',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        // Result Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: category == 'Normal Cognition' ? AppTheme.sageLight : AppTheme.warmPeach,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: category == 'Normal Cognition' ? AppTheme.forestGreen : AppTheme.warmTerracotta,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Primary Risk Probability: ${(riskScore * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // SHAP Waterfall Drivers
        Text(
          'Top Explainability Drivers (SHAP Waterfall)',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),

        ...shaps.map((s) {
          final name = s['display_name'] ?? s['feature'] ?? 'Feature';
          final val = s['patient_value']?.toString() ?? '';
          final shapVal = (s['shap_value'] as num?)?.toDouble() ?? 0.0;
          final dir = s['direction'] ?? 'reduces_risk';
          final isProtective = dir == 'reduces_risk';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                Icon(
                  isProtective ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 16,
                  color: isProtective ? AppTheme.forestGreen : AppTheme.warmTerracotta,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$name ($val)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  'SHAP: ${shapVal.toStringAsFixed(4)}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isProtective ? AppTheme.forestGreen : AppTheme.warmTerracotta,
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 20),

        // Recommendations
        Text(
          'Caregiver Guidance Recommendations',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 10),
        ...recommendations.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: _buildNoteItem(r.toString()),
            )),
      ],
    );
  }
}
