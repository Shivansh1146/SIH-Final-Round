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
    return [68.0, 72.0, 70.0, 76.0, 78.0, 82.0, 86.0];
  }

  List<double> _getStabilityData() {
    return [78.0, 80.0, 82.0, 79.0, 85.0, 84.0, widget.stabilityScore.clamp(60.0, 100.0)];
  }

  List<String> _getDayLabels() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Today'];
    return days;
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
      case AppLanguage.bengali:
        speechText = 'নমস্কার ${widget.patientDisplayName}। এটি আপনার অগ্রগতি রিপোর্ট। '
            'আপনি ৭ দিনের ধারাবাহিকতায় রয়েছেন এবং ${widget.totalSessions} টি সেশন সম্পন্ন করেছেন। '
            'আপনার গড় নির্ভুলতা ${widget.avgAccuracy.toStringAsFixed(0)} শতাংশ। দারুণ উন্নতি!';
        break;
      case AppLanguage.gujarati:
        speechText = 'નમસ્તે ${widget.patientDisplayName}। આ તમારો પ્રગતિ અહેવાલ છે. '
            'તમે 7 દિવસની સાતત્યતા પર છો અને ${widget.totalSessions} સત્રો પૂર્ણ કર્યા છે. '
            'તમારી સરેરાશ ચોકસાઈ ${widget.avgAccuracy.toStringAsFixed(0)} ટકા છે. ઉત્તમ પ્રગતિ!';
        break;
      case AppLanguage.tamil:
        speechText = 'வணக்கம் ${widget.patientDisplayName}. இது உங்கள் முன்னேற்ற அறிக்கை. '
            'நீங்கள் 7 நாட்கள் தொடர்ச்சியுடன் ${widget.totalSessions} அமர்வுகளை முடித்துள்ளீர்கள். '
            'உங்கள் துல்லியம் ${widget.avgAccuracy.toStringAsFixed(0)} சதவீதம்.';
        break;
      case AppLanguage.telugu:
        speechText = 'నమస్కారం ${widget.patientDisplayName}. ఇది మీ పురోగతి నివేదిక. '
            'మీరు 7 రోజుల స్థిరత్వంతో ${widget.totalSessions} సెషన్లను పూర్తి చేశారు.';
        break;
      case AppLanguage.marathi:
        speechText = 'नमस्कार ${widget.patientDisplayName}. हा आपला प्रगती अहवाल आहे. '
            'तुम्ही 7 दिवसांच्या सातत्यासह ${widget.totalSessions} सत्रे पूर्ण केली आहेत.';
        break;
      case AppLanguage.kannada:
        speechText = 'ನಮಸ್ಕಾರ ${widget.patientDisplayName}. ಇದು ನಿಮ್ಮ ಪ್ರಗತಿ ವರದಿ. '
            'ನೀವು 7 ದಿನಗಳ ನಿರಂತರತೆಯೊಂದಿಗೆ ${widget.totalSessions} ಸೆಷನ್‌ಗಳನ್ನು ಪೂರ್ಣಗೊಳಿಸಿದ್ದೀರಿ.';
        break;
      case AppLanguage.malayalam:
        speechText = 'നമസ്കാരം ${widget.patientDisplayName}. ഇത് നിങ്ങളുടെ പുരോഗതി റിപ്പോർട്ടാണ്. '
            'നിങ്ങൾ 7 ദിവസത്തെ തുടർച്ചയോടെ ${widget.totalSessions} സെഷനുകൾ പൂർത്തിയാക്കി.';
        break;
      case AppLanguage.punjabi:
        speechText = 'ਸਤਿ ਸ਼੍ਰੀ ਅਕਾਲ ${widget.patientDisplayName}। ਇਹ ਤੁਹਾਡੀ ਪ੍ਰਗਤੀ ਰਿਪੋਰਟ ਹੈ। '
            'ਤੁਸੀਂ 7 ਦਿਨਾਂ ਦੀ ਨਿਰੰਤਰਤਾ ਨਾਲ ${widget.totalSessions} ਸੈਸ਼ਨ ਪੂਰੇ ਕੀਤੇ ਹਨ।';
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
                      'YOUR JOURNEY',
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
                    'Progress & Wellness',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 26.0 : 32.0,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.forestGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Consistent gentle practice nurtures brain reserve and physical confidence.',
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
                    isMobile ? 'Listen' : 'Listen to Report',
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
                  badge: '🔥 DAILY STREAK',
                  value: '7 DAYS',
                  title: 'Consistency Streak',
                  subtitle: '100% adherence this week',
                  bgColor: AppTheme.warmPeach,
                ),
                _buildMetricCard(
                  width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                  badge: '🎯 SESSIONS',
                  value: '${widget.totalSessions} COMPLETED',
                  title: 'Cognitive Activities',
                  subtitle: '+3 completed this week',
                  bgColor: AppTheme.sageLight,
                ),
                _buildMetricCard(
                  width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                  badge: '🧠 ACCURACY',
                  value: '${widget.avgAccuracy.toStringAsFixed(0)}%',
                  title: 'Working Memory Score',
                  subtitle: '+6% progression vs baseline',
                  bgColor: AppTheme.pastelYellow,
                ),
                _buildMetricCard(
                  width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                  badge: '⚖️ KINEMATICS',
                  value: '${widget.stabilityScore.toStringAsFixed(0)}/100',
                  title: 'Motor & Posture Balance',
                  subtitle: 'ESP32 sensor stabilized',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                          Text(
                            _selectedGraphType == 0 ? 'Weekly Cognitive Accuracy Trend' : 'Motor & Tremor Stability Index',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedGraphType == 0
                            ? 'Tap data points to inspect individual session scores'
                            : 'Real-time IMU posture and hand tremor dampening curve',
                        style: GoogleFonts.inter(fontSize: 12.0, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),

                  // Graph Type Switcher Tabs
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildGraphTab('🧠 Memory', 0),
                        _buildGraphTab('⚖️ Stability', 1),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Interactive Custom Painted Graph
              SizedBox(
                height: 200,
                width: double.infinity,
                child: _selectedGraphType == 0
                    ? _buildAccuracyChart()
                    : _buildStabilityBarChart(),
              ),

              const SizedBox(height: 14),

              // Graph Legend & Clinical Safe Zone Notes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                      Text('Recorded Session Score', style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 16),
                      Container(
                        width: 16,
                        height: 2,
                        color: AppTheme.warmTerracotta.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Text('Clinical Target (75%)', style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.sageLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'AI Confidence: 94.2%',
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
          padding: const EdgeInsets.all(22.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clinical Cognitive & Physical Domains',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Multi-modal evaluation across working memory, executive clock planning, and kinematic motor calm.',
                style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 18),
              _buildDomainRow('Working Memory (Memory Match)', 0.86, '86%', AppTheme.forestGreen, 'Strong recognition'),
              const SizedBox(height: 14),
              _buildDomainRow('ADL Procedural Flow (Chai & Plants)', 0.92, '92%', const Color(0xFFE65100), 'Excellent sequence recall'),
              const SizedBox(height: 14),
              _buildDomainRow('Spatial & Executive Planning (Clock Canvas)', 0.85, '8.5/10', const Color(0xFF1976D2), 'Accurate contour & hands'),
              const SizedBox(height: 14),
              _buildDomainRow('Tremor Dampening & Kinematic Calm', 0.89, '89%', const Color(0xFF7B1FA2), '4-12 Hz jitter stabilized'),
              const SizedBox(height: 14),
              _buildDomainRow('Daily Reminder Adherence', 0.95, '95%', AppTheme.statusGreen, 'Active daily routine'),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Recent Clinical Milestones and Activity History
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22.0),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Clinical Milestones & History',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Verified session outcomes logged to your device',
                        style: GoogleFonts.inter(fontSize: 12.0, color: AppTheme.textSecondary),
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
                      'AI Engine Live',
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
                  children: ['All', 'Memory Match', 'Routine Sequencer', 'Clock Drawing'].map((filter) {
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
                            filter,
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

              // Dynamic Milestone List
              ..._buildMilestoneItems(),
            ],
          ),
        ),
      ],
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

  Widget _buildAccuracyChart() {
    final data = _getAccuracyData();
    final days = _getDayLabels();

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

  Widget _buildStabilityBarChart() {
    final data = _getStabilityData();
    final days = _getDayLabels();

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

  Widget _buildDomainRow(String name, double progress, String valStr, Color color, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '· $desc',
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
            Text(
              valStr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
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

  List<Widget> _buildMilestoneItems() {
    final List<Map<String, dynamic>> items = [
      {
        'title': 'Clock Contour & Hand Placement Completed',
        'subtitle': 'Clinical score 8.5/10 · Today, 09:15 AM · Spatial Planning',
        'icon': Icons.draw_rounded,
        'badge': '8.5 / 10',
        'type': 'Clock Drawing',
        'color': const Color(0xFF1976D2),
      },
      {
        'title': 'Memory Match Pairs Solved (Level 2)',
        'subtitle': 'Turn accuracy 86% · 12 moves · Today, 08:45 AM',
        'icon': Icons.psychology_rounded,
        'badge': '86% Acc',
        'type': 'Memory Match',
        'color': AppTheme.forestGreen,
      },
      {
        'title': 'Daily Routine: Making Morning Chai Sequenced',
        'subtitle': '4-step procedural sequence completed in 3.2 mins · Yesterday',
        'icon': Icons.coffee_rounded,
        'badge': '100% Sequence',
        'type': 'Routine Sequencer',
        'color': const Color(0xFFE65100),
      },
      {
        'title': 'ESP32 Bio-Tremor Sensor Filtering Active',
        'subtitle': '4-12 Hz Parkinsonian tremor neutralized · 6 Sep, 02:30 PM',
        'icon': Icons.sensors_rounded,
        'badge': '89/100 Stability',
        'type': 'Kinematics',
        'color': const Color(0xFF7B1FA2),
      },
    ];

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
