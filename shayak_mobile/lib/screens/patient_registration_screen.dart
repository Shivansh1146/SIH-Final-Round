import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';

/// Multi-step patient registration screen.
/// Steps: 1 Personal Info → 2 Language → 3 Caregiver → 4 Review & Done
class PatientRegistrationScreen extends StatefulWidget {
  final VoidCallback onRegistered;
  final ValueChanged<AppViewMode> onNavigate;

  const PatientRegistrationScreen({
    super.key,
    required this.onRegistered,
    required this.onNavigate,
  });

  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState
    extends State<PatientRegistrationScreen> with TickerProviderStateMixin {
  // Step tracker
  int _step = 0;
  final int _totalSteps = 4;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── Form controllers ──────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _caregiverNameCtrl = TextEditingController();
  final _caregiverPhoneCtrl = TextEditingController();
  final _caregiverRelationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  int _age = 65;
  Gender _gender = Gender.male;
  AppLanguage _language = AppLanguage.english;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _diagnosisCtrl.dispose();
    _caregiverNameCtrl.dispose();
    _caregiverPhoneCtrl.dispose();
    _caregiverRelationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0 && _nameCtrl.text.trim().isEmpty) {
      _showError('Please enter the patient\'s full name.');
      return;
    }
    if (_step < _totalSteps - 1) {
      _fadeCtrl.reverse().then((_) {
        setState(() => _step++);
        _fadeCtrl.forward();
      });
    }
  }

  void _prevStep() {
    if (_step > 0) {
      _fadeCtrl.reverse().then((_) {
        setState(() => _step--);
        _fadeCtrl.forward();
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.warmTerracotta,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _register() {
    final profile = PatientProfile(
      id: 'pt-${DateTime.now().millisecondsSinceEpoch}',
      fullName: _nameCtrl.text.trim(),
      age: _age,
      gender: _gender,
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      diagnosis:
          _diagnosisCtrl.text.trim().isEmpty ? null : _diagnosisCtrl.text.trim(),
      preferredLanguage: _language,
      caregiverName: _caregiverNameCtrl.text.trim().isEmpty
          ? null
          : _caregiverNameCtrl.text.trim(),
      caregiverPhone: _caregiverPhoneCtrl.text.trim().isEmpty
          ? null
          : _caregiverPhoneCtrl.text.trim(),
      caregiverRelation: _caregiverRelationCtrl.text.trim().isEmpty
          ? null
          : _caregiverRelationCtrl.text.trim(),
      medicalNotes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      registeredAt: DateTime.now(),
      linkCode: PatientProfile.generateLinkCode(),
    );

    profile.saveToHive();
    widget.onRegistered();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              currentMode: AppViewMode.landing,
              onModeChanged: widget.onNavigate,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 40,
                      vertical: 24,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 8),
                          _buildProgressBar(),
                          const SizedBox(height: 28),
                          _buildStepContent(),
                          const SizedBox(height: 28),
                          _buildNavButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final stepTitles = [
      'Personal Details',
      'Language Preference',
      'Caregiver Info',
      'Review & Confirm',
    ];
    final stepSubtitles = [
      'Tell us a little about the patient',
      'Choose the preferred interface language',
      'Who helps care for this patient? (optional)',
      'Everything looks good?',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.sageLight,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'STEP ${_step + 1} OF $_totalSteps',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w800,
              color: AppTheme.forestGreen, letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stepTitles[_step],
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26, fontWeight: FontWeight.w800,
            color: AppTheme.forestGreen, letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stepSubtitles[_step],
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(_totalSteps, (i) {
        final isActive = i <= _step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.forestGreen : AppTheme.surfaceBorder,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildPersonalStep();
      case 1:
        return _buildLanguageStep();
      case 2:
        return _buildCaregiverStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  // ── Step 1: Personal Details ───────────────────────────────────────────────

  Widget _buildPersonalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(children: [
          _label('Full Name *'),
          _textField(
            controller: _nameCtrl,
            hint: 'e.g. Ramesh Kumar',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 18),
          _label('Age'),
          _ageSelector(),
          const SizedBox(height: 18),
          _label('Gender'),
          _genderSelector(),
          const SizedBox(height: 18),
          _label('City / Town (optional)'),
          _textField(
            controller: _cityCtrl,
            hint: 'e.g. Kolkata',
            icon: Icons.location_city_rounded,
          ),
          const SizedBox(height: 18),
          _label('Diagnosis / Condition (optional)'),
          _textField(
            controller: _diagnosisCtrl,
            hint: 'e.g. Mild Cognitive Impairment',
            icon: Icons.medical_information_rounded,
          ),
        ]),
      ],
    );
  }

  Widget _ageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.cake_rounded, color: AppTheme.forestGreen, size: 20),
          const SizedBox(width: 12),
          Text(
            '$_age years',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _circleBtn(Icons.remove_rounded, () {
                if (_age > 18) setState(() => _age--);
              }),
              const SizedBox(width: 8),
              _circleBtn(Icons.add_rounded, () {
                if (_age < 120) setState(() => _age++);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 34, height: 34,
        decoration: const BoxDecoration(
          color: AppTheme.sageLight, shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppTheme.forestGreen),
      ),
    );
  }

  Widget _genderSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Gender.values.map((g) {
        final sel = g == _gender;
        return InkWell(
          onTap: () => setState(() => _gender = g),
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? AppTheme.forestGreen : Colors.white,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: sel ? AppTheme.forestGreen : AppTheme.surfaceBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(g.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  g.displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Step 2: Language ───────────────────────────────────────────────────────

  Widget _buildLanguageStep() {
    return _sectionCard(children: [
      Text(
        'Select preferred language for the patient\'s interface.',
        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
      ),
      const SizedBox(height: 16),
      ...AppLanguage.values.map((lang) {
        final sel = lang == _language;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _language = lang),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: sel ? AppTheme.sageLight : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: sel ? AppTheme.forestGreen : AppTheme.surfaceBorder,
                  width: sel ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(lang.flag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      lang.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: sel ? AppTheme.forestGreen : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (sel)
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.forestGreen, size: 22),
                ],
              ),
            ),
          ),
        );
      }),
    ]);
  }

  // ── Step 3: Caregiver ──────────────────────────────────────────────────────

  Widget _buildCaregiverStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.warmPeach,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.warmPeachDark),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.warmTerracotta, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Caregiver details are optional. You can add them later from the patient home screen.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.warmTerracotta, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(children: [
          _label('Caregiver Name'),
          _textField(
            controller: _caregiverNameCtrl,
            hint: 'e.g. Anita Sharma',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          _label('Phone Number'),
          _textField(
            controller: _caregiverPhoneCtrl,
            hint: 'e.g. +91 98765 43210',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
          ),
          const SizedBox(height: 16),
          _label('Relation to Patient'),
          _textField(
            controller: _caregiverRelationCtrl,
            hint: 'e.g. Daughter, Nurse, Spouse',
            icon: Icons.favorite_border_rounded,
          ),
          const SizedBox(height: 16),
          _label('Medical Notes (optional)'),
          _textField(
            controller: _notesCtrl,
            hint: 'Any allergies, special conditions, or care notes…',
            icon: Icons.notes_rounded,
            maxLines: 3,
          ),
        ]),
      ],
    );
  }

  // ── Step 4: Review ─────────────────────────────────────────────────────────

  Widget _buildReviewStep() {
    return Column(
      children: [
        // Success icon
        Center(
          child: Container(
            width: 70, height: 70,
            decoration: const BoxDecoration(
              color: AppTheme.sageLight, shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🌿', style: TextStyle(fontSize: 36)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _reviewCard('👤 Personal Details', [
          _reviewRow('Name', _nameCtrl.text.trim().isEmpty ? '—' : _nameCtrl.text.trim()),
          _reviewRow('Age', '$_age years'),
          _reviewRow('Gender', _gender.displayName),
          if (_cityCtrl.text.trim().isNotEmpty)
            _reviewRow('City', _cityCtrl.text.trim()),
          if (_diagnosisCtrl.text.trim().isNotEmpty)
            _reviewRow('Diagnosis', _diagnosisCtrl.text.trim()),
        ]),
        const SizedBox(height: 12),
        _reviewCard('🌐 Language', [
          _reviewRow('Preferred Language',
              '${_language.flag}  ${_language.displayName}'),
        ]),
        if (_caregiverNameCtrl.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _reviewCard('❤️ Caregiver', [
            _reviewRow('Name', _caregiverNameCtrl.text.trim()),
            if (_caregiverPhoneCtrl.text.trim().isNotEmpty)
              _reviewRow('Phone', _caregiverPhoneCtrl.text.trim()),
            if (_caregiverRelationCtrl.text.trim().isNotEmpty)
              _reviewRow('Relation', _caregiverRelationCtrl.text.trim()),
          ]),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.sageLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.sageBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppTheme.forestGreen, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'All data is stored privately on this device. Nothing is shared without your consent.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.forestGreen, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewCard(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Nav Buttons ────────────────────────────────────────────────────────────

  Widget _buildNavButtons() {
    final isLast = _step == _totalSteps - 1;
    return Row(
      children: [
        if (_step > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
              ),
              child: Text(
                'Back',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        if (_step > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isLast ? _register : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isLast ? AppTheme.warmTerracotta : AppTheme.forestGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLast ? 'Register Patient 🌿' : 'Continue',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w800,
                  ),
                ),
                if (!isLast) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15, fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight),
        prefixIcon: Icon(icon, color: AppTheme.forestGreen, size: 20),
        filled: true,
        fillColor: AppTheme.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.forestGreen, width: 2),
        ),
      ),
    );
  }
}
