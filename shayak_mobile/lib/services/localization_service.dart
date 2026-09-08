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
    },
  };
}
