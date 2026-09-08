import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/patient_profile.dart';
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
      case AppLanguage.bengali:
        return 'নমস্কার! সহায়কে আপনাকে স্বাগতম। আপনার ভাষা বাংলা নির্বাচন করা হয়েছে।';
      case AppLanguage.tamil:
        return 'வணக்கம்! சகாயக் உங்களை வரவேற்கிறது. உங்கள் மொழி தமிழ் தேர்ந்தெடுக்கப்பட்டது.';
      case AppLanguage.telugu:
        return 'నమస్కారం! సహాయక్ కు స్వాగతం. మీ భాష తెలుగు ఎంపిక చేయబడింది.';
      case AppLanguage.marathi:
        return 'नमस्कार! सहायकमध्ये आपले स्वागत आहे. आपली भाषा मराठी निवडली गेली आहे.';
      case AppLanguage.gujarati:
        return 'નમસ્તે! સહાયકમાં આપનું સ્વાગત છે. તમારી ભાષા ગુજરાતી પસંદ કરવામાં આવી છે.';
      case AppLanguage.kannada:
        return 'ನಮಸ್ಕಾರ! ಸಹಾಯಕಕ್ಕೆ ಸುಸ್ವಾಗತ. ನಿಮ್ಮ ಭಾಷೆ ಕನ್ನಡ ಆಯ್ಕೆಯಾಗಿದೆ.';
      case AppLanguage.malayalam:
        return 'നമസ്കാരം! സഹായകിലേക്ക് സ്വാഗതം. നിങ്ങളുടെ ഭാഷ മലയാളം തിരഞ്ഞെടുത്തു.';
      case AppLanguage.punjabi:
        return 'ਸਤਿ ਸ਼੍ਰੀ ਅਕਾਲ! ਸਹਾਇਕ ਵਿੱਚ ਤੁਹਾਡਾ ਸੁਆਗਤ ਹੈ। ਤੁਹਾਡੀ ਭਾਸ਼ਾ ਪੰਜਾਬੀ ਚੁਣੀ ਗਈ ਹੈ।';
      case AppLanguage.english:
      default:
        return 'Welcome to Sahayak AI. Interface language set to English.';
    }
  }

  static String tr(String key, [AppLanguage? overrideLang]) {
    final lang = overrideLang ?? languageNotifier.value;
    final dict = _translations[lang] ?? _translations[AppLanguage.english]!;
    return dict[key] ?? _translations[AppLanguage.english]![key] ?? key;
  }

  static final Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.english: {
      'good_morning': 'Good morning,',
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
    },
    AppLanguage.hindi: {
      'good_morning': 'शुभ प्रभात,',
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
    },
    AppLanguage.bengali: {
      'good_morning': 'সুপ্রভাত,',
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
      'no_reminders': 'কোনো অনুস্মারক নেই। যোগ করতে ট্যাপ করুন।',
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
    },
    AppLanguage.tamil: {
      'good_morning': 'காலை வணக்கம்,',
      'calm_quote': 'அமைதியான ஆரம்பம் நல்ல நினைவாற்றலைத் தருகிறது.',
      'listen': 'கேளுங்கள்',
      'adjust': 'சரிசெய்',
      'todays_activity': "இன்றைய செயல்பாடு",
      'memory_match': 'நினைவக பொருத்தம்',
      'memory_match_sub': 'பொருந்தும் ஜோடிகளைக் கண்டறியவும்.',
      'about_5_mins': 'சுமார் 5 நிமிடங்கள்',
      'start_activity': 'தொடங்குங்கள்',
      'today': 'இன்று',
      'reminders': 'நினைவூட்டல்கள்',
      'all_done': 'அனைத்தும் முடிந்தது 🎉',
      'pending': 'நிலுவையில்',
      'view_all': 'அனைத்தையும் பார்க்க',
      'test_alarm': 'அலாரம் சோதனை 🔔',
      'no_reminders': 'நினைவூட்டல்கள் இல்லை.',
      'need_help': 'உதவி தேவையா?',
      'need_help_sub': 'பராமரிப்பாளரை எந்த நேரத்திலும் தொடர்பு கொள்ளலாம்.',
      'call_caregiver': 'பராமரிப்பாளரை அழைக்கவும்',
      'gentle_activities': 'மென்மையான பயிற்சிகள்',
      'games_exercises': 'விளையாட்டுகள் & பயிற்சிகள்',
      'games_sub': 'நினைவாற்றலை வலுப்படுத்தும் பயிற்சிகள்.',
      'routine_sequencer': 'தினசரி பழக்கவழக்க வரிசை',
      'routine_sub': 'டீ போடுவது, செடிகளுக்கு நீர் ஊற்றுவது போன்ற பழக்கங்கள்.',
      'play_routine': 'வரிசை விளையாடு',
      'play_memory_match': 'நினைவகம் விளையாடு',
      'clock_drawing': 'கடிகார வரைதல் சோதனை',
      'clock_sub': 'அறிவாற்றல் மதிப்பீடு.',
      'play_clock': 'சோதனையைத் தொடங்கு',
      'home': 'முகப்பு',
      'games': 'விளையாட்டுகள்',
      'caregiver': 'பராமரிப்பாளர்',
      'patient': 'நோயாளி',
      'switch_language': 'மொழியை மாற்றவும்',
      'select_language': 'மொழியைத் தேர்ந்தெடுக்கவும்',
    },
    AppLanguage.telugu: {
      'good_morning': 'శుభోదయం,',
      'calm_quote': 'ప్రశాంతమైన ప్రారంభం మంచి జ్ఞాపకశక్తిని ఇస్తుంది.',
      'listen': 'వినండి',
      'adjust': 'సవరించండి',
      'todays_activity': "నేటి కార్యాచరణ",
      'memory_match': 'జ్ఞాపకశక్తి సరిపోలిక',
      'memory_match_sub': 'సరిపోలే జతలను కనుగొనండి.',
      'about_5_mins': 'సుమారు 5 నిమిషాలు',
      'start_activity': 'ప్రారంభించండి',
      'today': 'ఈరోజు',
      'reminders': 'రిమైండర్లు',
      'all_done': 'అన్నీ పూర్తయ్యాయి 🎉',
      'pending': 'బాకీ',
      'view_all': 'అన్నీ చూడండి',
      'test_alarm': 'అలారం టెస్ట్ 🔔',
      'no_reminders': 'రిమైండర్లు లేవు.',
      'need_help': 'సహాయం కావాలా?',
      'need_help_sub': 'కేర్ గివర్ కు ఎప్పుడైనా కాల్ చేయవచ్చు.',
      'call_caregiver': 'కేర్ గివర్ కు కాల్ చేయండి',
      'gentle_activities': 'సున్నితమైన వ్యాయామాలు',
      'games_exercises': 'ఆటలు & వ్యాయామాలు',
      'games_sub': 'జ్ఞాపకశక్తిని మెరుగుపరిచే ఆహ్లాదకరమైన ఆటలు.',
      'routine_sequencer': 'దినచర్య సీక్వెన్సర్',
      'routine_sub': 'టీ చేయడం, మొక్కలకు నీరు పోయడం వంటి పనులు.',
      'play_routine': 'దినచర్య ఆట ఆడండి',
      'play_memory_match': 'జ్ఞాపకశక్తి ఆట ఆడండి',
      'clock_drawing': 'గడియారం డ్రాయింగ్ టెస్ట్',
      'clock_sub': 'కాగ్నిటివ్ అసెస్‌మెంట్.',
      'play_clock': 'టెస్ట్ ప్రారంభించండి',
      'home': 'హోమ్',
      'games': 'ఆటలు',
      'caregiver': 'కేర్ గివర్',
      'patient': 'రోగి',
      'switch_language': 'భాష మార్చండి',
      'select_language': 'భాషను ఎంచుకోండి',
    },
    AppLanguage.marathi: {
      'good_morning': 'शुभ प्रभात,',
      'calm_quote': 'शांत सुरुवात चांगली स्मरणशक्ती आणि समाधान देते.',
      'listen': 'ऐका',
      'adjust': 'बदला',
      'todays_activity': "आजची कृती",
      'memory_match': 'स्मृती जुळवणी (Memory Match)',
      'memory_match_sub': 'जोड्या शोधा आणि आरामात खेळा.',
      'about_5_mins': 'सुमारे ५ मिनिटे',
      'start_activity': 'खेळ सुरू करा',
      'today': 'आज',
      'reminders': 'स्मरणपत्रे (Reminders)',
      'all_done': 'सर्व पूर्ण 🎉',
      'pending': 'बाकी',
      'view_all': 'सर्व पहा',
      'test_alarm': 'अलार्म टेस्ट 🔔',
      'no_reminders': 'कोणतीही स्मरणपत्रे नाहीत.',
      'need_help': 'मदत हवी आहे का?',
      'need_help_sub': 'तुम्ही काळजीवाहू व्यक्तीशी कधीही संपर्क साधू शकता.',
      'call_caregiver': 'काळजीवाहूला कॉल करा',
      'gentle_activities': 'सोपे व्यायाम',
      'games_exercises': 'खेळ आणि व्यायाम',
      'games_sub': 'स्मरणशक्ती वाढवणारे खेळ.',
      'routine_sequencer': 'दैनिक दिनचर्या खेळ',
      'routine_sub': 'चहा बनवणे, झाडांना पाणी देणे अशा रोजच्या सवयी.',
      'play_routine': 'दिनचर्या खेळा',
      'play_memory_match': 'स्मृती जुळवणी खेळा',
      'clock_drawing': 'घड्याळ रेखाटन चाचणी',
      'clock_sub': 'मानसिक क्षमता मूल्यांकन.',
      'play_clock': 'चाचणी सुरू करा',
      'home': 'होम',
      'games': 'खेळ',
      'caregiver': 'काळजीवाहू',
      'patient': 'रुग्ण',
      'switch_language': 'भाषा बदला',
      'select_language': 'भाषा निवडा',
    },
    AppLanguage.gujarati: {
      'good_morning': 'શુભ સવાર,',
      'calm_quote': 'શાંત શરૂઆત સારી યાદશક્તિ અને સુખ આપે છે.',
      'listen': 'સાંભળો',
      'adjust': 'સમાયોજિત',
      'todays_activity': "આજની પ્રવૃત્તિ",
      'memory_match': 'યાદશક્તિ મેચ (Memory Match)',
      'memory_match_sub': 'જોડીઓ શોધો અને શાંતિથી રમો.',
      'about_5_mins': 'લગભગ ૫ મિનિટ',
      'start_activity': 'શરૂ કરો',
      'today': 'આજે',
      'reminders': 'રિમાઇન્ડર્સ',
      'all_done': 'બધું પૂર્ણ 🎉',
      'pending': 'બાકી',
      'view_all': 'બધા જુઓ',
      'test_alarm': 'અલાર્મ ટેસ્ટ 🔔',
      'no_reminders': 'કોઈ રિમાઇન્ડર નથી.',
      'need_help': 'શું મદદ જોઈએ છે?',
      'need_help_sub': 'તમે કોઈપણ સમયે સંભાળ રાખનારને કૉલ કરી શકો છો.',
      'call_caregiver': 'સંભાળ રાખનારને કૉલ કરો',
      'gentle_activities': 'સરળ પ્રવૃત્તિઓ',
      'games_exercises': 'રમતો અને કસરતો',
      'games_sub': 'યાદશક્તિ મજબૂત કરતી રમતો.',
      'routine_sequencer': 'દૈનિક દિનચર્યા ક્રમ',
      'routine_sub': 'ચા બનાવવી, છોડને પાણી આપવું વગેરે પ્રવૃત્તિઓ.',
      'play_routine': 'દિનચર્યા રમો',
      'play_memory_match': 'યાદશક્તિ રમો',
      'clock_drawing': 'ઘડિયાળ ડ્રોઇંગ ટેસ્ટ',
      'clock_sub': 'જ્ઞાનાત્મક ક્ષમતાનું મૂલ્યાંકન.',
      'play_clock': 'ટેસ્ટ શરૂ કરો',
      'home': 'હોમ',
      'games': 'રમતો',
      'caregiver': 'સંભાળ રાખનાર',
      'patient': 'દર્દી',
      'switch_language': 'ભાષા બદલો',
      'select_language': 'ભાષા પસંદ કરો',
    },
    AppLanguage.kannada: {
      'good_morning': 'ಶುಭೋದಯ,',
      'calm_quote': 'ಶಾಂತ ಆರಂಭವು ಉತ್ತಮ ಸ್ಮರಣೆಯನ್ನು ನೀಡುತ್ತದೆ.',
      'listen': 'ಕೇಳಿ',
      'adjust': 'ಹೊಂದಿಸಿ',
      'todays_activity': "ಇಂದಿನ ಚಟುವಟಿಕೆ",
      'memory_match': 'ನೆನಪಿನ ಹೊಂದಾಣಿಕೆ',
      'memory_match_sub': 'ಹೊಂದಾಣಿಕೆಯ ಜೋಡಿಗಳನ್ನು ಹುಡುಕಿ.',
      'about_5_mins': 'ಸುಮಾರು 5 ನಿಮಿಷಗಳು',
      'start_activity': 'ಪ್ರಾರಂಭಿಸಿ',
      'today': 'ಇಂದು',
      'reminders': 'ಜ್ಞಾಪನೆಗಳು',
      'all_done': 'ಎಲ್ಲವೂ ಪೂರ್ಣಗೊಂಡಿದೆ 🎉',
      'pending': 'ಬಾಕಿ',
      'view_all': 'ಎಲ್ಲವನ್ನೂ ವೀಕ್ಷಿಸಿ',
      'test_alarm': 'ಅಲಾರಾಂ ಪರೀಕ್ಷೆ 🔔',
      'no_reminders': 'ಯಾವುದೇ ಜ್ಞಾಪನೆಗಳಿಲ್ಲ.',
      'need_help': 'ಸಹಾಯ ಬೇಕೇ?',
      'need_help_sub': 'ಆರೈಕೆದಾರರನ್ನು ಯಾವುದೇ ಸಮಯದಲ್ಲಿ ಸಂಪರ್ಕಿಸಬಹುದು.',
      'call_caregiver': 'ಆರೈಕೆದಾರರಿಗೆ ಕರೆ ಮಾಡಿ',
      'gentle_activities': 'ಸರಳ ಚಟುವಟಿಕೆಗಳು',
      'games_exercises': 'ಆಟಗಳು ಮತ್ತು ವ್ಯಾಯಾಮಗಳು',
      'games_sub': 'ನೆನಪಿನ ಶಕ್ತಿಯನ್ನು ಹೆಚ್ಚಿಸುವ ಆಟಗಳು.',
      'routine_sequencer': 'ದೈನಂದಿನ ದಿನಚರಿ ಅನುಕ್ರಮ',
      'routine_sub': 'ಚಹಾ ಮಾಡುವುದು, ಗಿಡಗಳಿಗೆ ನೀರು ಹಾಕುವುದು ಇತ್ಯಾದಿ.',
      'play_routine': 'ದಿನಚರಿ ಆಟ ಆಡಿ',
      'play_memory_match': 'ನೆನಪಿನ ಆಟ ಆಡಿ',
      'clock_drawing': 'ಗಡಿಯಾರ ಚಿತ್ರಕಲೆ ಪರೀಕ್ಷೆ',
      'clock_sub': 'ಅರಿವಿನ ಸಾಮರ್ಥ್ಯ ಪರೀಕ್ಷೆ.',
      'play_clock': 'ಪರೀಕ್ಷೆ ಪ್ರಾರಂಭಿಸಿ',
      'home': 'ಮುಖಪುಟ',
      'games': 'ಆಟಗಳು',
      'caregiver': 'ಆರೈಕೆದಾರ',
      'patient': 'ರೋಗಿ',
      'switch_language': 'ಭಾಷೆ ಬದಲಾಯಿಸಿ',
      'select_language': 'ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ',
    },
    AppLanguage.malayalam: {
      'good_morning': 'സുപ്രഭാതം,',
      'calm_quote': 'ശാന്തമായ തുടക്കം നല്ല ഓർമ്മ നൽകുന്നു.',
      'listen': 'കേൾക്കുക',
      'adjust': 'ക്രമീകരിക്കുക',
      'todays_activity': "ഇന്നത്തെ പ്രവർത്തനം",
      'memory_match': 'ഓർമ്മ പൊരുത്തം',
      'memory_match_sub': 'പൊരുത്തപ്പെടുന്ന ജോഡികൾ കണ്ടെത്തുക.',
      'about_5_mins': 'ഏകദേശം 5 മിനിറ്റ്',
      'start_activity': 'ആരംഭിക്കുക',
      'today': 'ഇന്ന്',
      'reminders': 'ഓർമ്മപ്പെടുത്തലുകൾ',
      'all_done': 'എല്ലാം പൂർത്തിയായി 🎉',
      'pending': 'ബാക്കി',
      'view_all': 'എല്ലാം കാണുക',
      'test_alarm': 'അലാറം ടെസ്റ്റ് 🔔',
      'no_reminders': 'ഓർമ്മപ്പെടുത്തലുകൾ ഇല്ല.',
      'need_help': 'സഹായം വേണമോ?',
      'need_help_sub': 'പരിപാലകനെ എപ്പോൾ വേണമെങ്കിലും ബന്ധപ്പെടാം.',
      'call_caregiver': 'പരിപാലകനെ വിളിക്കുക',
      'gentle_activities': 'ലളിതമായ വ്യായാമങ്ങൾ',
      'games_exercises': 'കളികളും വ്യായാമങ്ങളും',
      'games_sub': 'ഓർമ്മശക്തി വർദ്ധിപ്പിക്കുന്ന കളികൾ.',
      'routine_sequencer': 'ദിനചര്യ അനുക്രമം',
      'routine_sub': 'ചായ ഉണ്ടാക്കൽ, ചെടികൾ നനയ്ക്കൽ എന്നിവ.',
      'play_routine': 'ദിനചര്യ ആരംഭിക്കുക',
      'play_memory_match': 'ഓർമ്മക്കളി കളിക്കുക',
      'clock_drawing': 'ക്ലോക്ക് ഡ്രോയിംഗ് ടെസ്റ്റ്',
      'clock_sub': 'വൈജ്ഞാനിക ശേഷി പരിശോധന.',
      'play_clock': 'ടെസ്റ്റ് ആരംഭിക്കുക',
      'home': 'ഹോം',
      'games': 'കളികൾ',
      'caregiver': 'പരിപാലകൻ',
      'patient': 'രോഗി',
      'switch_language': 'ഭാഷ മാറ്റുക',
      'select_language': 'ഭാഷ തിരഞ്ഞെടുക്കുക',
    },
    AppLanguage.punjabi: {
      'good_morning': 'ਸ਼ੁਭ ਸਵੇਰ,',
      'calm_quote': 'ਇੱਕ ਸ਼ਾਂਤ ਸ਼ੁਰੂਆਤ ਚੰਗੀ ਯਾਦਦਾਸ਼ਤ ਲਿਆਉਂਦੀ ਹੈ।',
      'listen': 'ਸੁਣੋ',
      'adjust': 'ਸੈੱਟ ਕਰੋ',
      'todays_activity': "ਅੱਜ ਦੀ ਗਤੀਵਿਧੀ",
      'memory_match': 'ਯਾਦਦਾਸ਼ਤ ਮੇਲ (Memory Match)',
      'memory_match_sub': 'ਜੋੜੇ ਲੱਭੋ ਅਤੇ ਆਰਾਮ ਨਾਲ ਖੇਡੋ।',
      'about_5_mins': 'ਲਗਭਗ 5 ਮਿੰਟ',
      'start_activity': 'ਸ਼ੁਰੂ ਕਰੋ',
      'today': 'ਅੱਜ',
      'reminders': 'ਯਾਦ-ਦਹਾਨੀਆਂ (Reminders)',
      'all_done': 'ਸਭ ਪੂਰਾ ਹੋ ਗਿਆ 🎉',
      'pending': 'ਬਾਕੀ',
      'view_all': 'ਸਭ ਦੇਖੋ',
      'test_alarm': 'ਅਲਾਰਮ ਟੈਸਟ 🔔',
      'no_reminders': 'ਕੋਈ ਯਾਦ-ਦਹਾਨੀ ਨਹੀਂ ਹੈ।',
      'need_help': 'ਕੀ ਮਦਦ ਚਾਹੀਦੀ ਹੈ?',
      'need_help_sub': 'ਤੁਸੀਂ ਕਿਸੇ ਵੀ ਸਮੇਂ ਕੇਅਰਗਿਵਰ ਨੂੰ ਕਾਲ ਕਰ ਸਕਦੇ ਹੋ।',
      'call_caregiver': 'ਕੇਅਰਗਿਵਰ ਨੂੰ ਕਾਲ ਕਰੋ',
      'gentle_activities': 'ਸਧਾਰਨ ਗਤੀਵਿਧੀਆਂ',
      'games_exercises': 'ਖੇਡਾਂ ਅਤੇ ਅਭਿਆਸ',
      'games_sub': 'ਯਾਦਦਾਸ਼ਤ ਨੂੰ ਮਜ਼ਬੂਤ ​​ਕਰਨ ਵਾਲੀਆਂ ਖੇਡਾਂ।',
      'routine_sequencer': 'ਰੋਜ਼ਾਨਾ ਰੁਟੀਨ ਕ੍ਰਮ',
      'routine_sub': 'ਚਾਹ ਬਣਾਉਣਾ, ਪੌਦਿਆਂ ਨੂੰ ਪਾਣੀ ਦੇਣਾ ਆਦਿ।',
      'play_routine': 'ਰੁਟੀਨ ਖੇਡੋ',
      'play_memory_match': 'ਯਾਦਦਾਸ਼ਤ ਖੇਡੋ',
      'clock_drawing': 'ਘੜੀ ਡਰਾਇੰਗ ਟੈਸਟ',
      'clock_sub': 'ਮਾਨਸਿਕ ਮੁਲਾਂਕਣ।',
      'play_clock': 'ਟੈਸਟ ਸ਼ੁਰੂ ਕਰੋ',
      'home': 'ਹੋਮ',
      'games': 'ਖੇਡਾਂ',
      'caregiver': 'ਕੇਅਰਗਿਵਰ',
      'patient': 'ਮਰੀਜ਼',
      'switch_language': 'ਭਾਸ਼ਾ ਬਦਲੋ',
      'select_language': 'ਭਾਸ਼ਾ ਚੁਣੋ',
    },
  };
}
