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

  void _onTabSelected(int idx) {
    setState(() => _sidebarIndex = idx);
    if (idx == 1 && _aiEvaluationData == null) {
      _fetchAiDecisions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

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

            // Main Content Area
            Expanded(
              child: isMobile
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: _sidebarIndex == 1
                          ? _buildAiDecisionsView(isMobile: true)
                          : _buildCaregiverOverview(context, isMobile: true),
                    )
                  : Row(
                      children: [
                        AppSidebar(
                          isCaregiver: true,
                          selectedIndex: _sidebarIndex,
                          onSelectIndex: _onTabSelected,
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
                                child: _sidebarIndex == 1
                                    ? _buildAiDecisionsView(isMobile: false)
                                    : _buildCaregiverOverview(context, isMobile: false),
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
      bottomNavigationBar: isMobile
          ? Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.surfaceBorder, width: 1.0)),
              ),
              child: BottomNavigationBar(
                currentIndex: _sidebarIndex,
                onTap: _onTabSelected,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: AppTheme.forestGreen,
                unselectedItemColor: AppTheme.textSecondary,
                selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_outlined),
                    activeIcon: Icon(Icons.grid_view_rounded),
                    label: 'Overview',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.auto_awesome_outlined),
                    activeIcon: Icon(Icons.auto_awesome_rounded),
                    label: 'AI decisions',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.psychology_outlined),
                    activeIcon: Icon(Icons.psychology_rounded),
                    label: 'Reminders',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildCaregiverOverview(BuildContext context, {required bool isMobile}) {
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
                      const Icon(Icons.favorite_border_rounded, size: 13, color: AppTheme.forestGreen),
                      const SizedBox(width: 5),
                      Text(
                        'Caregiver workspace',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 11.0 : 12.0,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Good afternoon',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 26.0 : 34.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'A clear view of support, without clinical assumptions.',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 12.5 : 14.5,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Dropdown & Sync Button
            if (!isMobile) ...[
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
          ],
        ),

        SizedBox(height: isMobile ? 12 : 18),

        // Status Sync Banner
        Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 10),
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
              Expanded(
                child: Text(
                  'Local data · last synced 14 Mar, 5:35 pm',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 11.5 : 12.0,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'DEMO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textLight,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isMobile ? 12 : 18),

        // Selected Patient Card
        Container(
          padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: AppTheme.sageLight.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: AppTheme.sageBorder),
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 42 : 48,
                height: isMobile ? 42 : 48,
                decoration: const BoxDecoration(
                  color: AppTheme.forestGreen,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'RK',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 14.0 : 16.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECTED PATIENT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forestGreen,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ramesh Kumar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 16.0 : 18.0,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Age 68 · Anita Kumar · English',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11.5 : 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
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
                      Text('Last activity', style: GoogleFonts.inter(fontSize: 10.5, color: AppTheme.textLight)),
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

        SizedBox(height: isMobile ? 12 : 18),

        // 4 Stat Metric Cards Grid
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 1.3 : 1.4,
          children: [
            _buildStatCard(
              title: 'GAMES COMPLETED',
              value: '13',
              subtitle: 'Recent sessions',
              badgeIcon: Icons.check_circle_outline_rounded,
              badgeColor: AppTheme.statusGreen,
              badgeBg: AppTheme.sageLight,
              isMobile: isMobile,
            ),
            _buildStatCard(
              title: 'AVERAGE ACCURACY',
              value: '76%',
              subtitle: 'Gameplay score',
              badgeIcon: Icons.north_east_rounded,
              badgeColor: AppTheme.warmTerracotta,
              badgeBg: AppTheme.warmPeach,
              isMobile: isMobile,
            ),
            _buildStatCard(
              title: 'AVG RESPONSE',
              value: '4.3s',
              subtitle: 'Per interaction',
              badgeIcon: Icons.access_time_rounded,
              badgeColor: AppTheme.warmOchre,
              badgeBg: AppTheme.pastelYellow,
              isMobile: isMobile,
            ),
            _buildStatCard(
              title: 'DIFFICULTY',
              value: 'Level 2',
              subtitle: 'Adaptive tier',
              badgeIcon: Icons.psychology_outlined,
              badgeColor: AppTheme.forestGreen,
              badgeBg: AppTheme.pastelBlue,
              isMobile: isMobile,
            ),
          ],
        ),

        SizedBox(height: isMobile ? 14 : 20),

        // Lower Dashboard: 7-Session Performance & Support Notes
        if (isMobile) ...[
          _buildCognitivePerformanceCard(isMobile: true),
          const SizedBox(height: 14),
          _buildSupportNotesCard(),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _buildCognitivePerformanceCard(isMobile: false)),
              const SizedBox(width: 18),
              Expanded(flex: 4, child: _buildSupportNotesCard()),
            ],
          ),
        ],
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
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 18.0),
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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 9.0 : 10.0,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(badgeIcon, size: 12, color: badgeColor),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 22.0 : 26.0,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 10.5 : 11.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCognitivePerformanceCard({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 22.0),
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
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Activity performance',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 14.5 : 16.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.sageLight,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Non-medical',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.forestGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildChartBar('S1', 0.65, '65%'),
                _buildChartBar('S2', 0.70, '70%'),
                _buildChartBar('S3', 0.68, '68%'),
                _buildChartBar('S4', 0.74, '74%'),
                _buildChartBar('S5', 0.78, '78%'),
                _buildChartBar('S6', 0.75, '75%'),
                _buildChartBar('S7', 0.82, '82%', isCurrent: true),
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
            fontSize: 9.5,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? AppTheme.forestGreen : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 18,
          height: 60 * pct,
          decoration: BoxDecoration(
            color: isCurrent ? AppTheme.forestGreen : AppTheme.sageLight,
            borderRadius: BorderRadius.circular(5),
            border: isCurrent ? null : Border.all(color: AppTheme.sageBorder),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: GoogleFonts.inter(fontSize: 9.5, color: AppTheme.textLight)),
      ],
    );
  }

  Widget _buildSupportNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppTheme.pastelPink,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.notifications_none_rounded, size: 15, color: AppTheme.warmTerracotta),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Support notes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildNoteItem('37s that Ramesh completed his session today.'),
          const SizedBox(height: 8),
          _buildNoteItem('Smooth motor interaction during memory matching.'),
          const SizedBox(height: 8),
          _buildNoteItem('Consistent morning routine maintained.'),
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
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppTheme.forestGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            note,
            style: GoogleFonts.inter(fontSize: 12.0, color: AppTheme.textSecondary, height: 1.35),
          ),
        ),
      ],
    );
  }

  Widget _buildAiDecisionsView({required bool isMobile}) {
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
          'AI Decision Analytics & SHAP',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.forestGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time kinematic fusion & TreeExplainer local feature attributions.',
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),

        // Result Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: category == 'Normal Cognition' ? AppTheme.sageLight : AppTheme.warmPeach,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: category == 'Normal Cognition' ? AppTheme.forestGreen : AppTheme.warmTerracotta,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Risk: ${(riskScore * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Top Explainability Drivers (SHAP Waterfall)',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 10),

        ...shaps.map((s) {
          final name = s['display_name'] ?? s['feature'] ?? 'Feature';
          final val = s['patient_value']?.toString() ?? '';
          final shapVal = (s['shap_value'] as num?)?.toDouble() ?? 0.0;
          final dir = s['direction'] ?? 'reduces_risk';
          final isProtective = dir == 'reduces_risk';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                Icon(
                  isProtective ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 15,
                  color: isProtective ? AppTheme.forestGreen : AppTheme.warmTerracotta,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$name ($val)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  'SHAP: ${shapVal.toStringAsFixed(4)}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isProtective ? AppTheme.forestGreen : AppTheme.warmTerracotta,
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        Text(
          'Caregiver Guidance Recommendations',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        ...recommendations.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: _buildNoteItem(r.toString()),
            )),
      ],
    );
  }
}
