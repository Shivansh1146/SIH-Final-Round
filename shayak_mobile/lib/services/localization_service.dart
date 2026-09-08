import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/patient_profile.dart';
import '../theme/app_theme.dart';
import 'audio_narration_service.dart';

class LocalizationService {
  static final LocalizationService instance = LocalizationService._internal();
  LocalizationService._internal();

  static final ValueNotifier<AppLanguage> languageNotifier =
      ValueNotifier<AppLanguage>(AppLanguage.english);

  AppLanguage get currentLanguage => languageNotifier.value;

  void init() {
    try {
      final box = Hive.box('user_preferences');
      final savedLang = box.get('selected_app_language') as String?;
      if (savedLang != null) {
        final lang = AppLanguage.values.firstWhere(
          (e) => e.name == savedLang,
          orElse: () => AppLanguage.english,
        );
        languageNotifier.value = lang;
        return;
      }
    } catch (_) {}

    final profile = PatientProfile.loadFromHive();
    if (profile != null) {
      languageNotifier.value = profile.preferredLanguage;
    }
  }

  static void showLanguageDialog(BuildContext context) {
    final currentLang = LocalizationService.instance.currentLanguage;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Language / भाषा चुनें',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: AppLanguage.values.map((lang) {
                    final isSelected = lang == currentLang;
                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: AppTheme.sageLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: Text(lang.flag, style: const TextStyle(fontSize: 20)),
                      title: Text(
                        lang.displayName,
                        style: GoogleFonts.inter(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTheme.forestGreen : AppTheme.textPrimary,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.forestGreen) : null,
                      onTap: () {
                        LocalizationService.instance.setLanguage(lang, speakPreview: true);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void setLanguage(AppLanguage lang, {bool speakPreview = true}) {
    languageNotifier.value = lang;
    try {
      final box = Hive.box('user_preferences');
      box.put('selected_app_language', lang.name);
    } catch (_) {}

    final profile = PatientProfile.loadFromHive();
    if (profile != null) {
      profile.preferredLanguage = lang;
      profile.saveToHive();
    }

    if (speakPreview) {
      final greeting = getLanguageWelcomeSpeech(lang);
      AudioNarrationService.instance.speak(greeting, language: lang);
    }
  }

  static String getLanguageWelcomeSpeech(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hindi:
        return 'नमस्ते! सहायक में आपका स्वागत है। आपकी भाषा हिंदी चुनी गई है।';
      case AppLanguage.assamese:
        return 'নমস্কাৰ! সহায়কত আপোনাক স্বাগতম। আপোনাৰ ভাষা অসমীয়া নিৰ্বাচন কৰা হৈছে।';
      case AppLanguage.bengali:
        return 'নমস্কার! সহায়কে আপনাকে স্বাগতম। আপনার ভাষা বাংলা নির্বাচন করা হয়েছে।';
      case AppLanguage.manipuri:
        return 'খুরুমজরি! সহায়কতা তরাম্না ওকচরি। নখোয়গী লোন মৈতৈলোন্ খনখ্রে।';
      case AppLanguage.bodo:
        return 'खुलुमबाय! सहायाक-आव नोंथांखौ बरायबाय। नोंथांनि रावआ बड़ो सायखबाय।';
      case AppLanguage.nepali:
        return 'नमस्ते! सहायकमा तपाईंलाई स्वागत छ। तपाईंको भाषा नेपाली चयन गरिएको छ।';
      case AppLanguage.mizo:
        return 'Chibai! Sahayak-ah kan lo lawm a che. I tawng thlan chu Mizo a ni.';
      case AppLanguage.english:
      default:
        return 'Welcome to Sahayak AI. Interface language set to English.';
    }
  }

  static String getCaregiverCallSpeech(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hindi:
        return 'देखभालकर्ता अनीता कुमार को कॉल किया जा रहा है। कृपया प्रतीक्षा करें।';
      case AppLanguage.assamese:
        return 'কেয়াৰগিভাৰ অনিতা কুমাৰক ফোন কৰা হৈছে। অনুগ্ৰহ কৰি অপেক্ষা কৰক।';
      case AppLanguage.bengali:
        return 'কেয়ারগিভার অনিতা কুমারকে কল করা হচ্ছে। দয়া করে কিছুক্ষণ অপেক্ষা করুন।';
      case AppLanguage.manipuri:
        return 'কেয়ারগিভার অনিতা কুমারদা কোল তৌরি। চানবিদুনা মতম খরা ঙাইবিউ।';
      case AppLanguage.bodo:
        return 'सामलायगिरि अनिता कुमारनो कल खालामदों। अननानै एसे सम नेथ’।';
      case AppLanguage.nepali:
        return 'हेरचाहकर्ता अनिता कुमारलाई फोन गरिँदैछ। कृपया केही बेर पर्खनुहोस्।';
      case AppLanguage.mizo:
        return 'Enkawltu Anita Kumar kan bia mek e. Khawngaihin lo nghak lawk rawh.';
      case AppLanguage.english:
      default:
        return 'Calling Caregiver Anita Kumar. Please hold on a moment.';
    }
  }

  static String trFilter(String filter, [AppLanguage? lang]) {
    final l = lang ?? instance.currentLanguage;
    switch (filter) {
      case 'Pending':
        return tr('pending', l);
      case 'Completed':
        switch (l) {
          case AppLanguage.hindi: return 'पूर्ण';
          case AppLanguage.assamese: return 'সম্পূৰ্ণ';
          case AppLanguage.bengali: return 'সম্পন্ন';
          case AppLanguage.manipuri: return 'লোইশিনবা';
          case AppLanguage.bodo: return 'फुंखांनाय';
          case AppLanguage.nepali: return 'पूरा';
          case AppLanguage.mizo: return 'Zawh tawh';
          case AppLanguage.english: default: return 'Completed';
        }
      case 'Medicines':
        switch (l) {
          case AppLanguage.hindi: return 'दवाइयाँ';
          case AppLanguage.assamese: return 'ঔষধ';
          case AppLanguage.bengali: return 'ওষুধ';
          case AppLanguage.manipuri: return 'হিদাক';
          case AppLanguage.bodo: return 'मुलि';
          case AppLanguage.nepali: return 'औषधि';
          case AppLanguage.mizo: return 'Damdawi';
          case AppLanguage.english: default: return 'Medicines';
        }
      case 'All':
      default:
        switch (l) {
          case AppLanguage.hindi: return 'सभी';
          case AppLanguage.assamese: return 'সকলো';
          case AppLanguage.bengali: return 'সমস্ত';
          case AppLanguage.manipuri: return 'পুম্নমক';
          case AppLanguage.bodo: return 'गासैबो';
          case AppLanguage.nepali: return 'सबै';
          case AppLanguage.mizo: return 'Zawng zawng';
          case AppLanguage.english: default: return 'All';
        }
    }
  }

  static String getCaregiverVoiceGreeting(AppLanguage lang, [String patientName = 'Ramesh']) {
    switch (lang) {
      case AppLanguage.hindi:
        return 'नमस्ते $patientName जी! मैं अनीता कुमार बोल रही हूँ। मैं आपकी बात सुन रही हूँ, बताइए क्या सहायता चाहिए?';
      case AppLanguage.assamese:
        return 'নমস্কাৰ $patientName ডাঙৰীয়া! মই অনিতা কুমাৰ। মই আপোনাৰ লগত আছোঁ, আপোনাক কেনেকৈ সহায় কৰিব পাৰোঁ?';
      case AppLanguage.bengali:
        return 'নমস্কার $patientName বাবু! আমি অনিতা কুমার বলছি। আমি আপনার সাথে আছি, বলুন কীভাবে সাহায্য করতে পারি?';
      case AppLanguage.manipuri:
        return 'খুরুমজরি $patientName জী! ঐ অনিতা কুমারনি। নহাকপু করম্না মতেং পাংগদগে?';
      case AppLanguage.bodo:
        return 'खुलुमबाय $patientName! आं अनिता कुमार। आं नोंथांनि रावखौ खोनादों, नोंथांनो मा हेफाजाब नांगौ?';
      case AppLanguage.nepali:
        return 'नमस्ते $patientName जी! म अनिता कुमार बोल्दैछु। म तपाईँको साथमा छु, कसरी सहयोग गर्न सक्छु?';
      case AppLanguage.mizo:
        return 'Chibai $patientName! Anita Kumar ka ni e. I kiangah ka awm a, engtin nge ka puih theih ang che?';
      case AppLanguage.english:
      default:
        return 'Hello $patientName! This is Anita Kumar. I can hear you clearly. How can I assist you right now?';
    }
  }

  static String tr(String key, [AppLanguage? overrideLang]) {
    final lang = overrideLang ?? languageNotifier.value;
    final dict = _translations[lang] ?? _translations[AppLanguage.english]!;
    return dict[key] ?? _translations[AppLanguage.english]![key] ?? key;
  }

  static String getTimeGreeting([AppLanguage? overrideLang]) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return tr('good_morning', overrideLang);
    } else if (hour >= 12 && hour < 17) {
      return tr('good_afternoon', overrideLang);
    } else if (hour >= 17 && hour < 21) {
      return tr('good_evening', overrideLang);
    } else {
      return tr('good_night', overrideLang);
    }
  }

  static String trReminderTitle(String title, [AppLanguage? overrideLang]) {
    final t = title.toLowerCase().trim();
    if (t.contains('morning') && (t.contains('med') || t.contains('dawa') || t.contains('medicine'))) {
      return tr('rem_morning_medicine', overrideLang);
    }
    if (t.contains('hydrat') || t.contains('water') || t.contains('pani')) {
      return tr('rem_hydration', overrideLang);
    }
    if (t.contains('lunch') || t.contains('vitamin') || t.contains('meal')) {
      return tr('rem_lunch', overrideLang);
    }
    if (t.contains('memory') || t.contains('match') || t.contains('game')) {
      return tr('rem_memory_game', overrideLang);
    }
    if (t.contains('walk') || t.contains('garden') || t.contains('evening')) {
      return tr('rem_evening_walk', overrideLang);
    }
    if (t.contains('night') && (t.contains('med') || t.contains('medicine'))) {
      return tr('rem_night_medicine', overrideLang);
    }
    return title;
  }

  static String trReminderNotes(String? notes, [AppLanguage? overrideLang]) {
    if (notes == null || notes.isEmpty) return '';
    final n = notes.toLowerCase().trim();
    if (n.contains('warm water') || n.contains('breakfast')) {
      return tr('rem_morning_medicine_notes', overrideLang);
    }
    if (n.contains('glass') || n.contains('fresh water')) {
      return tr('rem_hydration_notes', overrideLang);
    }
    if (n.contains('wholesome') || n.contains('nutritious')) {
      return tr('rem_lunch_notes', overrideLang);
    }
    if (n.contains('5-minute') || n.contains('cognitive')) {
      return tr('rem_memory_game_notes', overrideLang);
    }
    if (n.contains('15-minute') || n.contains('stroll') || n.contains('fresh air')) {
      return tr('rem_evening_walk_notes', overrideLang);
    }
    if (n.contains('before going') || n.contains('bed')) {
      return tr('rem_night_medicine_notes', overrideLang);
    }
    return notes;
  }

  static String buildReminderSpokenSentence({
    required String patientName,
    required String timeStr,
    required String rawTitle,
    String? rawNotes,
    AppLanguage? overrideLang,
  }) {
    final lang = overrideLang ?? languageNotifier.value;
    final title = trReminderTitle(rawTitle, lang);
    final notes = trReminderNotes(rawNotes, lang);

    switch (lang) {
      case AppLanguage.hindi:
        return 'नमस्ते $patientName। समय $timeStr हो गया है, $title का समय है। $notes';
      case AppLanguage.assamese:
        return 'নমস্কাৰ $patientName। এতিয়া $timeStr বাজিছে, $title-ৰ সময় হৈছে। $notes';
      case AppLanguage.bengali:
        return 'নমস্কার $patientName। এখন $timeStr বাজে, $title-এর সময় হয়েছে। $notes';
      case AppLanguage.manipuri:
        return 'খুরুমজরি $patientName। মতম $timeStr তারি, $title তৌনবগী মতমনি। $notes';
      case AppLanguage.bodo:
        return 'खुलुमबाय $patientName। दा $timeStr जाबाय, $title नि समा जाबाय। $notes';
      case AppLanguage.nepali:
        return 'नमस्ते $patientName। अहिले $timeStr बज्यो, $title को समय भएको छ। $notes';
      case AppLanguage.mizo:
        return 'Chibai $patientName. Dar $timeStr a ri ta, $title a hun e. $notes';
      case AppLanguage.english:
      default:
        return 'Hello $patientName. It is $timeStr, time for $title. $notes';
    }
  }

  static String buildScheduleSpokenSentence({
    required String patientName,
    required List<Map<String, String>> items,
    AppLanguage? overrideLang,
  }) {
    final lang = overrideLang ?? languageNotifier.value;
    if (items.isEmpty) {
      switch (lang) {
        case AppLanguage.hindi:
          return 'नमस्ते $patientName। आज के सभी कार्य पूरे हो चुके हैं। बहुत बढ़िया!';
        case AppLanguage.assamese:
          return 'নমস্কাৰ $patientName। আজিৰ সকলো কাম সম্পূৰ্ণ হৈছে। অতি উত্তম!';
        case AppLanguage.bengali:
          return 'নমস্কার $patientName। আজকের সমস্ত কাজ সম্পন্ন হয়েছে। অসাধারণ!';
        case AppLanguage.manipuri:
          return 'খুরুমজরি $patientName। ঙসিগী পুম্নমক লোইশিনখ্রে। য়াম্না ফরে!';
        case AppLanguage.bodo:
          return 'खुलुमबाय $patientName। दिनैनि गासै हाबाफोरा जोबबाय। जोबोद मोजां!';
        case AppLanguage.nepali:
          return 'नमस्ते $patientName। आजका सबै कामहरू पूरा भएका छन्। धेरै राम्रो!';
        case AppLanguage.mizo:
          return 'Chibai $patientName. Vawiina hnathawh tur zawng zawng a zo tawh. A ropui hle mai!';
        case AppLanguage.english:
        default:
          return 'Hello $patientName. All reminders for today are completed. Wonderful job!';
      }
    }

    final buffer = StringBuffer();
    switch (lang) {
      case AppLanguage.hindi:
        buffer.write('नमस्ते $patientName। आज का आपका कार्यक्रम इस प्रकार है: ');
        for (final item in items) {
          final t = trReminderTitle(item['title'] ?? '', lang);
          buffer.write('${item['time']} पर $t। ');
        }
        break;
      case AppLanguage.assamese:
        buffer.write('নমস্কাৰ $patientName। আজিৰ আপোনাৰ কাৰ্যসূচী এনেধৰণৰ: ');
        for (final item in items) {
          final t = trReminderTitle(item['title'] ?? '', lang);
          buffer.write('${item['time']} বজাত $t। ');
        }
        break;
      case AppLanguage.bengali:
        buffer.write('নমস্কার $patientName। আজকের আপনার সময়সূচী হলো: ');
        for (final item in items) {
          final t = trReminderTitle(item['title'] ?? '', lang);
          buffer.write('${item['time']}-এ $t। ');
        }
        break;
      case AppLanguage.manipuri:
        buffer.write('খুরুমজরি $patientName। ঙসিগী মতম লেপপা অসুম্না লৈ: ');
        for (final item in items) {
          final t = trReminderTitle(item['title'] ?? '', lang);
          buffer.write('${item['time']} দা $t। ');
        }
        break;
      case AppLanguage.bodo:
        buffer.write('खुलुमबाय $patientName। दिनैनि नोंथांनि सम फारिलाइया बेबादि: ');
        for (final item in items) {
          final t = trReminderTitle(item['title'] ?? '', lang);
          buffer.write('${item['time']} आव $t। ');
        }
        break;
      case AppLanguage.nepali:
        buffer.write('नमस्ते $patientName। आजको तपाईंको तालिका यस प्रकार छ: ');
        for (final item in items) {
          final t = trReminderTitle(item['title'] ?? '', lang);
          buffer.write('${item['time']} मा $t। ');
        }
        break;
      case AppLanguage.mizo:
        buffer.write('Chibai $patientName. Vawiina i hun ruahman chu hetiang a ni: ');
        for (final item in items) {
          final t = trReminderTitle(item['title'] ?? '', lang);
          buffer.write('Dar ${item['time']}-ah $t. ');
        }
        break;
      case AppLanguage.english:
      default:
        buffer.write('Hello $patientName. Here is your schedule for today: ');
        for (final item in items) {
          final t = trReminderTitle(item['title'] ?? '', lang);
          buffer.write('$t scheduled for ${item['time']}. ');
        }
        break;
    }
    return buffer.toString();
  }


  static final Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.english: {
      'good_morning': 'Good morning,',
      'good_afternoon': 'Good afternoon,',
      'good_evening': 'Good evening,',
      'good_night': 'Good night,',
      'calm_quote': 'A calm start makes room for a good memory.',
      'listen': 'Listen',
      'adjust': 'Adjust',
      'todays_activity': "TODAY'S ACTIVITY",
      'memory_match': 'Memory Match',
      'memory_match_sub': 'Find the matching pairs. Take your time — one card at a time.',
      'about_5_mins': 'About 5 minutes',
      'start_activity': 'Start activity',
      'today': 'TODAY',
      'reminders': 'Reminders',
      'all_done': 'All Done 🎉',
      'pending': 'pending',
      'view_all': 'View all',
      'test_alarm': 'Test Alarm 🔔',
      'no_reminders': 'No reminders set. Tap to add your daily routine.',
      'need_help': 'Need a little help?',
      'need_help_sub': 'You can listen to instructions, take a pause, or ask a caregiver for assistance anytime.',
      'call_caregiver': 'Call Caregiver',
      'gentle_activities': 'GENTLE ACTIVITIES',
      'games_exercises': 'Games & Exercises',
      'games_sub': 'Enjoyable cognitive exercises designed to strengthen memory and motor calm.',
      'routine_sequencer': 'Daily Routine & Life Sequencer',
      'routine_sub': 'Rebuild step-by-step memory for familiar everyday activities (Chai, Plants, Getting Ready).',
      'play_routine': 'Play Routine Sequencer',
      'play_memory_match': 'Play Memory Match',
      'clock_drawing': 'Clock Drawing Canvas',
      'clock_sub': 'Clinical spatial & executive function cognitive assessment.',
      'play_clock': 'Start Clock Assessment',
      'home': 'Home',
      'games': 'Games',
      'caregiver': 'Caregiver',
      'patient': 'Patient',
      'switch_language': 'Change Language',
      'select_language': 'Select Preferred Language',
      'caregiver_workspace': 'Caregiver workspace',
      'caregiver_sub': 'A clear view of support, without clinical assumptions.',
      'patient_care_team_sub': 'Understand patterns, support with confidence.',
      'patient_space_sub': 'A gentle space for daily activities.',
      'care_team': 'CARE TEAM',
      'patient_app': 'PATIENT APP',
      'simulate_sync': 'Simulate sync',
      'live_auto_sync': 'LIVE AUTO-SYNC (2s)',
      'selected_patient': 'SELECTED PATIENT',
      'last_activity': 'Last activity',
      'games_completed': 'GAMES COMPLETED',
      'across_recent_sessions': 'Across recent sessions',
      'avg_accuracy': 'AVERAGE ACCURACY',
      'gameplay_performance': 'Gameplay performance',
      'avg_response': 'AVERAGE RESPONSE',
      'per_interaction': 'Per interaction',
      'current_difficulty': 'CURRENT DIFFICULTY',
      'ai_adaptive_auto': '🤖 AI-Adaptive Auto',
      'fixed_manual_mode': '⚙️ Fixed Manual Mode',
      'diff_controller_title': 'Cognitive Difficulty & AI Pacing Controller',
      'diff_controller_sub': 'Manage auto-adaptive progression or set fixed challenge levels for the patient.',
      'ai_adaptive': 'AI-Adaptive',
      'manual_lock': 'Manual Lock',
      'overview': 'Overview',
      'care_plan': 'Care plan',
      'progress': 'Progress',
      'accessibility': 'Accessibility',
      'help': 'Help',
      'preferred_language': 'PREFERRED LANGUAGE',
      'choose_interface_lang': 'Choose Interface Language',
      'choose_lang_desc': 'All reminders, instructions, audio speech, and games adapt to your selected language.',
      'moves': 'Moves',
      'pairs_left': 'Pairs Left',
      'time': 'Time',
      'accuracy': 'Accuracy',
      'step_number': 'Step',
      'clear': 'Clear',
      'submit': 'Submit',
      'well_done': 'Well done!',
      'add_activity': 'Add Activity',
      'save_plan': 'Save Care Plan',
      'rem_morning_medicine': 'Morning medicine',
      'rem_morning_medicine_notes': 'Take with warm water after breakfast',
      'rem_hydration': 'Morning hydration & water',
      'rem_hydration_notes': 'A glass of fresh water',
      'rem_lunch': 'Lunch & vitamins',
      'rem_lunch_notes': 'Wholesome nutritious lunch',
      'rem_memory_game': 'Memory Match game activity',
      'rem_memory_game_notes': 'Daily 5-minute cognitive exercise',
      'rem_evening_walk': 'Evening garden walk',
      'rem_evening_walk_notes': 'Gentle 15-minute stroll in fresh air',
      'rem_night_medicine': 'Night medicine',
      'rem_night_medicine_notes': 'Before going to bed',
    },
    AppLanguage.hindi: {
      'good_morning': 'शुभ प्रभात,',
      'good_afternoon': 'शुभ दोपहर,',
      'good_evening': 'शुभ संध्या,',
      'good_night': 'शुभ रात्रि,',
      'calm_quote': 'एक शांत शुरुआत अच्छी याददाश्त और सुकून लाती है।',
      'listen': 'सुनें',
      'adjust': 'समायोजित करें',
      'todays_activity': "आज की गतिविधि",
      'memory_match': 'स्मृति मिलान (Memory Match)',
      'memory_match_sub': 'जोड़े ढूंढें। आराम से एक-एक करके खेलें।',
      'about_5_mins': 'लगभग 5 मिनट',
      'start_activity': 'गतिविधि शुरू करें',
      'today': 'आज',
      'reminders': 'दैनिक अनुस्मारक (Reminders)',
      'all_done': 'सब पूर्ण 🎉',
      'pending': 'बाकी',
      'view_all': 'सभी देखें',
      'test_alarm': 'अलार्म टेस्ट 🔔',
      'no_reminders': 'कोई अनुस्मारक नहीं है। नया जोड़ने के लिए टैप करें।',
      'need_help': 'क्या आपको सहायता चाहिए?',
      'need_help_sub': 'आप निर्देश सुन सकते हैं या किसी भी समय देखभालकर्ता को कॉल कर सकते हैं।',
      'call_caregiver': 'देखभालकर्ता को कॉल करें',
      'gentle_activities': 'सौम्य गतिविधियाँ',
      'games_exercises': 'खेल और अभ्यास',
      'games_sub': 'स्मृति और मानसिक शांति को मजबूत करने वाले सुखद खेल।',
      'routine_sequencer': 'दैनिक दिनचर्या अनुक्रमक',
      'routine_sub': 'चाय बनाना, पौधों को पानी देना आदि दैनिक कार्यों का अभ्यास करें।',
      'play_routine': 'दिनचर्या खेलें',
      'play_memory_match': 'स्मृति मिलान खेलें',
      'clock_drawing': 'घड़ी चित्रांकन मूल्यांकन',
      'clock_sub': 'स्थानिक और संज्ञानात्मक क्षमता का सरल परीक्षण।',
      'play_clock': 'घड़ी परीक्षण शुरू करें',
      'home': 'होम',
      'games': 'खेल',
      'caregiver': 'देखभालकर्ता',
      'patient': 'मरीज',
      'switch_language': 'भाषा बदलें',
      'select_language': 'पसंदीदा भाषा चुनें',
      'caregiver_workspace': 'देखभालकर्ता कार्यक्षेत्र (Caregiver workspace)',
      'caregiver_sub': 'बिना किसी परेशानी के सहायता और स्वास्थ्य की स्पष्ट समझ।',
      'patient_care_team_sub': 'मरीज की स्थिति समझें और पूरे आत्मविश्वास से सहयोग करें।',
      'patient_space_sub': 'दैनिक गतिविधियों के लिए एक शांत और सरल मंच।',
      'care_team': 'देखभाल टीम (Care Team)',
      'patient_app': 'मरीज ऐप (Patient App)',
      'simulate_sync': 'डेटा सिंक करें (Simulate sync)',
      'live_auto_sync': 'लाइव ऑटो-सिंक (2s)',
      'selected_patient': 'चयनित मरीज (Selected Patient)',
      'last_activity': 'अंतिम गतिविधि',
      'games_completed': 'पूर्ण किए गए खेल',
      'across_recent_sessions': 'हाल के सत्रों के आधार पर',
      'avg_accuracy': 'औसत सटीकता',
      'gameplay_performance': 'खेल प्रदर्शन स्कोर',
      'avg_response': 'औसत प्रतिक्रिया समय',
      'per_interaction': 'प्रति गतिविधि',
      'current_difficulty': 'वर्तमान कठिनाई स्तर',
      'ai_adaptive_auto': '🤖 एआई-अनुकूलित ऑटो',
      'fixed_manual_mode': '⚙️ निश्चित मैनुअल मोड',
      'diff_controller_title': 'संज्ञानात्मक कठिनाई और एआई गति नियंत्रक',
      'diff_controller_sub': 'मरीज के लिए एआई-आधारित प्रगति नियंत्रित करें या मैन्युअल कठिनाई स्तर सेट करें।',
      'ai_adaptive': 'एआई-अनुकूलित (AI-Adaptive)',
      'manual_lock': 'मैनुअल लॉक (Manual Lock)',
      'overview': 'अवलोकन (Overview)',
      'care_plan': 'देखभाल योजना (Care plan)',
      'progress': 'प्रगति (Progress)',
      'accessibility': 'सुलभता (Accessibility)',
      'help': 'सहायता (Help)',
      'preferred_language': 'पसंदीदा भाषा',
      'choose_interface_lang': 'इंटरफ़ेस भाषा चुनें',
      'choose_lang_desc': 'सभी अनुस्मारक, निर्देश, ऑडियो आवाज और खेल आपकी चुनी हुई भाषा में रूपांतरित होंगे।',
      'moves': 'चालें (Moves)',
      'pairs_left': 'शेष जोड़े',
      'time': 'समय',
      'accuracy': 'सटीकता',
      'step_number': 'चरण',
      'clear': 'साफ करें',
      'submit': 'जमा करें',
      'well_done': 'बहुत बढ़िया!',
      'add_activity': 'गतिविधि जोड़ें',
      'save_plan': 'योजना सहेजें',
      'rem_morning_medicine': 'सुबह की दवा (Morning medicine)',
      'rem_morning_medicine_notes': 'नाश्ते के बाद गुनगुने पानी के साथ लें',
      'rem_hydration': 'सुबह का पानी और ताजगी (Hydration)',
      'rem_hydration_notes': 'एक गिलास ताजा पानी पिएं',
      'rem_lunch': 'दोपहर का भोजन व विटामिन (Lunch)',
      'rem_lunch_notes': 'पौष्टिक व सुपाच्य दोपहर का खाना',
      'rem_memory_game': 'स्मृति मिलान खेल (Memory Match)',
      'rem_memory_game_notes': 'दैनिक 5 मिनट का दिमागी अभ्यास',
      'rem_evening_walk': 'शाम की बागवानी व टहलना (Garden Walk)',
      'rem_evening_walk_notes': 'ताजी हवा में 15 मिनट की हल्की सैर',
      'rem_night_medicine': 'रात की दवा (Night medicine)',
      'rem_night_medicine_notes': 'सोने से पहले लें',
    },
    AppLanguage.assamese: {
      'good_morning': 'শুভ প্ৰভাত,',
      'good_afternoon': 'শুভ অপৰাহ্ণ,',
      'good_evening': 'শুভ সন্ধিয়া,',
      'good_night': 'শুভ ৰাত্ৰি,',
      'calm_quote': 'এটা শান্ত আৰম্ভণিয়ে ভাল স্মৃতি আৰু শান্তি আনে।',
      'listen': 'শুনক',
      'adjust': 'সমন্বয়',
      'todays_activity': "আজিৰ কাৰ্যকলাপ",
      'memory_match': 'স্মৃতি মিলন (Memory Match)',
      'memory_match_sub': 'জোৰাবোৰ বিচাৰক। লাহে লাহে খেলক।',
      'about_5_mins': 'প্ৰায় ৫ মিনিট',
      'start_activity': 'আৰম্ভ কৰক',
      'today': 'আজি',
      'reminders': 'অনুস্মাৰক (Reminders)',
      'all_done': 'সকলো সম্পন্ন 🎉',
      'pending': 'বাকী',
      'view_all': 'সকলো চাওক',
      'test_alarm': 'এলার্ম পৰীক্ষা 🔔',
      'no_reminders': 'কোনো অনুস্মাৰক নাই।',
      'need_help': 'সহায় লাগে নেকি?',
      'need_help_sub': 'আপুনি নিৰ্দেশনা শুনিব পাৰে বা কেয়াৰগিভাৰক সহায়ৰ বাবে মাতিব পাৰে।',
      'call_caregiver': 'কেয়াৰগিভাৰক ফোন কৰক',
      'gentle_activities': 'শান্ত কাৰ্যকলাপ',
      'games_exercises': 'খেল আৰু ব্যায়াম',
      'games_sub': 'স্মৃতিশক্তি আৰু মন শান্ত ৰখাৰ কাৰ্যসূচী।',
      'routine_sequencer': 'দৈনন্দিন ৰুটিন অনুক্ৰমক',
      'routine_sub': 'চাহ বনোৱা, গছত পানী দিয়া আদি দৈনন্দিন অভ্যাস।',
      'play_routine': 'ৰুটিন খেলক',
      'play_memory_match': 'স্মৃতি খেল আৰম্ভ কৰক',
      'clock_drawing': 'ঘড়ী অঁকাৰ পৰীক্ষা',
      'clock_sub': 'মানসিক আৰু কাৰ্যনিৰ্বাহী ক্ষমতা পৰীক্ষা।',
      'play_clock': 'ঘড়ী পৰীক্ষা আৰম্ভ কৰক',
      'home': 'গৃহ',
      'games': 'খেল',
      'caregiver': 'কেয়াৰগিভাৰ',
      'patient': 'ৰোগী',
      'switch_language': 'ভাষা সলনি কৰক',
      'select_language': 'পছন্দৰ ভাষা বাছনি কৰক',
      'caregiver_workspace': 'কেয়াৰগিভাৰ কাৰ্যক্ষেত্ৰ',
      'caregiver_sub': 'সহজ আৰু শান্তভাৱে সহায় কৰাৰ স্পষ্ট পৰিৱেশ।',
      'patient_care_team_sub': 'ৰোগীক বুজি আত্মবিশ্বাসেৰে সহায় কৰক।',
      'patient_space_sub': 'দৈনন্দিন কামৰ বাবে এক শান্ত ঠাই।',
      'care_team': 'যত্ন দল (Care Team)',
      'patient_app': 'ৰোগী এপ্প্',
      'simulate_sync': 'তথ্য সংযোগ (Sync)',
      'live_auto_sync': 'লাইভ অটো-সংযোজন (২ ছেকেণ্ড)',
      'selected_patient': 'নিৰ্বাচিত ৰোগী',
      'last_activity': 'শেষ কাৰ্যকলাপ',
      'games_completed': 'সম্পূৰ্ণ খেল',
      'across_recent_sessions': 'শেহতীয়া খেলৰ ওপৰত',
      'avg_accuracy': 'গড় শুদ্ধতা',
      'gameplay_performance': 'খেলৰ প্ৰদৰ্শন',
      'avg_response': 'গড় সঁহাৰি সময়',
      'per_interaction': 'প্ৰতিটো কামত',
      'current_difficulty': 'বৰ্তমান স্তৰ',
      'ai_adaptive_auto': '🤖 এআই-স্বয়ংচালিত',
      'fixed_manual_mode': '⚙️ নিৰ্দিষ্ট মেনুৱেল',
      'diff_controller_title': 'মানসিক স্তৰ আৰু এআই গতি নিয়ন্ত্ৰক',
      'diff_controller_sub': 'ৰোগীৰ বাবে এআই বা মেনুৱেল স্তৰ নিৰ্বাচন কৰক।',
      'ai_adaptive': 'এআই-অনুকূলিত',
      'manual_lock': 'মেনুৱেল লক',
      'overview': 'অৱলোকন',
      'care_plan': 'যত্ন পৰিকল্পনা',
      'progress': 'উন্নতি',
      'accessibility': 'সহজ সুবিধা',
      'help': 'সহায়',
      'preferred_language': 'পছন্দৰ ভাষা',
      'choose_interface_lang': 'ভাষা বাছনি কৰক',
      'choose_lang_desc': 'সকলো অনুস্মাৰক, কথাবতৰা আৰু খেল নিৰ্বাচিত ভাষাত সলনি হ’ব।',
      'moves': 'খোজ (Moves)',
      'pairs_left': 'বাকী থকা জোৰা',
      'time': 'সময়',
      'accuracy': 'শুদ্ধতা',
      'step_number': 'স্তৰ',
      'clear': 'মচক',
      'submit': 'দাখিল কৰক',
      'well_done': 'অতি উত্তম!',
      'add_activity': 'কাৰ্য্যসূচী যোগ কৰক',
      'save_plan': 'পৰিকল্পনা সংৰক্ষণ কৰক',
      'rem_morning_medicine': 'ৰাতিপুৱাৰ ঔষধ (Morning medicine)',
      'rem_morning_medicine_notes': 'জলপান খোৱাৰ পিছত কুহুমীয়া পানীৰে খাব',
      'rem_hydration': 'ৰাতিপুৱাৰ পানী খোৱা (Hydration)',
      'rem_hydration_notes': 'এগিলাচ সতেজ পানী খাওক',
      'rem_lunch': 'দুপৰীয়াৰ আহাৰ আৰু ভিটামিন (Lunch)',
      'rem_lunch_notes': 'পুষ্টিকৰ দুপৰীয়াৰ আহাৰ',
      'rem_memory_game': 'স্মৃতি মিলন খেল (Memory Match)',
      'rem_memory_game_notes': 'দৈনিক ৫ মিনিটৰ স্মৃতি অনুশীলন',
      'rem_evening_walk': 'সন্ধিয়াৰ খোজ কঢ়া (Evening Walk)',
      'rem_evening_walk_notes': 'সতেজ বতাহত ১৫ মিনিটৰ শান্ত খোজ',
      'rem_night_medicine': 'ৰাতিৰ ঔষধ (Night medicine)',
      'rem_night_medicine_notes': 'শোৱাৰ আগতে খাব',
    },
    AppLanguage.bengali: {
      'good_morning': 'সুপ্রভাত,',
      'good_afternoon': 'শুভ অপরাহ্ন,',
      'good_evening': 'শুভ সন্ধ্যা,',
      'good_night': 'শুভ রাত্রি,',
      'calm_quote': 'একটি শান্ত সকাল ভালো স্মৃতি ও প্রশান্তি এনে দেয়।',
      'listen': 'শুনুন',
      'adjust': 'সমন্বয়',
      'todays_activity': "আজকের কার্যকলাপ",
      'memory_match': 'স্মৃতি মেলানো (Memory Match)',
      'memory_match_sub': 'মিলিত জোড়া খুঁজুন। ধীরে ধীরে খেলুন।',
      'about_5_mins': 'প্রায় ৫ মিনিট',
      'start_activity': 'খেলা শুরু করুন',
      'today': 'আজ',
      'reminders': 'অনুস্মারক (Reminders)',
      'all_done': 'সব সম্পন্ন 🎉',
      'pending': 'বাকি',
      'view_all': 'সব দেখুন',
      'test_alarm': 'অ্যালার্ম পরীক্ষা 🔔',
      'no_reminders': 'কোনো অনুস্মারকের তালিকা নেই।',
      'need_help': 'সাহায্য প্রয়োজন?',
      'need_help_sub': 'আপনি নির্দেশ শুনতে পারেন বা যেকোনো সময় সাহায্যকারীর সাথে যোগাযোগ করতে পারেন।',
      'call_caregiver': 'কেয়ারগিভারকে কল করুন',
      'gentle_activities': 'শান্ত কার্যকলাপ',
      'games_exercises': 'খেলা এবং ব্যায়াম',
      'games_sub': 'স্মৃতিশক্তি ও মানসিক প্রশান্তির জন্য সুন্দর ব্যায়াম।',
      'routine_sequencer': 'দৈনন্দিন কাজের ক্রম',
      'routine_sub': 'চা বানানো, গাছে জল দেওয়া ইত্যাদি প্রতিদিনের অভ্যাস।',
      'play_routine': 'রুটিন খেলা শুরু করুন',
      'play_memory_match': 'স্মৃতি মেলানো খেলুন',
      'clock_drawing': 'ঘড়ির ছবি আঁকার পরীক্ষা',
      'clock_sub': 'মানসিক ও স্থানিক ক্ষমতার ক্লিনিকাল মূল্যায়ন।',
      'play_clock': 'ঘড়ি পরীক্ষা শুরু করুন',
      'home': 'হোম',
      'games': 'খেলা',
      'caregiver': 'কেয়ারগিভার',
      'patient': 'রোগী',
      'switch_language': 'ভাষা পরিবর্তন করুন',
      'select_language': 'পছন্দের ভাষা নির্বাচন করুন',
      'caregiver_workspace': 'কেয়ারগিভার কর্মক্ষেত্র',
      'caregiver_sub': 'সহজ ও স্পষ্ট সহায়তার পরিবেশ।',
      'patient_care_team_sub': 'রোগীর অবস্থা বুঝে আত্মবিশ্বাসের সাথে সহায়তা করুন।',
      'patient_space_sub': 'দৈনন্দিন কাজের জন্য একটি শান্ত স্থান।',
      'care_team': 'কেয়ার টিম',
      'patient_app': 'রোগী অ্যাপ',
      'simulate_sync': 'ডেটা সিঙ্ক করুন',
      'live_auto_sync': 'লাইভ অটো-সিঙ্ক (২ সেকেন্ড)',
      'selected_patient': 'নির্বাচিত রোগী',
      'last_activity': 'শেষ কার্যকলাপ',
      'games_completed': 'সম্পন্ন খেলা',
      'across_recent_sessions': 'সাম্প্রতিক সেশনের ওপর',
      'avg_accuracy': 'গড় নির্ভুলতা',
      'gameplay_performance': 'খেলার স্কোর',
      'avg_response': 'গড় প্রতিক্রিয়ার সময়',
      'per_interaction': 'প্রতি পদক্ষেপে',
      'current_difficulty': 'বর্তমান স্তর',
      'ai_adaptive_auto': '🤖 এআই-অভিযোজিত',
      'fixed_manual_mode': '⚙️ ম্যানুয়াল মোড',
      'diff_controller_title': 'জ্ঞানীয় স্তর ও এআই গতি নিয়ন্ত্রক',
      'diff_controller_sub': 'রোগীর জন্য এআই গতি বা ম্যানুয়াল চ্যালেঞ্জ স্তর পরিচালনা করুন।',
      'ai_adaptive': 'এআই-অভিযোজিত',
      'manual_lock': 'ম্যানুয়াল লক',
      'overview': 'সংক্ষিপ্ত বিবরণ (Overview)',
      'care_plan': 'যত্ন পরিকল্পনা (Care plan)',
      'progress': 'অগ্রগতি (Progress)',
      'accessibility': 'সহজ ব্যবহার (Accessibility)',
      'help': 'সাহায্য (Help)',
      'preferred_language': 'পছন্দের ভাষা',
      'choose_interface_lang': 'ইন্টারফেস ভাষা নির্বাচন করুন',
      'choose_lang_desc': 'সমস্ত অনুস্মারক, নির্দেশাবলী, ভয়েস কথা এবং গেম আপনার নির্বাচিত ভাষায় অভিযোজিত হবে।',
      'moves': 'চাল (Moves)',
      'pairs_left': 'বাকি জোড়া',
      'time': 'সময়',
      'accuracy': 'নির্ভুলতা',
      'step_number': 'ধাপ',
      'clear': 'মুছুন',
      'submit': 'জমা দিন',
      'well_done': 'অসাধারণ!',
      'add_activity': 'কার্যকলাপ যোগ করুন',
      'save_plan': 'পরিকল্পনা সংরক্ষণ করুন',
      'rem_morning_medicine': 'সকালের ওষুধ (Morning medicine)',
      'rem_morning_medicine_notes': 'প্রাতরাশের পর হালকা গরম জল দিয়ে খাবেন',
      'rem_hydration': 'সকালের জলপান (Hydration)',
      'rem_hydration_notes': 'এক গ্লাস তাজা জল পান করুন',
      'rem_lunch': 'দুপুরের খাবার ও ভিটামিন (Lunch)',
      'rem_lunch_notes': 'পুষ্টিকর দুপুরের খাবার',
      'rem_memory_game': 'স্মৃতি মেলানো খেলা (Memory Match)',
      'rem_memory_game_notes': 'প্রতিদিনের ৫ মিনিটের মস্তিষ্কের ব্যায়াম',
      'rem_evening_walk': 'সন্ধ্যার সান্ধ্যভ্রমণ (Evening Walk)',
      'rem_evening_walk_notes': 'তাজা বাতাসে ১৫ মিনিটের শান্ত হাঁটা',
      'rem_night_medicine': 'রাতের ওষুধ (Night medicine)',
      'rem_night_medicine_notes': 'ঘুমানোর আগে খাবেন',
    },
    AppLanguage.manipuri: {
      'good_morning': 'নুমিৎ খাবল,',
      'good_afternoon': 'নুমিৎ য়ুংবা,',
      'good_evening': 'নুমিদাং ওইরে,',
      'good_night': 'নুমিদাংগী খুরুমজরি,',
      'calm_quote': 'শান্তি ওইবা হৌদোক অসিনা নুংশিরবা নিংশিংবা অমসুং পোথাফম পীরি।',
      'listen': 'তাবিয়ু',
      'adjust': 'শেমজিনবা',
      'todays_activity': "ঙসিগী থবক",
      'memory_match': 'নিংশিংবা চাংয়েং (Memory Match)',
      'memory_match_sub': 'মান্নবা মেচশিং থিবিয়ু। তপ্না তপ্না শানবিয়ু।',
      'about_5_mins': 'মিনিট ৫ রোম',
      'start_activity': 'হৌদোকপিয়ু',
      'today': 'ঙসি',
      'reminders': 'নিংশিংবা (Reminders)',
      'all_done': 'পুম্নমক লোইরে 🎉',
      'pending': 'লেমহৌরি',
      'view_all': 'পুম্নমক য়েংবিয়ু',
      'test_alarm': 'অলার্ম চাংয়েং 🔔',
      'no_reminders': 'নিংশিংবা লৈতে।',
      'need_help': 'মতেং দরকার ওইব্রা?',
      'need_help_sub': 'নহাক্না পাউতাক তাবিয়ু নত্ত্রগা কেয়রগিভরগী মতেং লৌজৌ।',
      'call_caregiver': 'কেয়রগিভরদা ফোন তৌবিয়ু',
      'gentle_activities': 'অফবা থবকশিং',
      'games_exercises': 'শান্ন-খোৎনবা অমসুং চাংয়েং',
      'games_sub': 'নিংশিংবা পাঙ্গল কনখৎহন্নবা শান্নবা।',
      'routine_sequencer': 'নুমিৎ খুদিংগী থবক মথং-মনাও',
      'routine_sub': 'চা শাবা, পাম্বীদা ঈশিং থাইবা অসিনচিংবা।',
      'play_routine': 'থবক মথং-মনাও শানবিয়ু',
      'play_memory_match': 'নিংশিংবা শানবিয়ু',
      'clock_drawing': 'পুং চহী অনীৎ য়েংদুনা য়েকপা',
      'clock_sub': 'মচীন-মনাও নৈনবা চাংয়েং।',
      'play_clock': 'চাংয়েং হৌদোকপিয়ু',
      'home': 'য়ুম',
      'games': 'শান্নবা',
      'caregiver': 'কেয়রগিভর',
      'patient': 'অনা-লায়েংবা',
      'switch_language': 'লোন হোংদোকপিয়ু',
      'select_language': 'পাম্বা লোন খনবিয়ু',
      'caregiver_workspace': 'কেয়রগিভরগী থবক মফম',
      'caregiver_sub': 'অনা-লায়েংবদা অয়েৎপা য়াওদনা মতেং পাংনবগী মফম।',
      'patient_care_team_sub': 'অনা-লায়েংববু খঙদুনা থৌনাগা লোয়ননা মতেং পাংবিয়ু।',
      'patient_space_sub': 'নুমিৎ খুদিংগী থবকশিংগী শান্ত ওইবা মফম।',
      'care_team': 'কেয়র তীম',
      'patient_app': 'অনা-লায়েংবা এপ',
      'simulate_sync': 'দেতা শিংক তৌবিয়ু',
      'live_auto_sync': 'লাইভ ওতো-শিংক (২ সেকেন্দ)',
      'selected_patient': 'খনরবা অনা-লায়েংবা',
      'last_activity': 'অরোইবা থবক',
      'games_completed': 'লোইশিনখিবা শান্নবা',
      'across_recent_sessions': 'হন্দক্কী শান্নবশিংদা',
      'avg_accuracy': 'চুম্বগী চাং',
      'gameplay_performance': 'শান্নবগী মহৈ',
      'avg_response': 'খুম্বগী মতম',
      'per_interaction': 'থবক অমমমদা',
      'current_difficulty': 'হৌজিক্কী থাক',
      'ai_adaptive_auto': '🤖 এআই-অদাপ্তিব ওতো',
      'fixed_manual_mode': '⚙️ মেনুএল মোদ',
      'diff_controller_title': 'ৱাখলগী থাক অমসুং এআই কন্ত্রোলর',
      'diff_controller_sub': 'অনা-লায়েংবগী থাক এআই নত্ত্রগা মেনুএল ওইনা শেমজিনবিয়ু।',
      'ai_adaptive': 'এআই-অদাপ্তিব',
      'manual_lock': 'মেনুএল লোক',
      'overview': 'য়েন্থোকপা (Overview)',
      'care_plan': 'লায়েং থৌরাং (Care plan)',
      'progress': 'চাউখৎপা (Progress)',
      'accessibility': 'অলাইবা মওং',
      'help': 'মতেং (Help)',
      'preferred_language': 'পাম্বা লোন',
      'choose_interface_lang': 'লোন খনবিয়ু',
      'choose_lang_desc': 'নিংশিংবা, পাউতাক, খোন্থোক অমসুং শান্নবা পুম্নমক নহাক্কী লোনদা ওন্থোক্কনি।',
      'moves': 'খোঙথাং',
      'pairs_left': 'লেমহৌবা জোড়া',
      'time': 'মতম',
      'accuracy': 'চুম্বা',
      'step_number': 'তাংকক',
      'clear': 'মচক',
      'submit': 'পীবিয়ু',
      'well_done': 'য়াম্না ফরে!',
      'add_activity': 'থবক হাপচিনবিয়ু',
      'save_plan': 'থৌরাং শেভ তৌবিয়ু',
      'rem_morning_medicine': 'অয়ুক্কী হিদাক (Morning medicine)',
      'rem_morning_medicine_notes': 'চাক চাবা মতুংদা ঈশিং শাবা অমগা থকপিয়ু',
      'rem_hydration': 'অয়ুক্কী ঈশিং থকপা (Hydration)',
      'rem_hydration_notes': 'গ্লাস অমা তাজা ঈশিং থকপিয়ু',
      'rem_lunch': 'নুংথিলগী চাক অমসুং ভিটামিন (Lunch)',
      'rem_lunch_notes': 'মচীন-মনাও হৈবা নুংথিলগী চাক',
      'rem_memory_game': 'নিংশিংবা চাংয়েং শান্নবা (Memory Match)',
      'rem_memory_game_notes': 'নুমিৎ খুদিংগী মিনিট ৫গী শান্নবা',
      'rem_evening_walk': 'নুমিদাংগী খোঙনা চৎপা (Evening Walk)',
      'rem_evening_walk_notes': 'অফবা নুংশিত্তা মিনিট ১৫ খোঙনা চৎপা',
      'rem_night_medicine': 'অহিংগী হিদাক (Night medicine)',
      'rem_night_medicine_notes': 'তুমদ্রিঙৈগী মমাংদা থকপিয়ু',
    },
    AppLanguage.bodo: {
      'good_morning': 'फुंबिलिनि खुलुमबाय,',
      'good_afternoon': 'सानजौफुनि खुलुमबाय,',
      'good_evening': 'बेलासिनि खुलुमबाय,',
      'good_night': 'होरनि खुलुमबाय,',
      'calm_quote': 'गोजोनै जागायजेननाया मोजां गोसोखांथि आरो गोजोनथि लाबोयो।',
      'listen': 'खोनासं',
      'adjust': 'गोरोबहो',
      'todays_activity': "दिनैनि हाबाफारि",
      'memory_match': 'गोसोखांथि गोरोबनाय',
      'memory_match_sub': 'गोरोबनाय जराफोरखौ नागिरना दिहुन।',
      'about_5_mins': 'सिम ५ मिनिट',
      'start_activity': 'जागायजेन',
      'today': 'दिनै',
      'reminders': 'गोसोखांथाव (Reminders)',
      'all_done': 'गासैबो जाफुंबाय 🎉',
      'pending': 'थालांबाय',
      'view_all': 'गासैबो नाय',
      'test_alarm': 'एलार्म आनजाद 🔔',
      'no_reminders': 'जेबो गोसोखांथाव गैया।',
      'need_help': 'मदद नांगौ नामा?',
      'need_help_sub': 'नोंथाङा जेब्लाबो सामलायगिरिखौ फोन खालामनो हागोन।',
      'call_caregiver': 'सामलायगिरिनो फोन खालाम',
      'gentle_activities': 'सुबुं हाबाफारिफोर',
      'games_exercises': 'गेलेनाय आरो दिन्थिफोर',
      'games_sub': 'गोसोखांथिखौ गोख्रों खालामनो गेलेनाय।',
      'routine_sequencer': 'सानफ्रोमबोनि हाबा फारि',
      'routine_sub': 'सा बानायनाय, बिफांआव दै होनाय बायदि।',
      'play_routine': 'फारिखौ गेले',
      'play_memory_match': 'गोसोखांथिखौ गेले',
      'clock_drawing': 'घडी आखिनाय आनजाद',
      'clock_sub': 'गोसोनि बिबां आनजाद।',
      'play_clock': 'आनजाद जागाय',
      'home': 'न’',
      'games': 'गेलेनाय',
      'caregiver': 'सामलायगिरि',
      'patient': 'साग्लोबग्रा',
      'switch_language': 'राव सोलाय',
      'select_language': 'राव सायख',
      'caregiver_workspace': 'सामलायगिरिनि हाबासाल',
      'caregiver_sub': 'गोजोनै हेफाजाब होनायनि रोखा दिन्थिफुल।',
      'patient_care_team_sub': 'साग्लोबग्राखौ बुजिना गोसो गोख्रोंजों हेफाजाब हो।',
      'patient_space_sub': 'सानफ्रोमबोनि हाबानि गोजोन जायगा।',
      'care_team': 'सामलायगिरि हानजा',
      'patient_app': 'साग्लोबग्रा एप',
      'simulate_sync': 'डाटा सिंक खालाम',
      'live_auto_sync': 'लाइभ अटो-सिंक (२ सेकेन्ड)',
      'selected_patient': 'सायखनाय साग्लोबग्रा',
      'last_activity': 'जोबथा हाबा',
      'games_completed': 'जोबनाय गेलेनाय',
      'across_recent_sessions': 'दावबायनायनि सायाव',
      'avg_accuracy': 'गोरलैयै गेबेंथि',
      'gameplay_performance': 'गेलेनायनि बिबां',
      'avg_response': 'फिनहोनायनि सम',
      'per_interaction': 'हाबा फारियाव',
      'current_difficulty': 'दानि थाखो',
      'ai_adaptive_auto': '🤖 एआई-अटो',
      'fixed_manual_mode': '⚙️ मेन्युअल मद',
      'diff_controller_title': 'गोसो थाखो आरो एआई नियन्त्रक',
      'diff_controller_sub': 'साग्लोबग्रानि थाखोखौ एआई एबा मेन्युअल सायख।',
      'ai_adaptive': 'एआई-अनुकूलित',
      'manual_lock': 'मेन्युअल लक',
      'overview': 'गुवारै नायनाय',
      'care_plan': 'सामलायनाय फारिलाइ',
      'progress': 'जौगानाय',
      'accessibility': 'गोरलै ब्यवस्था',
      'help': 'मदद',
      'preferred_language': 'पसंदनि राव',
      'choose_interface_lang': 'राव सायख',
      'choose_lang_desc': 'गासै गोसोखांथाव, बिथोन, सोदोब आरो गेलेनाय नोंथांनि रावआव सोलायगोन।',
      'moves': 'थांखि',
      'pairs_left': 'थालांनाय जरा',
      'time': 'सम',
      'accuracy': 'गेबेंथि',
      'step_number': 'खोलोब',
      'clear': 'हुगार',
      'submit': 'हो',
      'well_done': 'जोबोद मोजां!',
      'add_activity': 'हाबा दाजाब',
      'save_plan': 'फारिलाइ लाखि',
      'rem_morning_medicine': 'फुंबिलिनि मुलि (Morning medicine)',
      'rem_morning_medicine_notes': 'फुंनि जाखांनानै गुदुं दैजों लो',
      'rem_hydration': 'फुंबिलिनि दै लोनाय (Hydration)',
      'rem_hydration_notes': 'गोथां दै ग्लाससे लो',
      'rem_lunch': 'सानजौफुनि ओंखाम आरो भिटामिन (Lunch)',
      'rem_lunch_notes': 'पुष्टिकोर सानजौफुनि ओंखाम',
      'rem_memory_game': 'गोसोखांथि गोरोबनाय गेलेनाय (Memory Match)',
      'rem_memory_game_notes': 'सानफ्रोमबो ५ मिनिटनि गोसो आनजाद',
      'rem_evening_walk': 'बेलासिनि बागान दावबायनाय (Evening Walk)',
      'rem_evening_walk_notes': 'बार मोजांआव १५ मिनिट लासै दावबाय',
      'rem_night_medicine': 'होरनि मुलि (Night medicine)',
      'rem_night_medicine_notes': 'उन्दुनायनि सिगां लो',
    },
    AppLanguage.nepali: {
      'good_morning': 'शुभ प्रभात,',
      'good_afternoon': 'शुभ दिउँसो,',
      'good_evening': 'शुभ साँझ,',
      'good_night': 'शुभ रात्रि,',
      'calm_quote': 'शान्त शुरुवातले राम्रो स्मरण र मानसिक शान्ति ल्याउँछ।',
      'listen': 'सुन्नुहोस्',
      'adjust': 'मिलाउनुहोस्',
      'todays_activity': "आजको गतिविधि",
      'memory_match': 'स्मरण मिलान (Memory Match)',
      'memory_match_sub': 'मिल्दो जोडीहरू खोज्नुहोस् र शान्त भएर खेल्नुहोस्।',
      'about_5_mins': 'लगभग ५ मिनेट',
      'start_activity': 'सुरु गर्नुहोस्',
      'today': 'आज',
      'reminders': 'दैनिक सम्झना (Reminders)',
      'all_done': 'सबै सम्पन्न 🎉',
      'pending': 'बाँकी',
      'view_all': 'सबै हेर्नुहोस्',
      'test_alarm': 'अलार्म परीक्षण 🔔',
      'no_reminders': 'कुनै सम्झना छैन।',
      'need_help': 'सहयोग चाहिन्छ?',
      'need_help_sub': 'तपाईं कुनै पनि समय केयरगिभरलाई सम्पर्क गर्न सक्नुहुन्छ।',
      'call_caregiver': 'केयरगिभरलाई कल गर्नुहोस्',
      'gentle_activities': 'शान्त गतिविधिहरू',
      'games_exercises': 'खेल र अभ्यासहरू',
      'games_sub': 'स्मरणशक्ति र मानसिक सन्तुलन बढाउने अभ्यासहरू।',
      'routine_sequencer': 'दैनिक दिनचर्या क्रम',
      'routine_sub': 'चिया बनाउने, बिरुवामा पानी हाल्ने आदि अभ्यास।',
      'play_routine': 'दिनचर्या खेल्नुहोस्',
      'play_memory_match': 'स्मरण खेल खेल्नुहोस्',
      'clock_drawing': 'घडी चित्रकला परीक्षण',
      'clock_sub': 'संज्ञानात्मक क्षमता परीक्षण।',
      'play_clock': 'परीक्षण सुरु गर्नुहोस्',
      'home': 'गृह',
      'games': 'खेलहरू',
      'caregiver': 'केयरगिभर',
      'patient': 'बिरामी',
      'switch_language': 'भाषा बदल्नुहोस्',
      'select_language': 'भाषा चयन गर्नुहोस्',
      'caregiver_workspace': 'केयरगिभर कार्यक्षेत्र',
      'caregiver_sub': 'सहज र स्पष्ट सहयोगको वातावरण।',
      'patient_care_team_sub': 'बिरामीको अवस्था बुझेर आत्मविश्वासका साथ सहयोग गर्नुहोस्।',
      'patient_space_sub': 'दैनिक गतिविधिहरूको लागि एक शान्त ठाउँ।',
      'care_team': 'हेरचाह टोली',
      'patient_app': 'बिरामी एप',
      'simulate_sync': 'डाटा सिंक गर्नुहोस्',
      'live_auto_sync': 'प्रत्यक्ष अटो-सिंक (२ सेकेन्ड)',
      'selected_patient': 'चयनित बिरामी',
      'last_activity': 'अन्तिम गतिविधि',
      'games_completed': 'पूरा भएका खेलहरू',
      'across_recent_sessions': 'हालैका सत्रहरू अनुसार',
      'avg_accuracy': 'औसत शुद्धता',
      'gameplay_performance': 'खेल प्रदर्शन स्कोर',
      'avg_response': 'औसत प्रतिक्रिया समय',
      'per_interaction': 'प्रति गतिविधि',
      'current_difficulty': 'हालको स्तर',
      'ai_adaptive_auto': '🤖 एआई-अनुकूलित',
      'fixed_manual_mode': '⚙️ म्यानुअल मोड',
      'diff_controller_title': 'संज्ञानात्मक स्तर र एआई गति नियन्त्रक',
      'diff_controller_sub': 'बिरामीको लागि एआई वा म्यानुअल कठिनाई स्तर व्यवस्थापन गर्नुहोस्।',
      'ai_adaptive': 'एआई-अनुकूलित',
      'manual_lock': 'म्यानुअल लक',
      'overview': 'सिंहावलोकन (Overview)',
      'care_plan': 'हेरचाह योजना (Care plan)',
      'progress': 'प्रगति (Progress)',
      'accessibility': 'पहुँच योग्यता (Accessibility)',
      'help': 'सहयोग (Help)',
      'preferred_language': 'प्राथमिक भाषा',
      'choose_interface_lang': 'इन्टरफेस भाषा छान्नुहोस्',
      'choose_lang_desc': 'सबै सम्झना, निर्देशन, आवाज र खेलहरू तपाईंको छनौट गरिएको भाषामा रूपान्तरित हुनेछन्।',
      'moves': 'चालहरू (Moves)',
      'pairs_left': 'बाँकी जोडी',
      'time': 'समय',
      'accuracy': 'शुद्धता',
      'step_number': 'चरण',
      'clear': 'मेटाउनुहोस्',
      'submit': 'पेश गर्नुहोस्',
      'well_done': 'धेरै राम्रो!',
      'add_activity': 'गतिविधि थप्नुहोस्',
      'save_plan': 'योजना सुरक्षित गर्नुहोस्',
      'rem_morning_medicine': 'बिहानको औषधि (Morning medicine)',
      'rem_morning_medicine_notes': 'बिहानको खाजा पछि मनतातो पानीसँग लिनुहोस्',
      'rem_hydration': 'बिहानको पानी (Hydration)',
      'rem_hydration_notes': 'एक गिलास ताजा पानी पिउनुहोस्',
      'rem_lunch': 'दिउँसोको खाना र भिटामिन (Lunch)',
      'rem_lunch_notes': 'पौष्टिक र सन्तुलित दिउँसोको खाना',
      'rem_memory_game': 'स्मरण मिलान खेल (Memory Match)',
      'rem_memory_game_notes': 'दैनिक ५ मिनेटको मानसिक अभ्यास',
      'rem_evening_walk': 'साँझको बगैंचा पैदल यात्रा (Garden Walk)',
      'rem_evening_walk_notes': 'ताजा हावामा १५ मिनेटको शान्त हिँडाइ',
      'rem_night_medicine': 'रातको औषधि (Night medicine)',
      'rem_night_medicine_notes': 'सुत्नु अघि लिनुहोस्',
    },
    AppLanguage.mizo: {
      'good_morning': 'Chibai zing chibai,',
      'good_afternoon': 'Chhun chibai,',
      'good_evening': 'Tlaizawng chibai,',
      'good_night': 'Muthak chibai,',
      'calm_quote': 'Bultanna nunnem hian hriatrengna tha leh rilru damna a thlen.',
      'listen': 'Ngaithla rawh',
      'adjust': 'Siamrem rawh',
      'todays_activity': "VAWIIN THILTIH",
      'memory_match': 'Hriatrengna Inmilh (Memory Match)',
      'memory_match_sub': 'A inmil zawng chhuak rawh. Hmanhmawh lovin khel rawh.',
      'about_5_mins': 'Minute 5 vel',
      'start_activity': 'Tan rawh',
      'today': 'VAWIIN',
      'reminders': 'Hriattirna (Reminders)',
      'all_done': 'A zo vek e 🎉',
      'pending': 'la awm',
      'view_all': 'En kimna',
      'test_alarm': 'Darkhla Test 🔔',
      'no_reminders': 'Hriattirna a awm rih lo.',
      'need_help': 'Tanpuina i mamawh em?',
      'need_help_sub': 'Engtik lai pawhin i enkawltu i be thei reng e.',
      'call_caregiver': 'Enkawltu be rawh',
      'gentle_activities': 'THILTIH NUAMTE',
      'games_exercises': 'Infiamna & Inzirtirna',
      'games_sub': 'Hriatrengna tichak tura duan thiltihte.',
      'routine_sequencer': 'Nitinte Hnathawh Indawt',
      'routine_sub': 'Thingpui lum, thlai tui pek tih angte.',
      'play_routine': 'Khel tan rawh',
      'play_memory_match': 'Hriatrengna Khel rawh',
      'clock_drawing': 'Sana Ziak Entirna',
      'clock_sub': 'Rilru leh ngaihtuahna endikna.',
      'play_clock': 'Endikna tan rawh',
      'home': 'In',
      'games': 'Infiamna',
      'caregiver': 'Enkawltu',
      'patient': 'Damlo',
      'switch_language': 'Tawng thlakna',
      'select_language': 'Tawng duhzawng thlang rawh',
      'caregiver_workspace': 'Enkawltu Hnathawhna Hmun',
      'caregiver_sub': 'Damlo tanpui nana hriatthiamna kimchang.',
      'patient_care_team_sub': 'Damlo dinhmun hrethiam la, inrintawkna nen tanpui rawh.',
      'patient_space_sub': 'Nitinte thiltih atan hmun nuam leh dam.',
      'care_team': 'Enkawltu Pawl',
      'patient_app': 'Damlo App',
      'simulate_sync': 'Data Sync rawh',
      'live_auto_sync': 'Auto-Sync (2s)',
      'selected_patient': 'Damlo Thlan',
      'last_activity': 'Thiltih hnuhnung',
      'games_completed': 'Infiamna zawh zat',
      'across_recent_sessions': 'Infiamna hnuhnungte atangin',
      'avg_accuracy': 'Dik chawhrual',
      'gameplay_performance': 'Infiamna dinhmun',
      'avg_response': 'Chhanna hun chawhrual',
      'per_interaction': 'Thiltih tinah',
      'current_difficulty': 'Harsatna awm mek',
      'ai_adaptive_auto': '🤖 AI-Adaptive Auto',
      'fixed_manual_mode': '⚙️ Manual Mode',
      'diff_controller_title': 'Rilru Thiamna & AI Kaihhruaina',
      'diff_controller_sub': 'Damlo tana AI harsatna siamremna emaw mahnia thlanna.',
      'ai_adaptive': 'AI-Adaptive',
      'manual_lock': 'Manual Lock',
      'overview': 'Enna Tlangpui (Overview)',
      'care_plan': 'Enkawlna Ruahmanna',
      'progress': 'Hmasawnna (Progress)',
      'accessibility': 'Awlsamna (Accessibility)',
      'help': 'Tanpuina (Help)',
      'preferred_language': 'Tawng duh zawn',
      'choose_interface_lang': 'Interface Tawng Thlang rawh',
      'choose_lang_desc': 'Hriattirna, kaihhruaina, aw chhuak leh infiamna zawng zawng i tawng thlan milin a inthlak ang.',
      'moves': 'Chetsual zat',
      'pairs_left': 'La bâng zat',
      'time': 'Hun',
      'accuracy': 'Dik zat',
      'step_number': 'Step',
      'clear': 'Tifai rawh',
      'submit': 'Thawn rawh',
      'well_done': 'A va tha em!',
      'add_activity': 'Thiltih thar dah rawh',
      'save_plan': 'Ruahmanna vawng tha rawh',
      'rem_morning_medicine': 'Zing damdawi (Morning medicine)',
      'rem_morning_medicine_notes': 'Tukṭhuan ei zawhah tui lum nen ei rawh',
      'rem_hydration': 'Zing tui in (Hydration)',
      'rem_hydration_notes': 'Tui thianghlim no khat in rawh',
      'rem_lunch': 'Chhunchaw leh vitamins (Lunch)',
      'rem_lunch_notes': 'Chhunchaw ṭha leh hrisel',
      'rem_memory_game': 'Hriatrengna Inmilh Infiamna (Memory Match)',
      'rem_memory_game_notes': 'Ni tina minute 5 rilru sawizawina',
      'rem_evening_walk': 'Tlai kal chhuah (Evening Walk)',
      'rem_evening_walk_notes': 'Boruak thianghlima minute 15 kal velna',
      'rem_night_medicine': 'Zan damdawi (Night medicine)',
      'rem_night_medicine_notes': 'Mut dawnah ei rawh',
    },
  };
}
