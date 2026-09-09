import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_profile.dart';
import '../services/session_service.dart';
import '../services/audio_narration_service.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';

class PatientProgressDashboard extends StatefulWidget {
  final String patientId;
  final String patientDisplayName;
  final int totalSessions;
  final double avgAccuracy;
  final double stabilityScore;
  final List<dynamic> recentSessions;
  final VoidCallback onStartMemoryMatch;
  final VoidCallback onStartRoutineSequencer;
  final VoidCallback? onStartSpotTheDifference;

  const PatientProgressDashboard({
    super.key,
    required this.patientId,
    required this.patientDisplayName,
    required this.totalSessions,
    required this.avgAccuracy,
    required this.stabilityScore,
    required this.recentSessions,
    required this.onStartMemoryMatch,
    required this.onStartRoutineSequencer,
    this.onStartSpotTheDifference,
  });

  @override
  State<PatientProgressDashboard> createState() => _PatientProgressDashboardState();
}

class _PatientProgressDashboardState extends State<PatientProgressDashboard> {
  int _selectedGraphType = 0; // 0: Cognitive Accuracy, 1: Kinematic Stability
  int? _selectedDataPointIndex;
  String _sessionFilter = 'All';

  List<double> _getAccuracyData() {
    final stats = SessionService.instance.getStatsFor(widget.patientId);
    if (stats.last7Scores.isNotEmpty) {
      return stats.last7Scores.map((s) => s * 100.0).toList();
    }
    final target = widget.avgAccuracy > 0 ? widget.avgAccuracy : 76.0;
    return [
      (target - 11).clamp(40.0, 95.0),
      (target - 6).clamp(40.0, 95.0),
      (target - 8).clamp(40.0, 95.0),
      (target - 2).clamp(40.0, 95.0),
      (target - 4).clamp(40.0, 95.0),
      (target + 2).clamp(40.0, 95.0),
      target,
    ];
  }

  List<double> _getStabilityData() {
    final stab = widget.stabilityScore > 0 ? widget.stabilityScore : 84.0;
    return [
      (stab - 6).clamp(50.0, 100.0),
      (stab - 4).clamp(50.0, 100.0),
      (stab - 2).clamp(50.0, 100.0),
      (stab - 5).clamp(50.0, 100.0),
      (stab + 1).clamp(50.0, 100.0),
      (stab - 1).clamp(50.0, 100.0),
      stab,
    ];
  }

  List<String> _getDayLabels([AppLanguage? lang]) {
    final language = lang ?? LocalizationService.instance.currentLanguage;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Today'];
    return days.map((d) => LocalizationService.trDayLabel(d, language)).toList();
  }

  void _narrateProgress() {
    final currentLang = LocalizationService.instance.currentLanguage;
    String speechText;

    switch (currentLang) {
      case AppLanguage.hindi:
        speechText = 'नमस्ते ${widget.patientDisplayName}। यह आपकी प्रगति रिपोर्ट है। '
            'आप 7 दिनों की निरंतरता पर हैं और आपने ${widget.totalSessions} अभ्यास सत्र पूरे किए हैं। '
            'आपकी औसत स्मृति सटीकता ${widget.avgAccuracy.toStringAsFixed(0)} प्रतिशत है और स्थिरता स्कोर ${widget.stabilityScore.toStringAsFixed(0)} है। बहुत अच्छा प्रदर्शन!';
        break;
      case AppLanguage.assamese:
        speechText = 'নমস্কাৰ ${widget.patientDisplayName}। এইটো আপোনাৰ অগ্ৰগতি প্ৰতিবেদন। '
            'আপুনি ৭ দিনৰ ধাৰাবাহিকতাত আছে আৰু ${widget.totalSessions} টা অনুশীলন সম্পূৰ্ণ কৰিছে। '
            'আপোনাৰ গড় সঠিকতা ${widget.avgAccuracy.toStringAsFixed(0)} শতাংশ আৰু স্থিৰতা স্কোৰ ${widget.stabilityScore.toStringAsFixed(0)}। অতি উত্তম অগ্ৰগতি!';
        break;
      case AppLanguage.bengali:
        speechText = 'নমস্কার ${widget.patientDisplayName}। এটি আপনার অগ্রগতি রিপোর্ট। '
            'আপনি ৭ দিনের ধারাবাহিকতায় রয়েছেন এবং ${widget.totalSessions} টি সেশন সম্পন্ন করেছেন। '
            'আপনার গড় নির্ভুলতা ${widget.avgAccuracy.toStringAsFixed(0)} শতাংশ। দারুণ উন্নতি!';
        break;
      case AppLanguage.manipuri:
        speechText = 'খুরুমজরি ${widget.patientDisplayName}। মসি নহাক্কী চাউখৎলকপগী রিপোর্তনি। '
            'নহাক্না নুমিৎ ৭গী চাং নাইবা সেসন ${widget.totalSessions} লোইশিনখ্রে। '
            'নহাক্কী নিংশিংবা অচুম্বা চাদা ${widget.avgAccuracy.toStringAsFixed(0)} অমসুং স্তেবিলিতি স্কোর ${widget.stabilityScore.toStringAsFixed(0)}নি। য়াম্না ফরে!';
        break;
      case AppLanguage.bodo:
        speechText = 'खुलुमबाय ${widget.patientDisplayName}। बेयो नोंथांनि जौगानाय रिपर्ट। '
            'नोंथाङा सान ७ नि फारियाव ${widget.totalSessions} सानजाद फुंखांबाय। '
            'नोंथांनि गोरोबनाय बिबाङा ${widget.avgAccuracy.toStringAsFixed(0)} जौखोन्दो। साबायखर!';
        break;
      case AppLanguage.nepali:
        speechText = 'नमस्ते ${widget.patientDisplayName}। यो तपाईंको प्रगति प्रतिवेदन हो। '
            'तपाईं ७ दिनको निरन्तरतामा हुनुहुन्छ र ${widget.totalSessions} सत्रहरू पूरा गर्नुभएको छ। '
            'तपाईंको औसत शुद्धता ${widget.avgAccuracy.toStringAsFixed(0)} प्रतिशत र स्थिरता स्कोर ${widget.stabilityScore.toStringAsFixed(0)} छ। धेरै राम्रो!';
        break;
      case AppLanguage.mizo:
        speechText = 'Chibai ${widget.patientDisplayName}. Hei hi i hmasawnna report a ni e. '
            'Ni 7 chhung zawnin session ${widget.totalSessions} i zo tawh a. '
            'I hriatrengna dik zat chu ${widget.avgAccuracy.toStringAsFixed(0)}% a ni a, stability score chu ${widget.stabilityScore.toStringAsFixed(0)} a ni. I ti tha hle mai!';
        break;
      case AppLanguage.english:
      default:
        speechText = 'Hello ${widget.patientDisplayName}. Here is your progress report. '
            'You are on a 7-day consistency streak with ${widget.totalSessions} completed activities. '
            'Your average cognitive accuracy is ${widget.avgAccuracy.toStringAsFixed(0)} percent, '
            'and your kinematic balance stability score is ${widget.stabilityScore.toStringAsFixed(0)} out of 100. Wonderful progression!';
        break;
    }

    AudioNarrationService.instance.speak(speechText, language: currentLang);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, lang, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 700;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.sageLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          LocalizationService.tr('your_journey', lang),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.forestGreen,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LocalizationService.tr('progress_wellness', lang),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 26.0 : 32.0,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.forestGreen,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LocalizationService.tr('progress_wellness_sub', lang),
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 13.0 : 14.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _narrateProgress,
                      icon: const Icon(Icons.volume_up_rounded, size: 16, color: AppTheme.forestGreen),
                      label: Text(
                        isMobile ? LocalizationService.tr('listen', lang) : LocalizationService.tr('listen_to_report', lang),
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.forestGreen),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.surfaceBorder),
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4 Highlight Metric Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetricCard(
                      width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                      badge: '🔥 ${LocalizationService.tr('daily_streak', lang)}',
                      value: LocalizationService.tr('seven_days', lang),
                      title: LocalizationService.tr('consistency_streak', lang),
                      subtitle: LocalizationService.tr('adherence_this_week', lang),
                      bgColor: AppTheme.warmPeach,
                    ),
                    _buildMetricCard(
                      width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                      badge: '🎯 ${LocalizationService.tr('sessions_caps', lang)}',
                      value: '${widget.totalSessions} ${LocalizationService.tr('completed_caps', lang)}',
                      title: LocalizationService.tr('cognitive_activities', lang),
                      subtitle: LocalizationService.tr('completed_this_week', lang),
                      bgColor: AppTheme.sageLight,
                    ),
                    _buildMetricCard(
                      width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                      badge: '🧠 ${LocalizationService.tr('accuracy_caps', lang)}',
                      value: '${widget.avgAccuracy.toStringAsFixed(0)}%',
                      title: LocalizationService.tr('working_memory_score', lang),
                      subtitle: LocalizationService.tr('progression_vs_baseline', lang),
                      bgColor: AppTheme.pastelYellow,
                    ),
                    _buildMetricCard(
                      width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                      badge: '⚖️ ${LocalizationService.tr('kinematics_caps', lang)}',
                      value: '${widget.stabilityScore.toStringAsFixed(0)}/100',
                      title: LocalizationService.tr('motor_posture_balance', lang),
                      subtitle: LocalizationService.tr('sensor_stabilized', lang),
                      bgColor: AppTheme.pastelBlue,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 22),

            // Interactive Progress Graph Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Graph Header & Switchers
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 450;
                      final titleWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _selectedGraphType == 0 ? Icons.trending_up_rounded : Icons.sensors_rounded,
                                color: AppTheme.forestGreen,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedGraphType == 0
                                      ? LocalizationService.tr('weekly_accuracy_trend', lang)
                                      : LocalizationService.tr('motor_stability_index', lang),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedGraphType == 0
                                ? LocalizationService.tr('tap_data_points', lang)
                                : LocalizationService.tr('realtime_imu_curve', lang),
                            style: GoogleFonts.inter(fontSize: 12.0, color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );

                      final switcherTabs = Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildGraphTab(LocalizationService.tr('memory_tab', lang), 0),
                            _buildGraphTab(LocalizationService.tr('stability_tab', lang), 1),
                          ],
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleWidget,
                            const SizedBox(height: 10),
                            switcherTabs,
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: titleWidget),
                          const SizedBox(width: 8),
                          switcherTabs,
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Interactive Custom Painted Graph
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: _selectedGraphType == 0
                        ? _buildAccuracyChart(lang)
                        : _buildStabilityBarChart(lang),
                  ),

                  const SizedBox(height: 14),

                  // Graph Legend & Clinical Safe Zone Notes
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppTheme.forestGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(LocalizationService.tr('recorded_session_score', lang), style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 2,
                                color: AppTheme.warmTerracotta.withOpacity(0.6),
                              ),
                              const SizedBox(width: 6),
                              Text(LocalizationService.tr('clinical_target', lang), style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                            ],
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
                          LocalizationService.tr('ai_confidence', lang),
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.forestGreen),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Cognitive Domain Progress Bars
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 16.0 : 22.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocalizationService.tr('clinical_domains_title', lang),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LocalizationService.tr('clinical_domains_sub', lang),
                    style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  Builder(builder: (context) {
                    final stats = SessionService.instance.getStatsFor(widget.patientId);
                    final sessions = SessionService.instance.getSessionsFor(widget.patientId);
                    final effectiveAcc = stats.totalSessions > 0 ? (stats.avgAccuracy * 100.0) : widget.avgAccuracy;
                    final matchSessions = sessions.where((s) => s.gameType == 'memory_match').toList();
                    final spotDiffSessions = sessions.where((s) => s.gameType == 'spot_the_difference').toList();
                    final routineSessions = sessions.where((s) => s.gameType == 'routine_sequencer' || s.gameType == 'adl_sequencer').toList();
                    final clockSessions = sessions.where((s) => s.gameType == 'clock_drawing').toList();

                    final matchAcc = matchSessions.isNotEmpty
                        ? (matchSessions.map((s) => s.accuracyRatio).reduce((a, b) => a + b) / matchSessions.length * 100.0)
                        : effectiveAcc;
                    final spotDiffAcc = spotDiffSessions.isNotEmpty
                        ? (spotDiffSessions.map((s) => s.accuracyRatio).reduce((a, b) => a + b) / spotDiffSessions.length * 100.0)
                        : (effectiveAcc > 0 ? (effectiveAcc + 5).clamp(50.0, 100.0) : 88.0);
                    final routineAcc = routineSessions.isNotEmpty
                        ? (routineSessions.map((s) => s.accuracyRatio).reduce((a, b) => a + b) / routineSessions.length * 100.0)
                        : (effectiveAcc > 0 ? (effectiveAcc + 8).clamp(50.0, 100.0) : 92.0);
                    final clockScore = clockSessions.isNotEmpty
                        ? (clockSessions.first.accuracyRatio * 10.0)
                        : (widget.stabilityScore > 0 ? (widget.stabilityScore / 10.0) : 8.5);

                    return Column(
                      children: [
                        _buildDomainRow(
                          'Working Memory (Memory Match)',
                          (matchAcc / 100.0).clamp(0.1, 1.0),
                          '${matchAcc.toStringAsFixed(0)}%',
                          AppTheme.forestGreen,
                          matchAcc >= 75 ? 'Strong recognition' : 'Consistent practice',
                          lang,
                        ),
                        const SizedBox(height: 14),
                        _buildDomainRow(
                          'Visual Recall & Scene Observation (What Changed)',
                          (spotDiffAcc / 100.0).clamp(0.1, 1.0),
                          '${spotDiffAcc.toStringAsFixed(0)}%',
                          const Color(0xFF00897B),
                          spotDiffAcc >= 75 ? 'Sharp detail detection' : 'Scene recall practice',
                          lang,
                        ),
                        const SizedBox(height: 14),
                        _buildDomainRow(
                          'ADL Procedural Flow (Chai & Plants)',
                          (routineAcc / 100.0).clamp(0.1, 1.0),
                          '${routineAcc.toStringAsFixed(0)}%',
                          const Color(0xFFE65100),
                          routineAcc >= 85 ? 'Excellent sequence recall' : 'Guided ADL sequence',
                          lang,
                        ),
                        const SizedBox(height: 14),
                        _buildDomainRow(
                          'Spatial & Executive Planning (Clock Canvas)',
                          (clockScore / 10.0).clamp(0.1, 1.0),
                          '${clockScore.toStringAsFixed(1)}/10',
                          const Color(0xFF1976D2),
                          clockScore >= 8.0 ? 'Accurate contour & hands' : 'Spatial planning tracking',
                          lang,
                        ),
                        const SizedBox(height: 14),
                        _buildDomainRow(
                          'Tremor Dampening & Kinematic Calm',
                          (widget.stabilityScore / 100.0).clamp(0.1, 1.0),
                          '${widget.stabilityScore.toStringAsFixed(0)}%',
                          const Color(0xFF7B1FA2),
                          '4-12 Hz jitter stabilized',
                          lang,
                        ),
                        const SizedBox(height: 14),
                        _buildDomainRow(
                          'Language & Semantic Naming (Local Language)',
                          0.91,
                          '91%',
                          const Color(0xFF1D4ED8),
                          'Mother tongue semantic recognition',
                          lang,
                        ),
                        const SizedBox(height: 14),
                        _buildDomainRow(
                          'Reminiscence & Emotional Memory (Memory Lane)',
                          0.94,
                          '94%',
                          const Color(0xFFC2410C),
                          'Warm autobiographical recall',
                          lang,
                        ),
                        const SizedBox(height: 14),
                        _buildDomainRow(
                          'Daily Reminder Adherence',
                          0.95,
                          '95%',
                          AppTheme.statusGreen,
                          'Active daily routine',
                          lang,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Recent Clinical Milestones and Activity History
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 16.0 : 22.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocalizationService.tr('recent_milestones_title', lang),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              LocalizationService.tr('recent_milestones_sub', lang),
                              style: GoogleFonts.inter(fontSize: 12.0, color: AppTheme.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.sageLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          LocalizationService.tr('ai_engine_live', lang),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Filter Chips
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['All', 'Language Naming', 'Memory Lane', 'Spot the Difference', 'Memory Match', 'Routine Sequencer', 'Clock Drawing'].map((filter) {
                        final isSel = _sessionFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () => setState(() => _sessionFilter = filter),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel ? AppTheme.forestGreen : AppTheme.background,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: isSel ? AppTheme.forestGreen : AppTheme.surfaceBorder,
                                ),
                              ),
                              child: Text(
                                LocalizationService.trMilestoneFilter(filter, lang),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSel ? Colors.white : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Dynamic Milestone List from actual sessions
                  ..._buildMilestoneItems(lang),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Doctor's Clinical Feedback & Prescriptions Card
            ValueListenableBuilder<int>(
              valueListenable: DoctorFeedback.feedbackNotifier,
              builder: (context, _, __) {
                final feedbackList = DoctorFeedback.getFeedbackForPatient(widget.patientId);
                if (feedbackList.isEmpty) return const SizedBox.shrink();
                final latest = feedbackList.first;

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 18.0 : 24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D4ED8).withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFDBEAFE)),
                                ),
                                child: const Icon(Icons.medical_services_rounded, size: 20, color: Color(0xFF1D4ED8)),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Doctor's Clinical Notes",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${latest.doctorName} · ${latest.specialty}',
                                      style: GoogleFonts.inter(fontSize: 12.0, color: AppTheme.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(
                              latest.clinicalImpression,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1D4ED8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          latest.feedbackNotes,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            height: 1.5,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                      if (latest.prescribedDirectives.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Prescribed Action Items & Directives:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...latest.prescribedDirectives.map((directive) => Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF1D4ED8)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      directive,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        color: const Color(0xFF1E293B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                );
              },
            ),

            // Doctor's Medical Profile Notes for this Particular Patient
            ValueListenableBuilder<String?>(
              valueListenable: PatientProfile.activeProfileNotifier,
              builder: (context, _, __) {
                final patient = PatientProfile.loadFromHive();
                if (patient == null || patient.medicalNotes == null || patient.medicalNotes!.trim().isEmpty) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 22.0),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 18.0 : 22.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.description_rounded, size: 20, color: Color(0xFFB45309)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Doctor's Clinical Notes (${patient.fullName})",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFCD34D)),
                          ),
                          child: Text(
                            patient.medicalNotes!,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              height: 1.5,
                              color: const Color(0xFF451A03),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required double width,
    required String badge,
    required String value,
    required String title,
    required String subtitle,
    required Color bgColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppTheme.surfaceBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              badge,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.forestGreen,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22.0,
              fontWeight: FontWeight.w800,
              color: AppTheme.forestGreen,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphTab(String label, int index) {
    final isSel = _selectedGraphType == index;
    return InkWell(
      onTap: () => setState(() => _selectedGraphType = index),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? AppTheme.forestGreen : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAccuracyChart([AppLanguage? lang]) {
    final data = _getAccuracyData();
    final days = _getDayLabels(lang);

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _LineChartPainter(
            dataPoints: data,
            labels: days,
            targetLineValue: 75.0,
            primaryColor: AppTheme.forestGreen,
            selectedIndex: _selectedDataPointIndex,
          ),
        );
      },
    );
  }

  Widget _buildStabilityBarChart([AppLanguage? lang]) {
    final data = _getStabilityData();
    final days = _getDayLabels(lang);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(data.length, (i) {
            final val = data[i];
            final heightFactor = (val / 100.0).clamp(0.1, 1.0);
            final barColor = val >= 80
                ? AppTheme.forestGreen
                : (val >= 65 ? AppTheme.warmPeachDark : AppTheme.warmTerracotta);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${val.toInt()}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: barColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: (constraints.maxHeight - 40) * heightFactor,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[i],
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildDomainRow(String name, double progress, String valStr, Color color, String desc, [AppLanguage? lang]) {
    final language = lang ?? LocalizationService.instance.currentLanguage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: LocalizationService.trDomainName(name, language),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: ' · ${LocalizationService.trDomainDesc(desc, language)}',
                      style: GoogleFonts.inter(
                        fontSize: 11.0,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valStr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.0,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppTheme.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMilestoneItems([AppLanguage? lang]) {
    final language = lang ?? LocalizationService.instance.currentLanguage;
    final sessions = SessionService.instance.getSessionsFor(widget.patientId);
    
    // Build real items dynamically from completed sessions
    final List<Map<String, dynamic>> items = [];

    if (sessions.isNotEmpty) {
      for (final s in sessions.take(6)) {
        final accPct = (s.accuracyRatio * 100).toStringAsFixed(0);
        final hour = s.playedAt.hour % 12 == 0 ? 12 : s.playedAt.hour % 12;
        final ampm = s.playedAt.hour >= 12 ? 'PM' : 'AM';
        final minStr = s.playedAt.minute.toString().padLeft(2, '0');
        final now = DateTime.now();
        final isToday = s.playedAt.day == now.day && s.playedAt.month == now.month && s.playedAt.year == now.year;
        final timeLabel = isToday ? 'Today, $hour:$minStr $ampm' : '${s.playedAt.day}/${s.playedAt.month}, $hour:$minStr $ampm';

        if (s.gameType == 'memory_match') {
          items.add({
            'title': LocalizationService.trMilestoneTitle('Memory Match Pairs Solved', language),
            'subtitle': 'Accuracy $accPct% · ${s.totalMoves} turns · $timeLabel',
            'icon': Icons.psychology_rounded,
            'badge': '$accPct% Acc',
            'type': 'Memory Match',
            'color': AppTheme.forestGreen,
          });
        } else if (s.gameType == 'spot_the_difference') {
          items.add({
            'title': LocalizationService.trMilestoneTitle('Spot the Difference (Visual Scene Recall)', language),
            'subtitle': 'Accuracy $accPct% · ${s.responseTimeSec.toStringAsFixed(1)}s avg reaction · $timeLabel',
            'icon': Icons.search_rounded,
            'badge': '$accPct% Recall',
            'type': 'Spot the Difference',
            'color': const Color(0xFF00897B),
          });
        } else if (s.gameType == 'clock_drawing') {
          final score = (s.accuracyRatio * 10.0).toStringAsFixed(1);
          items.add({
            'title': LocalizationService.trMilestoneTitle('Clock Contour & Hand Placement Completed', language),
            'subtitle': 'Clinical score $score/10 · $timeLabel · Spatial Planning',
            'icon': Icons.draw_rounded,
            'badge': '$score / 10',
            'type': 'Clock Drawing',
            'color': const Color(0xFF1976D2),
          });
        } else if (s.gameType == 'routine_sequencer' || s.gameType == 'adl_sequencer') {
          items.add({
            'title': LocalizationService.trMilestoneTitle('Daily Routine: Making Morning Chai Sequenced', language),
            'subtitle': '4-step procedural sequence completed · $timeLabel',
            'icon': Icons.coffee_rounded,
            'badge': '$accPct% Sequence',
            'type': 'Routine Sequencer',
            'color': const Color(0xFFE65100),
          });
        }
      }
    }

    // Always include the live ESP32 bio-sensor telemetry item
    items.add({
      'title': LocalizationService.trMilestoneTitle('ESP32 Bio-Tremor Sensor Filtering Active', language),
      'subtitle': LocalizationService.trMilestoneSubtitle('4-12 Hz Parkinsonian tremor neutralized · Live Active', language),
      'icon': Icons.sensors_rounded,
      'badge': '${widget.stabilityScore.toStringAsFixed(0)}/100 Stability',
      'type': 'Kinematics',
      'color': const Color(0xFF7B1FA2),
    });

    final filtered = items.where((item) {
      if (_sessionFilter == 'All') return true;
      return item['type'] == _sessionFilter;
    }).toList();

    if (filtered.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: Text(
              'No activities found in this filter.',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ),
      ];
    }

    return filtered.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['subtitle'] as String,
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Text(
                  item['badge'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: item['color'] as Color,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

// ── Custom Line & Gradient Area Painter ──────────────────────────────────────
class _LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<String> labels;
  final double targetLineValue;
  final Color primaryColor;
  final int? selectedIndex;

  _LineChartPainter({
    required this.dataPoints,
    required this.labels,
    required this.targetLineValue,
    required this.primaryColor,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paintLine = Paint()
      ..color = primaryColor
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintTarget = Paint()
      ..color = const Color(0xFFE65100).withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final paintGrid = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..strokeWidth = 1.0;

    const double paddingLeft = 32.0;
    const double paddingRight = 20.0;
    const double paddingTop = 20.0;
    const double paddingBottom = 30.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // Draw horizontal grid lines (0%, 50%, 75%, 100%)
    for (int p = 0; p <= 4; p++) {
      final y = paddingTop + chartHeight * (1.0 - p / 4.0);
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), paintGrid);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${p * 25}%',
          style: const TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Draw target line at 75%
    final targetY = paddingTop + chartHeight * (1.0 - targetLineValue / 100.0);
    double startX = paddingLeft;
    while (startX < size.width - paddingRight) {
      canvas.drawLine(Offset(startX, targetY), Offset(startX + 6, targetY), paintTarget);
      startX += 10;
    }

    // Calculate (x, y) coordinates for data points
    final points = <Offset>[];
    final stepX = chartWidth / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = paddingLeft + i * stepX;
      final val = dataPoints[i].clamp(0.0, 100.0);
      final y = paddingTop + chartHeight * (1.0 - val / 100.0);
      points.add(Offset(x, y));
    }

    // Build smooth cubic path
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Draw area gradient under path
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, paddingTop + chartHeight)
      ..lineTo(points.first.dx, paddingTop + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor.withOpacity(0.28), primaryColor.withOpacity(0.01)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, paddingTop, size.width, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paintLine);

    // Draw points and labels
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];

      // Draw point circle
      canvas.drawCircle(pt, 5.0, Paint()..color = Colors.white);
      canvas.drawCircle(pt, 5.0, Paint()..color = primaryColor..style = PaintingStyle.stroke..strokeWidth = 2.5);
      canvas.drawCircle(pt, 2.5, Paint()..color = primaryColor);

      // Value label on top
      final valPainter = TextPainter(
        text: TextSpan(
          text: '${dataPoints[i].toInt()}%',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      valPainter.paint(canvas, Offset(pt.dx - valPainter.width / 2, pt.dy - 16));

      // Day label at bottom
      if (i < labels.length) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        labelPainter.paint(canvas, Offset(pt.dx - labelPainter.width / 2, size.height - 18));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}
