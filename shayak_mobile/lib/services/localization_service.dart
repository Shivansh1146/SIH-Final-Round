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

  static String trTier(String tier, [AppLanguage? lang]) {
    final l = lang ?? instance.currentLanguage;
    final t = tier.toLowerCase();
    if (t.contains('level 1') || t.contains('gentle')) {
      switch (l) {
        case AppLanguage.hindi: return 'स्तर 1 (सौम्य)';
        case AppLanguage.assamese: return 'স্তৰ ১ (কোমল)';
        case AppLanguage.bengali: return 'স্তর ১ (কোমল)';
        case AppLanguage.manipuri: return 'থাক ১ (নমথবা)';
        case AppLanguage.bodo: return 'थाखो १ (गुरै)';
        case AppLanguage.nepali: return 'तह १ (सौम्य)';
        case AppLanguage.mizo: return 'Level 1 (Zawi)';
        case AppLanguage.english: default: return 'Level 1 (Gentle)';
      }
    } else if (t.contains('level 2') || t.contains('moderate')) {
      switch (l) {
        case AppLanguage.hindi: return 'स्तर 2 (मध्यम)';
        case AppLanguage.assamese: return 'স্তৰ ২ (মধ্যম)';
        case AppLanguage.bengali: return 'স্তর ২ (মাঝারি)';
        case AppLanguage.manipuri: return 'থাক ২ (ময়াইওইবা)';
        case AppLanguage.bodo: return 'थाखो २ (गेजेर)';
        case AppLanguage.nepali: return 'तह २ (मध्यम)';
        case AppLanguage.mizo: return 'Level 2 (Inawm)';
        case AppLanguage.english: default: return 'Level 2 (Moderate)';
      }
    } else if (t.contains('level 3') || t.contains('challenging')) {
      switch (l) {
        case AppLanguage.hindi: return 'स्तर 3 (कठिन)';
        case AppLanguage.assamese: return 'স্তৰ ৩ (প্ৰত্যাহ্বানজনক)';
        case AppLanguage.bengali: return 'স্তর ৩ (চ্যালেঞ্জিং)';
        case AppLanguage.manipuri: return 'থাক ৩ (চেলেঞ্জিং)';
        case AppLanguage.bodo: return 'थाखो ३ (गोब्राब)';
        case AppLanguage.nepali: return 'तह ३ (चुनौतीपूर्ण)';
        case AppLanguage.mizo: return 'Level 3 (Harsa)';
        case AppLanguage.english: default: return 'Level 3 (Challenging)';
      }
    } else if (t.contains('level 4') || t.contains('master')) {
      switch (l) {
        case AppLanguage.hindi: return 'स्तर 4 (कुशल)';
        case AppLanguage.assamese: return 'স্তৰ ৪ (পাৰদৰ্শী)';
        case AppLanguage.bengali: return 'স্তর ৪ (মাস্টার)';
        case AppLanguage.manipuri: return 'থাক ৪ (মাষ্টর)';
        case AppLanguage.bodo: return 'थाखो ४ (उस्ताद)';
        case AppLanguage.nepali: return 'तह ४ (मास्टर)';
        case AppLanguage.mizo: return 'Level 4 (Thiam)';
        case AppLanguage.english: default: return 'Level 4 (Master)';
      }
    }
    return tier;
  }

  static String getSupportNote1(int totalSessions, String firstName, [AppLanguage? lang]) {
    final l = lang ?? instance.currentLanguage;
    switch (l) {
      case AppLanguage.hindi:
        return '$firstName द्वारा $totalSessions पूर्ण की गई गतिविधियाँ दर्ज की गईं।';
      case AppLanguage.assamese:
        return '$firstName ৰ দ্বাৰা $totalSessions টা কাৰ্যকলাপ সম্পন্ন হৈছে।';
      case AppLanguage.bengali:
        return '$firstName বাবু $totalSessions টি কার্যকলাপ সম্পন্ন করেছেন।';
      case AppLanguage.manipuri:
        return '$firstName না থবক $totalSessions লোইশিনখ্রে।';
      case AppLanguage.bodo:
        return '$firstName आ $totalSessions हाबाफारि फुंखांबाय।';
      case AppLanguage.nepali:
        return '$firstName द्वारा $totalSessions गतिविधिहरू पूरा गरियो।';
      case AppLanguage.mizo:
        return '$firstName-an activity $totalSessions a zo tawh.';
      case AppLanguage.english:
      default:
        return '$totalSessions recorded game activities completed by $firstName.';
    }
  }

  static String getSupportNote2(String scorePct, [AppLanguage? lang]) {
    final l = lang ?? instance.currentLanguage;
    switch (l) {
      case AppLanguage.hindi:
        return 'स्थिर बातचीत के साथ नवीनतम सत्र सटीकता $scorePct% दर्ज की गई।';
      case AppLanguage.assamese:
        return 'স্থিৰ প্ৰদৰ্শনৰ সৈতে শেহতীয়া সঠিকতা $scorePct% ৰেকৰ্ড কৰা হৈছে।';
      case AppLanguage.bengali:
        return 'স্থিতিশীল মিথস্ক্রিয়ার সাথে সর্বশেষ নির্ভুলতা $scorePct% রেকর্ড করা হয়েছে।';
      case AppLanguage.manipuri:
        return 'অরোইবা সেসনগী অচুম্বা চাং চাদা $scorePct নি।';
      case AppLanguage.bodo:
        return 'गोरोबनाय बिबां $scorePct% आनजाद मोनबाय।';
      case AppLanguage.nepali:
        return 'स्थिर अन्तरक्रियाका साथ पछिल्लो शुद्धता $scorePct% रेकर्ड गरियो।';
      case AppLanguage.mizo:
        return 'Session hnuhnung ber dikna chu $scorePct% a ni.';
      case AppLanguage.english:
      default:
        return 'Latest session accuracy recorded at $scorePct% with steady interaction.';
    }
  }

  static String getSupportNote3([AppLanguage? lang]) {
    final l = lang ?? instance.currentLanguage;
    switch (l) {
      case AppLanguage.hindi:
        return 'सुचारू शारीरिक गति और नियमित दैनिक दिनचर्या बनी हुई है।';
      case AppLanguage.assamese:
        return 'সুচাৰু শাৰীৰিক গতি আৰু নিয়মীয়া দিনচৰ্যা বজাই ৰখা হৈছে।';
      case AppLanguage.bengali:
        return 'মসৃণ গতি ও নিয়মিত দৈনিক রুটিন বজায় রয়েছে।';
      case AppLanguage.manipuri:
        return 'নোংমগী থৌরাং চুম্না চত্থরি।';
      case AppLanguage.bodo:
        return 'सानफ्रोमनि हाबाफारिया मोजाङै जाबाय थादों।';
      case AppLanguage.nepali:
        return 'नियमित दैनिक दिनचर्या र सहज गति कायम छ।';
      case AppLanguage.mizo:
        return 'Ni tin thiltih mumal takin a kal chho zel.';
      case AppLanguage.english:
      default:
        return 'Smooth motor interaction and consistent daily routine maintained.';
    }
  }

  static String trCarePlanTitle(String title, [AppLanguage? lang]) {
    final l = lang ?? instance.currentLanguage;
    final t = title.toLowerCase();
    if (t.contains('donepezil')) {
      switch (l) {
        case AppLanguage.hindi: return 'डोनिपेजिल 5mg (Donepezil)';
        case AppLanguage.assamese: return 'ডনেপেজিল 5mg';
        case AppLanguage.bengali: return 'ডনেপেজিল ৫ মিলিগ্রাম';
        case AppLanguage.manipuri: return 'ডোনেপেজিল 5mg';
        case AppLanguage.bodo: return 'दनेपेजिल 5mg';
        case AppLanguage.nepali: return 'डोनिपेजिल ५ एमजी';
        case AppLanguage.mizo: return 'Donepezil 5mg';
        case AppLanguage.english: default: return 'Donepezil 5mg';
      }
    } else if (t.contains('memantine')) {
      switch (l) {
        case AppLanguage.hindi: return 'मेमेंटाइन 10mg (Memantine)';
        case AppLanguage.assamese: return 'মেমেণ্টাইন 10mg';
        case AppLanguage.bengali: return 'মেম্যান্টাইন ১০ মিলিগ্রাম';
        case AppLanguage.manipuri: return 'মেমন্টাইন 10mg';
        case AppLanguage.bodo: return 'मेमान्तिन 10mg';
        case AppLanguage.nepali: return 'मेमेन्टाइन १० एमजी';
        case AppLanguage.mizo: return 'Memantine 10mg';
        case AppLanguage.english: default: return 'Memantine 10mg';
      }
    } else if (t.contains('visual pattern')) {
      switch (l) {
        case AppLanguage.hindi: return 'दृश्य पैटर्न अभ्यास (Visual Pattern)';
        case AppLanguage.assamese: return 'দৃশ্য পেটাৰ্ণ অনুশীলন';
        case AppLanguage.bengali: return 'ভিজ্যুয়াল প্যাটার্ন ব্যায়াম';
        case AppLanguage.manipuri: return 'ভিজুএল পেতর্ন এক্সরসাইজ';
        case AppLanguage.bodo: return 'नुनाय महर आनजाद';
        case AppLanguage.nepali: return 'दृश्य ढाँचा अभ्यास';
        case AppLanguage.mizo: return 'Thil Lem Inmilh Enkawlna';
        case AppLanguage.english: default: return 'Visual Pattern Exercise';
      }
    } else if (t.contains('kinematic')) {
      switch (l) {
        case AppLanguage.hindi: return 'हाथ कंपन स्थिरीकरण (Kinematic Arm)';
        case AppLanguage.assamese: return 'হাত কঁপা স্থিৰিকৰণ (Kinematic)';
        case AppLanguage.bengali: return 'কাইনেমেটিক হাত স্থিরীকরণ';
        case AppLanguage.manipuri: return 'খুৎ কন্বা থিংবা (Kinematic)';
        case AppLanguage.bodo: return 'आथिं-आखाय थि खालामनाय';
        case AppLanguage.nepali: return 'हात कम्पन स्थिरीकरण';
        case AppLanguage.mizo: return 'Kut Khur Tihtlemna (Kinematic)';
        case AppLanguage.english: default: return 'Kinematic Arm Stabilization';
      }
    } else if (t.contains('hydration') || t.contains('fruit')) {
      switch (l) {
        case AppLanguage.hindi: return 'पानी और ताजे फल (Hydration & Fruit)';
        case AppLanguage.assamese: return 'পানী আৰু ফলমূল গ্ৰহণ';
        case AppLanguage.bengali: return 'জলপান ও তাজা ফল';
        case AppLanguage.manipuri: return 'ঈশিং অমসুং হৈহিং চাবা';
        case AppLanguage.bodo: return 'दै आरो फिथाइ जाफुंनाय';
        case AppLanguage.nepali: return 'पानी र ताजा फलफूल';
        case AppLanguage.mizo: return 'Tui In & Thei Ei';
        case AppLanguage.english: default: return 'Hydration & Fruit snack';
      }
    }
    return title;
  }

  static String trCarePlanFreq(String freq, [AppLanguage? lang]) {
    final l = lang ?? instance.currentLanguage;
    final f = freq.toLowerCase();
    if (f.contains('breakfast')) {
      switch (l) {
        case AppLanguage.hindi: return 'नाश्ते के साथ प्रतिदिन';
        case AppLanguage.assamese: return 'ৰাতিপুৱাৰ জলপানৰ সৈতে';
        case AppLanguage.bengali: return 'সকালের নাস্তার সাথে প্রতিদিন';
        case AppLanguage.manipuri: return 'নুমিদাং য়ুক্না চাবা';
        case AppLanguage.bodo: return 'फुंनि जामुं जों लोगोसे';
        case AppLanguage.nepali: return 'बिहानको खाजासँगै';
        case AppLanguage.mizo: return 'Tukthuan eikhamah';
        case AppLanguage.english: default: return 'Daily with breakfast';
      }
    } else if (f.contains('dinner')) {
      switch (l) {
        case AppLanguage.hindi: return 'रात के खाने के साथ प्रतिदिन';
        case AppLanguage.assamese: return 'ৰাতিৰ আহাৰৰ সৈতে';
        case AppLanguage.bengali: return 'রাতের খাবারের সাথে প্রতিদিন';
        case AppLanguage.manipuri: return 'নুমিদাং চাক্কা লোয়ননা';
        case AppLanguage.bodo: return 'होरनि जामुं जों लोगोसे';
        case AppLanguage.nepali: return 'रातिको खानासँगै';
        case AppLanguage.mizo: return 'Zanriah eikhamah';
        case AppLanguage.english: default: return 'Daily with dinner';
      }
    } else if (f.contains('morning session')) {
      switch (l) {
        case AppLanguage.hindi: return 'सुबह का सत्र';
        case AppLanguage.assamese: return 'ৰাতিপুৱাৰ সত্ৰ';
        case AppLanguage.bengali: return 'সকালের সেশন';
        case AppLanguage.manipuri: return 'অয়ুক্কী সেসন';
        case AppLanguage.bodo: return 'फुंनि हाबाफारि';
        case AppLanguage.nepali: return 'बिहानको सत्र';
        case AppLanguage.mizo: return 'Zing session';
        case AppLanguage.english: default: return 'Morning session';
      }
    } else if (f.contains('esp32') || f.contains('utensil')) {
      switch (l) {
        case AppLanguage.hindi: return 'सक्रिय ESP32 उपकरण';
        case AppLanguage.assamese: return 'সক্ৰিয় ESP32 ডিভাইচ';
        case AppLanguage.bengali: return 'সক্রিয় ESP32 ডিভাইস';
        case AppLanguage.manipuri: return 'ESP32 খুৎলাই';
        case AppLanguage.bodo: return 'गोसोहोनाय ESP32 आगजु';
        case AppLanguage.nepali: return 'सक्रिय ESP32 उपकरण';
        case AppLanguage.mizo: return 'ESP32 hmanraw hmangin';
        case AppLanguage.english: default: return 'Active ESP32 Utensil';
      }
    } else if (f.contains('routine')) {
      switch (l) {
        case AppLanguage.hindi: return 'दैनिक दिनचर्या';
        case AppLanguage.assamese: return 'দৈনিক দিনচৰ্যা';
        case AppLanguage.bengali: return 'দৈনিক রুটিন';
        case AppLanguage.manipuri: return 'নোংমগী থবক';
        case AppLanguage.bodo: return 'सानफ्रोमनि हाबाफारि';
        case AppLanguage.nepali: return 'दैनिक दिनचर्या';
        case AppLanguage.mizo: return 'Ni tin thiltih';
        case AppLanguage.english: default: return 'Daily routine';
      }
    }
    return freq;
  }

  static String trCarePlanType(String type, [AppLanguage? lang]) {
    final l = lang ?? instance.currentLanguage;
    switch (type.toLowerCase()) {
      case 'medication':
        switch (l) {
          case AppLanguage.hindi: return 'दवा';
          case AppLanguage.assamese: return 'ঔষধ';
          case AppLanguage.bengali: return 'ওষুধ';
          case AppLanguage.manipuri: return 'হিদাক';
          case AppLanguage.bodo: return 'मुलि';
          case AppLanguage.nepali: return 'औषधि';
          case AppLanguage.mizo: return 'Damdawi';
          case AppLanguage.english: default: return 'Medication';
        }
      case 'cognitive':
        switch (l) {
          case AppLanguage.hindi: return 'संज्ञानात्मक';
          case AppLanguage.assamese: return 'জ্ঞানীয়';
          case AppLanguage.bengali: return 'জ্ঞানীয়';
          case AppLanguage.manipuri: return 'নিংশিংবা';
          case AppLanguage.bodo: return 'गोसोनि';
          case AppLanguage.nepali: return 'संज्ञानात्मक';
          case AppLanguage.mizo: return 'Hriatna';
          case AppLanguage.english: default: return 'Cognitive';
        }
      case 'motor care':
        switch (l) {
          case AppLanguage.hindi: return 'शारीरिक गति';
          case AppLanguage.assamese: return 'গতি যত্ন';
          case AppLanguage.bengali: return 'শারীরিক যত্ন';
          case AppLanguage.manipuri: return 'হকচাংগী যত্ন';
          case AppLanguage.bodo: return 'आथिं-आखाय';
          case AppLanguage.nepali: return 'शारीरिक हेरचाह';
          case AppLanguage.mizo: return 'Taksa chetna';
          case AppLanguage.english: default: return 'Motor Care';
        }
      case 'dietary':
        switch (l) {
          case AppLanguage.hindi: return 'आहार';
          case AppLanguage.assamese: return 'খাদ্যতালিকা';
          case AppLanguage.bengali: return 'খাদ্যাভ্যাস';
          case AppLanguage.manipuri: return 'চিনাক-মচাং';
          case AppLanguage.bodo: return 'जाफुं-आहार';
          case AppLanguage.nepali: return 'आहार';
          case AppLanguage.mizo: return 'Chaw ei';
          case AppLanguage.english: default: return 'Dietary';
        }
      default:
        return type;
    }
  }

  static String trDayLabel(String day, [AppLanguage? lang]) {
    final l = lang ?? instance.currentLanguage;
    final d = day.toLowerCase();
    if (d == 'mon') {
      switch (l) {
        case AppLanguage.hindi: return 'सोम';
        case AppLanguage.assamese: return 'সোম';
        case AppLanguage.bengali: return 'সোম';
        case AppLanguage.manipuri: return 'নিংথৌ';
        case AppLanguage.bodo: return 'सम';
        case AppLanguage.nepali: return 'सोम';
        case AppLanguage.mizo: return 'Thawh';
        case AppLanguage.english: default: return 'Mon';
      }
    } else if (d == 'tue') {
      switch (l) {
        case AppLanguage.hindi: return 'मंगल';
        case AppLanguage.assamese: return 'মঙ্গল';
        case AppLanguage.bengali: return 'মঙ্গল';
        case AppLanguage.manipuri: return 'লৈপাক';
        case AppLanguage.bodo: return 'मंगलबार';
        case AppLanguage.nepali: return 'मङ्गल';
        case AppLanguage.mizo: return 'Thawhleh';
        case AppLanguage.english: default: return 'Tue';
      }
    } else if (d == 'wed') {
      switch (l) {
        case AppLanguage.hindi: return 'बुध';
        case AppLanguage.assamese: return 'বুধ';
        case AppLanguage.bengali: return 'বুধ';
        case AppLanguage.manipuri: return 'য়ুমসকৈসা';
        case AppLanguage.bodo: return 'बुधबार';
        case AppLanguage.nepali: return 'बुध';
        case AppLanguage.mizo: return 'Nilai';
        case AppLanguage.english: default: return 'Wed';
      }
    } else if (d == 'thu') {
      switch (l) {
        case AppLanguage.hindi: return 'गुरु';
        case AppLanguage.assamese: return 'বৃহস্পতি';
        case AppLanguage.bengali: return 'বৃহস্পতি';
        case AppLanguage.manipuri: return 'সগোলসেন';
        case AppLanguage.bodo: return 'बिसथि';
        case AppLanguage.nepali: return 'बिही';
        case AppLanguage.mizo: return 'Ningani';
        case AppLanguage.english: default: return 'Thu';
      }
    } else if (d == 'fri') {
      switch (l) {
        case AppLanguage.hindi: return 'शुक्र';
        case AppLanguage.assamese: return 'শুক্ৰ';
        case AppLanguage.bengali: return 'শুক্র';
        case AppLanguage.manipuri: return 'ইরাই';
        case AppLanguage.bodo: return 'सुखुरबार';
        case AppLanguage.nepali: return 'शुक्र';
        case AppLanguage.mizo: return 'Zirtawp';
        case AppLanguage.english: default: return 'Fri';
      }
    } else if (d == 'sat') {
      switch (l) {
        case AppLanguage.hindi: return 'शनि';
        case AppLanguage.assamese: return 'শনি';
        case AppLanguage.bengali: return 'শনি';
        case AppLanguage.manipuri: return 'থাংজা';
        case AppLanguage.bodo: return 'सुनिबार';
        case AppLanguage.nepali: return 'शनि';
        case AppLanguage.mizo: return 'Inrin';
        case AppLanguage.english: default: return 'Sat';
      }
    } else if (d == 'today') {
      switch (l) {
        case AppLanguage.hindi: return 'आज';
        case AppLanguage.assamese: return 'আজি';
        case AppLanguage.bengali: return 'আজ';
        case AppLanguage.manipuri: return 'ঙসি';
        case AppLanguage.bodo: return 'दिनै';
        case AppLanguage.nepali: return 'आज';
        case AppLanguage.mizo: return 'Vawiin';
        case AppLanguage.english: default: return 'Today';
      }
    }
    return day;
  }

  static String trDomainName(String name, [AppLanguage? lang]) {
    final l = lang ?? instance.currentLanguage;
    final n = name.toLowerCase();
    if (n.contains('working memory')) {
      switch (l) {
        case AppLanguage.hindi: return 'कार्यकारी स्मृति (Memory Match)';
        case AppLanguage.assamese: return 'কাৰ্যকৰী স্মৃতি (Memory Match)';
        case AppLanguage.bengali: return 'কার্যকরী স্মৃতি (Memory Match)';
        case AppLanguage.manipuri: return 'নিংশিংবা (Memory Match)';
        case AppLanguage.bodo: return 'गोसोआव दोननाय (Memory Match)';
        case AppLanguage.nepali: return 'कार्यकारी स्मरण (Memory Match)';
        case AppLanguage.mizo: return 'Hriatrengna (Memory Match)';
        case AppLanguage.english: default: return 'Working Memory (Memory Match)';
      }
    } else if (n.contains('adl') || n.contains('procedural')) {
      switch (l) {
        case AppLanguage.hindi: return 'दैनिक दिनचर्या अनुक्रम (Chai & Plants)';
        case AppLanguage.assamese: return 'দৈনিক দিনচৰ্যা প্ৰক্ৰিয়া (Chai & Plants)';
        case AppLanguage.bengali: return 'দৈনিক রুটিন ক্রম (Chai & Plants)';
        case AppLanguage.manipuri: return 'নোংমগী থৌরাং (Chai & Plants)';
        case AppLanguage.bodo: return 'सानफ्रोमनि फारि (Chai & Plants)';
        case AppLanguage.nepali: return 'दैनिक कार्य अनुक्रम (Chai & Plants)';
        case AppLanguage.mizo: return 'Ni tin thiltih indawt (Chai & Plants)';
        case AppLanguage.english: default: return 'ADL Procedural Flow (Chai & Plants)';
      }
    } else if (n.contains('spatial') || n.contains('clock canvas')) {
      switch (l) {
        case AppLanguage.hindi: return 'स्थानिक और कार्यकारी योजना (Clock Canvas)';
        case AppLanguage.assamese: return 'স্থানিক আৰু কাৰ্যনিৰ্বাহক পৰিকল্পনা (Clock Canvas)';
        case AppLanguage.bengali: return 'স্থানিক ও কার্যনির্বাহী পরিকল্পনা (Clock Canvas)';
        case AppLanguage.manipuri: return 'স্পেসিয়েল অমসুং এক্সেক্যুতিভ (Clock Canvas)';
        case AppLanguage.bodo: return 'जायगा आरो घडी आनजाद (Clock Canvas)';
        case AppLanguage.nepali: return 'स्थानिक तथा योजना क्षमता (Clock Canvas)';
        case AppLanguage.mizo: return 'Sana lem ruahmanna (Clock Canvas)';
        case AppLanguage.english: default: return 'Spatial & Executive Planning (Clock Canvas)';
      }
    } else if (n.contains('tremor') || n.contains('dampening')) {
      switch (l) {
        case AppLanguage.hindi: return 'कंपन नियंत्रण और शारीरिक शांति';
        case AppLanguage.assamese: return 'হাত কঁপনি নিয়ন্ত্ৰণ আৰু স্থিৰতা';
        case AppLanguage.bengali: return 'কম্পন নিয়ন্ত্রণ ও শারীরিক প্রশান্তি';
        case AppLanguage.manipuri: return 'খুৎ কন্বা থিংবা অমসুং শান্ত';
        case AppLanguage.bodo: return 'आखाय खौनाय होबथानाय';
        case AppLanguage.nepali: return 'हात कम्पन नियन्त्रण र शारीरिक शान्ति';
        case AppLanguage.mizo: return 'Kut khur vawnfimkhurna';
        case AppLanguage.english: default: return 'Tremor Dampening & Kinematic Calm';
      }
    } else if (n.contains('adherence') || n.contains('reminder')) {
      switch (l) {
        case AppLanguage.hindi: return 'दैनिक अनुस्मारक अनुपालन';
        case AppLanguage.assamese: return 'দৈনিক সোঁৱৰণী পালন';
        case AppLanguage.bengali: return 'দৈনিক রিমাইন্ডার মেনে চলা';
        case AppLanguage.manipuri: return 'নোংমগী নিংশিংবা ঙাক্না চৎপা';
        case AppLanguage.bodo: return 'सानफ्रोमनि गोसोखांथि मानिनाय';
        case AppLanguage.nepali: return 'दैनिक रिमाइन्डर पालना';
        case AppLanguage.mizo: return 'Ni tin hriattirna zawm dan';
        case AppLanguage.english: default: return 'Daily Reminder Adherence';
      }
    }
    return name;
  }

  static String trDomainDesc(String desc, [AppLanguage? lang]) {
    final l = lang ?? instance.currentLanguage;
    final d = desc.toLowerCase();
    if (d.contains('strong recognition')) {
      switch (l) {
        case AppLanguage.hindi: return 'मजबूत पहचान';
        case AppLanguage.assamese: return 'দৃঢ় চিনাক্তকৰণ';
        case AppLanguage.bengali: return 'দৃঢ় সনাক্তকরণ';
        case AppLanguage.manipuri: return 'অচেৎপা মশক খঙবা';
        case AppLanguage.bodo: return 'मोजां सिनायथि';
        case AppLanguage.nepali: return 'बलियो पहिचान';
        case AppLanguage.mizo: return 'Hriatna chak tha';
        case AppLanguage.english: default: return 'Strong recognition';
      }
    } else if (d.contains('sequence recall')) {
      switch (l) {
        case AppLanguage.hindi: return 'उत्कृष्ट अनुक्रम स्मरण';
        case AppLanguage.assamese: return 'উৎকৃষ্ট ক্ৰম সোঁৱৰণ';
        case AppLanguage.bengali: return 'চমৎকার ক্রম স্মরণ';
        case AppLanguage.manipuri: return 'ফবা নিংশিংবা';
        case AppLanguage.bodo: return 'जोबोद मोजां गोसोखांथि';
        case AppLanguage.nepali: return 'उत्कृष्ट क्रम स्मरण';
        case AppLanguage.mizo: return 'Indawt theihna tha';
        case AppLanguage.english: default: return 'Excellent sequence recall';
      }
    } else if (d.contains('accurate contour')) {
      switch (l) {
        case AppLanguage.hindi: return 'सटीक रूपरेखा और सुइयां';
        case AppLanguage.assamese: return 'সঠিক আকৃতি আৰু কাঁটা';
        case AppLanguage.bengali: return 'সঠিক রূপরেখা ও কাঁটা';
        case AppLanguage.manipuri: return 'চুম্বা মওং অমসুং কাটা';
        case AppLanguage.bodo: return 'थि महर आरो कांटा';
        case AppLanguage.nepali: return 'सटीक रूपरेखा र सुई';
        case AppLanguage.mizo: return 'Sana kutzung dik tak';
        case AppLanguage.english: default: return 'Accurate contour & hands';
      }
    } else if (d.contains('jitter') || d.contains('stabilized')) {
      switch (l) {
        case AppLanguage.hindi: return '4-12 Hz कंपन स्थिर';
        case AppLanguage.assamese: return '৪-১২ Hz কঁপনি স্থিৰিকৃত';
        case AppLanguage.bengali: return '৪-১২ Hz কম্পন প্রশমিত';
        case AppLanguage.manipuri: return '৪-১২ Hz কন্বা থিংখ্রে';
        case AppLanguage.bodo: return '४-१२ Hz खौनाय थि खालामबाय';
        case AppLanguage.nepali: return '४-१२ Hz कम्पन स्थिर';
        case AppLanguage.mizo: return '4-12 Hz khurna tihtlem';
        case AppLanguage.english: default: return '4-12 Hz jitter stabilized';
      }
    } else if (d.contains('active daily')) {
      switch (l) {
        case AppLanguage.hindi: return 'सक्रिय दैनिक दिनचर्या';
        case AppLanguage.assamese: return 'সক্ৰিয় দৈনিক দিনচৰ্যা';
        case AppLanguage.bengali: return 'সক্রিয় দৈনিক রুটিন';
        case AppLanguage.manipuri: return 'নোংমগী থবক সোইদনা চৎপা';
        case AppLanguage.bodo: return 'सानफ्रोमनि हाबाफारि सोलिबाय थादों';
        case AppLanguage.nepali: return 'सक्रिय दैनिक दिनचर्या';
        case AppLanguage.mizo: return 'Ni tin thiltih tha taka zawm';
        case AppLanguage.english: default: return 'Active daily routine';
      }
    }
    return desc;
  }

  static String trMilestoneTitle(String title, [AppLanguage? lang]) {
    final l = lang ?? instance.currentLanguage;
    final t = title.toLowerCase();
    if (t.contains('clock contour')) {
      switch (l) {
        case AppLanguage.hindi: return 'घड़ी रूपरेखा और सुई स्थापन पूर्ण';
        case AppLanguage.assamese: return 'ঘড়ী চিত্ৰাংকন আৰু কাঁটা স্থাপন সম্পূৰ্ণ';
        case AppLanguage.bengali: return 'ঘড়ির রূপরেখা ও কাঁটা স্থাপন সম্পন্ন';
        case AppLanguage.manipuri: return 'ঘড়ী য়েকপা অমসুং কাটা থম্বা লোইশিনখ্রে';
        case AppLanguage.bodo: return 'घडी आखिनाय आरो कांटा दोननाय आबुं जाबाय';
        case AppLanguage.nepali: return 'घडीको रूपरेखा र सुई राख्ने काम पूरा भयो';
        case AppLanguage.mizo: return 'Sana lem ziah leh kutzung dah zawh a ni';
        case AppLanguage.english: default: return 'Clock Contour & Hand Placement Completed';
      }
    } else if (t.contains('memory match')) {
      switch (l) {
        case AppLanguage.hindi: return 'स्मृति मिलान जोड़े हल किए (स्तर 2)';
        case AppLanguage.assamese: return 'স্মৃতি মিলান জোৰা সমাধান কৰা হ’ল (স্তৰ ২)';
        case AppLanguage.bengali: return 'মেমরি ম্যাচ জোড়া সমাধান (স্তর ২)';
        case AppLanguage.manipuri: return 'মেমোরি মেচ পেরে সমাধান তৌখ্রে (থাক ২)';
        case AppLanguage.bodo: return 'गोसोआव दोननाय जोरा आनजाद (थाखो २)';
        case AppLanguage.nepali: return 'स्मृति मिलान जोडी समाधान गरियो (तह २)';
        case AppLanguage.mizo: return 'Hriatrengna Inmilh a zo fel (Level 2)';
        case AppLanguage.english: default: return 'Memory Match Pairs Solved (Level 2)';
      }
    } else if (t.contains('chai') || t.contains('making morning chai')) {
      switch (l) {
        case AppLanguage.hindi: return 'दैनिक दिनचर्या: सुबह की चाय बनाना अनुक्रमित';
        case AppLanguage.assamese: return 'দৈনিক দিনচৰ্যা: ৰাতিপুৱাৰ চাহ বনোৱা সম্পূৰ্ণ';
        case AppLanguage.bengali: return 'দৈনিক রুটিন: সকালের চা তৈরির ক্রম সম্পন্ন';
        case AppLanguage.manipuri: return 'নোংমগী থবক: অয়ুক্কী চা শাবা লোইশিনখ্রে';
        case AppLanguage.bodo: return 'सानफ्रोमनि हाबा: फुंनि साहा बानायनाय फारि';
        case AppLanguage.nepali: return 'दैनिक दिनचर्या: बिहानको चिया बनाउने क्रम पूरा भयो';
        case AppLanguage.mizo: return 'Ni tin thiltih: Zing thingpui lum dan indawt';
        case AppLanguage.english: default: return 'Daily Routine: Making Morning Chai Sequenced';
      }
    } else if (t.contains('esp32') || t.contains('bio-tremor')) {
      switch (l) {
        case AppLanguage.hindi: return 'ESP32 बायो-कंपन सेंसर फ़िल्टरिंग सक्रिय';
        case AppLanguage.assamese: return 'ESP32 বায়’-ট্ৰেমৰ চেন্সৰ সক্ৰিয়';
        case AppLanguage.bengali: return 'ESP32 বায়ো-কম্পন সেন্সর ফিল্টারিং সক্রিয়';
        case AppLanguage.manipuri: return 'ESP32 সেন্সর এক্তিব লৈরে';
        case AppLanguage.bodo: return 'ESP32 आखाय खौनाय सेन्सर सोलिदों';
        case AppLanguage.nepali: return 'ESP32 कम्पन सेन्सर सक्रिय';
        case AppLanguage.mizo: return 'ESP32 Kut khur filter a nung e';
        case AppLanguage.english: default: return 'ESP32 Bio-Tremor Sensor Filtering Active';
      }
    }
    return title;
  }

  static String trMilestoneSubtitle(String sub, [AppLanguage? lang]) {
    final l = lang ?? instance.currentLanguage;
    final s = sub.toLowerCase();
    if (s.contains('clinical score') && s.contains('spatial')) {
      switch (l) {
        case AppLanguage.hindi: return 'नैदानिक स्कोर 8.5/10 · आज, 09:15 AM · स्थानिक योजना';
        case AppLanguage.assamese: return 'স্কোৰ ৮.৫/১০ · আজি, ০৯:১৫ AM · স্থানিক পৰিকল্পনা';
        case AppLanguage.bengali: return 'ক্লিনিক্যাল স্কোর ৮.৫/১০ · আজ, ০৯:১৫ AM · স্থানিক পরিকল্পনা';
        case AppLanguage.manipuri: return 'ক্লিনিকেল স্কোর ৮.৫/১০ · ঙসি, ০৯:১৫ AM';
        case AppLanguage.bodo: return 'अनजिमा ८.५/१० · दिनै, ०९:१५ AM';
        case AppLanguage.nepali: return 'क्लिनिकल स्कोर ८.५/१० · आज, ०९:१५ AM · स्थानिक योजना';
        case AppLanguage.mizo: return 'Clinical score 8.5/10 · Vawiin, 09:15 AM · Hmun awmze ruahmanna';
        case AppLanguage.english: default: return 'Clinical score 8.5/10 · Today, 09:15 AM · Spatial Planning';
      }
    } else if (s.contains('turn accuracy') || s.contains('12 moves')) {
      switch (l) {
        case AppLanguage.hindi: return 'सटीकता 86% · 12 चालें · आज, 08:45 AM';
        case AppLanguage.assamese: return 'সঠিকতা ৮৬% · ১২ টা খোজ · আজি, ০৮:৪৫ AM';
        case AppLanguage.bengali: return 'নির্ভুলতা ৮৬% · ১২টি চাল · আজ, ০৮:৪৫ AM';
        case AppLanguage.manipuri: return 'অচুম্বা ৮৬% · খোঙথাং ১২ · ঙসি, ০৮:৪৫ AM';
        case AppLanguage.bodo: return 'गोरोबनाय ८६% · १२ खोलोब · दिनै, ०८:४५ AM';
        case AppLanguage.nepali: return 'शुद्धता ८६% · १२ चाल · आज, ०८:४५ AM';
        case AppLanguage.mizo: return 'Dik zat 86% · Chetdan 12 · Vawiin, 08:45 AM';
        case AppLanguage.english: default: return 'Turn accuracy 86% · 12 moves · Today, 08:45 AM';
      }
    } else if (s.contains('procedural sequence') || s.contains('3.2 mins')) {
      switch (l) {
        case AppLanguage.hindi: return '4-चरणीय अनुक्रम 3.2 मिनट में पूर्ण · कल';
        case AppLanguage.assamese: return '৪-পদক্ষেপৰ ক্ৰম ৩.২ মিনিটত সম্পূৰ্ণ · কালি';
        case AppLanguage.bengali: return '৪-ধাপের প্রক্রিয়া ৩.২ মিনিটে সম্পন্ন · গতকাল';
        case AppLanguage.manipuri: return 'স্তেক ৪ গী থবক মিনিট ৩.২ দা লোইশিনখ্রে · ঙরাং';
        case AppLanguage.bodo: return '४-थाखो हाबाफारि ३.२ मिनिटआव जोबबाय · मिया';
        case AppLanguage.nepali: return '४-चरणको प्रक्रिया ३.२ मिनेटमा पूरा · हिजो';
        case AppLanguage.mizo: return 'Step 4 awm chu minute 3.2 chhungin a zo · Nimin';
        case AppLanguage.english: default: return '4-step procedural sequence completed in 3.2 mins · Yesterday';
      }
    } else if (s.contains('parkinsonian') || s.contains('neutralized')) {
      switch (l) {
        case AppLanguage.hindi: return '4-12 Hz कंपन संतुलित · 6 सितं, 02:30 PM';
        case AppLanguage.assamese: return '৪-১২ Hz কঁপনি নিয়ন্ত্ৰিত · ৬ ছেপ্টেম্বৰ, ০২:৩০ PM';
        case AppLanguage.bengali: return '৪-১২ Hz কম্পন নিয়ন্ত্রিত · ৬ সেপ্টেম্বর, ০২:৩০ PM';
        case AppLanguage.manipuri: return '৪-১২ Hz কন্বা থিংখ্রে · ৬ সেপ্তেম্বর, ০২:৩০ PM';
        case AppLanguage.bodo: return '४-१२ Hz आखाय खौनाय थि खालामबाय · ६ सेप्टेम्बर, ०२:३० PM';
        case AppLanguage.nepali: return '४-१२ Hz कम्पन नियन्त्रित · ६ सेप्टेम्बर, ०२:३० PM';
        case AppLanguage.mizo: return '4-12 Hz khurna tihtlem · 6 Sep, 02:30 PM';
        case AppLanguage.english: default: return '4-12 Hz Parkinsonian tremor neutralized · 6 Sep, 02:30 PM';
      }
    }
    return sub;
  }

  static String trMilestoneFilter(String filter, [AppLanguage? lang]) {
    final l = lang ?? instance.currentLanguage;
    switch (filter) {
      case 'Memory Match':
        switch (l) {
          case AppLanguage.hindi: return 'स्मृति मिलान';
          case AppLanguage.assamese: return 'স্মৃতি মিলান';
          case AppLanguage.bengali: return 'মেমরি ম্যাচ';
          case AppLanguage.manipuri: return 'মেমোরি মেচ';
          case AppLanguage.bodo: return 'गोसोआव दोननाय';
          case AppLanguage.nepali: return 'स्मृति मिलान';
          case AppLanguage.mizo: return 'Memory Match';
          case AppLanguage.english: default: return 'Memory Match';
        }
      case 'Routine Sequencer':
        switch (l) {
          case AppLanguage.hindi: return 'दिनचर्या अनुक्रमक';
          case AppLanguage.assamese: return 'দিনচৰ্যা অনুক্ৰমক';
          case AppLanguage.bengali: return 'রুটিন সিকোয়েন্সার';
          case AppLanguage.manipuri: return 'থৌরাং অনুক্রমক';
          case AppLanguage.bodo: return 'हाबाफारि फारि';
          case AppLanguage.nepali: return 'दिनचर्या अनुक्रमक';
          case AppLanguage.mizo: return 'Routine Sequencer';
          case AppLanguage.english: default: return 'Routine Sequencer';
        }
      case 'Clock Drawing':
        switch (l) {
          case AppLanguage.hindi: return 'घड़ी चित्रांकन';
          case AppLanguage.assamese: return 'ঘড়ী চিত্ৰাংকন';
          case AppLanguage.bengali: return 'ঘড়ি অঙ্কন';
          case AppLanguage.manipuri: return 'ঘড়ী য়েকপা';
          case AppLanguage.bodo: return 'घडी आखिनाय';
          case AppLanguage.nepali: return 'घडी चित्रांकन';
          case AppLanguage.mizo: return 'Clock Drawing';
          case AppLanguage.english: default: return 'Clock Drawing';
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
      'your_journey': 'YOUR JOURNEY',
      'progress_wellness': 'Progress & Wellness',
      'progress_wellness_sub': 'Real-time cognitive trajectory and sensor stabilization summary.',
      'listen_to_report': 'Listen to Report',
      'daily_streak': 'DAILY STREAK',
      'seven_days': '7 Days',
      'consistency_streak': 'Consistency Streak',
      'adherence_this_week': 'Active adherence this week',
      'sessions_caps': 'SESSIONS',
      'completed_caps': 'Completed',
      'cognitive_activities': 'Cognitive Activities',
      'completed_this_week': 'Completed this week',
      'accuracy_caps': 'ACCURACY',
      'working_memory_score': 'Working Memory Score',
      'progression_vs_baseline': 'Progression vs baseline (+8%)',
      'kinematics_caps': 'KINEMATICS',
      'motor_posture_balance': 'Motor & Tremor Stability',
      'sensor_stabilized': 'Sensor-stabilized interaction',
      'weekly_accuracy_trend': 'Weekly Accuracy Trend',
      'motor_stability_index': 'Motor Tremor Stability Index',
      'tap_data_points': 'Tap data points to inspect recorded score & notes',
      'realtime_imu_curve': 'Kinematic filter dampening tremor response',
      'memory_tab': 'Memory',
      'stability_tab': 'Stability',
      'recorded_session_score': 'Recorded Session Accuracy',
      'clinical_target': 'Clinical Baseline (70%)',
      'ai_confidence': 'AI Confidence 94%',
      'clinical_domains_title': 'Clinical Cognitive & Motor Domains',
      'clinical_domains_sub': 'Continuous tracking across 5 core rehabilitation dimensions.',
      'recent_milestones_title': 'Recent Clinical Milestones',
      'recent_milestones_sub': 'Real-time telemetry synced across patient exercises and ESP32 bio-sensors.',
      'ai_engine_live': 'AI ENGINE LIVE',
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
      'your_journey': 'आपकी प्रगति',
      'progress_wellness': 'प्रगति और स्वास्थ्य',
      'progress_wellness_sub': 'वास्तविक समय संज्ञानात्मक प्रक्षेपवक्र और सेंसर स्थिरीकरण सारांश।',
      'listen_to_report': 'रिपोर्ट सुनें',
      'daily_streak': 'दैनिक निरंतरता',
      'seven_days': '7 दिन',
      'consistency_streak': 'नियमितता रिकॉर्ड',
      'adherence_this_week': 'इस सप्ताह सक्रिय पालन',
      'sessions_caps': 'सत्र',
      'completed_caps': 'पूर्ण',
      'cognitive_activities': 'संज्ञानात्मक गतिविधियाँ',
      'completed_this_week': 'इस सप्ताह पूरा किया',
      'accuracy_caps': 'सटीकता',
      'working_memory_score': 'कार्यशील स्मृति स्कोर',
      'progression_vs_baseline': 'आधार रेखा की तुलना में सुधार (+8%)',
      'kinematics_caps': 'गतिशीलता',
      'motor_posture_balance': 'मोटर और कंपन स्थिरता',
      'sensor_stabilized': 'सेंसर-स्थिरीकृत इंटरैक्शन',
      'weekly_accuracy_trend': 'साप्ताहिक सटीकता रुझान',
      'motor_stability_index': 'मोटर कंपन स्थिरता सूचकांक',
      'tap_data_points': 'रिकॉर्ड किए गए स्कोर और नोट्स देखने के लिए बिंदुओं पर टैप करें',
      'realtime_imu_curve': 'कंपन प्रतिक्रिया को कम करने वाला काइनेमैटिक फ़िल्टर',
      'memory_tab': 'स्मृति',
      'stability_tab': 'स्थिरता',
      'recorded_session_score': 'रिकॉर्ड की गई सत्र सटीकता',
      'clinical_target': 'नैदानिक आधार रेखा (70%)',
      'ai_confidence': 'एआई विश्वास 94%',
      'clinical_domains_title': 'नैदानिक संज्ञानात्मक और मोटर डोमेन',
      'clinical_domains_sub': '5 मुख्य पुनर्वास आयामों में निरंतर निगरानी।',
      'recent_milestones_title': 'हाल की उपलब्धियां और सत्र',
      'recent_milestones_sub': 'रोगी के अभ्यासों और ESP32 बायो-सेंसरों से सिंक किया गया डेटा।',
      'ai_engine_live': 'एआई इंजन सक्रिय',
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
      'your_journey': 'আপোনাৰ যাত্ৰা',
      'progress_wellness': 'প্ৰগতি আৰু সুস্থতা',
      'progress_wellness_sub': 'প্ৰকৃত সময়ৰ বৌদ্ধিক গতিধাৰা আৰু সংবেদক স্থিৰিকৰণৰ সংক্ষিপ্ত বিৱৰণ।',
      'listen_to_report': 'প্ৰতিবেদন শুনক',
      'daily_streak': 'দৈনিক ধাৰাবাহিকতা',
      'seven_days': '৭ দিন',
      'consistency_streak': 'ধাৰাবাহিকতাৰ স্তৰ',
      'adherence_this_week': 'এই সপ্তাহত সক্ৰিয় উপস্থিতি',
      'sessions_caps': 'অধিবেশন',
      'completed_caps': 'সম্পন্ন',
      'cognitive_activities': 'বৌদ্ধিক কাৰ্যকলাপ',
      'completed_this_week': 'এই সপ্তাহত সম্পন্ন হৈছে',
      'accuracy_caps': 'সঠিকতা',
      'working_memory_score': 'কাৰ্যকৰী স্মৃতি স্ক’ৰ',
      'progression_vs_baseline': 'পূৰ্বৰ তুলনাত উন্নতি (+৮%)',
      'kinematics_caps': 'গতিশীলতা',
      'motor_posture_balance': 'শাৰীৰিক আৰু কঁপা স্থিৰতা',
      'sensor_stabilized': 'সংবেদক-স্থিৰিকৃত নিৰ্দেশনা',
      'weekly_accuracy_trend': 'সাপ্তাহিক সঠিকতাৰ ধাৰা',
      'motor_stability_index': 'শাৰীৰিক কঁপনি স্থিৰতা সূচক',
      'tap_data_points': 'ৰেকৰ্ড কৰা স্ক’ৰ চাবলৈ বিন্দুত স্পৰ্শ কৰক',
      'realtime_imu_curve': 'কঁপনি হ্ৰাস কৰা কাইনেমেটিক ফিল্টাৰ',
      'memory_tab': 'স্মৃতি',
      'stability_tab': 'স্থিৰতা',
      'recorded_session_score': 'ৰেকৰ্ড কৰা অধিবেশনৰ সঠিকতা',
      'clinical_target': 'চিকিৎসাজনিত স্তৰ (৭০%)',
      'ai_confidence': 'AI বিশ্বাসযোগ্যতা ৯৪%',
      'clinical_domains_title': 'চিকিৎসা বৌদ্ধিক আৰু শাৰীৰিক ক্ষেত্ৰ',
      'clinical_domains_sub': '৫টা মূল পুনৰ্বাসন ক্ষেত্ৰত অবিৰত নিৰীক্ষণ।',
      'recent_milestones_title': 'শেহতীয়া অগ্ৰগতি আৰু ইতিহাস',
      'recent_milestones_sub': 'ৰোগীৰ অনুশীলন আৰু ESP32 বায়’-সংবেদকৰ পৰা ছিংক হোৱা তথ্য।',
      'ai_engine_live': 'AI ইঞ্জিন সক্ৰিয়',
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
      'your_journey': 'আপনার অগ্রগতি',
      'progress_wellness': 'অগ্রগতি ও সুস্থতা',
      'progress_wellness_sub': 'রিয়েল-টাইম জ্ঞানীয় গতিপথ এবং সেন্সর স্থিতিশীলতার সারাংশ।',
      'listen_to_report': 'রিপোর্ট শুনুন',
      'daily_streak': 'দৈনিক ধারাবাহিকতা',
      'seven_days': '৭ দিন',
      'consistency_streak': 'ধারাবাহিকতা রেকর্ড',
      'adherence_this_week': 'এই সপ্তাহে সক্রিয় সম্পৃক্ততা',
      'sessions_caps': 'সেশন',
      'completed_caps': 'সম্পন্ন',
      'cognitive_activities': 'জ্ঞানীয় কার্যকলাপ',
      'completed_this_week': 'এই সপ্তাহে সম্পন্ন',
      'accuracy_caps': 'নির্ভুলতা',
      'working_memory_score': 'কার্যকরী স্মৃতি স্কোর',
      'progression_vs_baseline': 'ভিত্তিরেখার চেয়ে অগ্রগতি (+৮%)',
      'kinematics_caps': 'কাইনেমেটিক্স',
      'motor_posture_balance': 'মোটর ও কম্পন স্থিতিশীলতা',
      'sensor_stabilized': 'সেন্সর-স্থিতিশীল মিথস্ক্রিয়া',
      'weekly_accuracy_trend': 'সাপ্তাহিক নির্ভুলতার ধারা',
      'motor_stability_index': 'মোটর কম্পন স্থিতিশীলতা সূচক',
      'tap_data_points': 'রেকর্ড করা স্কোর ও নোট দেখতে পয়েন্টে ট্যাপ করুন',
      'realtime_imu_curve': 'কম্পন হ্রাসকারী কাইনেমেটিক ফিল্টার',
      'memory_tab': 'স্মৃতি',
      'stability_tab': 'স্থিতিশীলতা',
      'recorded_session_score': 'রেকর্ডকৃত সেশন নির্ভুলতা',
      'clinical_target': 'ক্লিনিকাল বেসলাইন (৭০%)',
      'ai_confidence': 'এআই নির্ভরযোগ্যতা ৯৪%',
      'clinical_domains_title': 'ক্লিনিকাল জ্ঞানীয় ও মোটর ডোমেন',
      'clinical_domains_sub': '৫টি মূল পুনর্বাসন ক্ষেত্রে অবিচ্ছিন্ন পর্যবেক্ষণ।',
      'recent_milestones_title': 'সাম্প্রতিক অগ্রগতি ও মাইলস্টোন',
      'recent_milestones_sub': 'রোগীর অনুশীলন ও ESP32 বায়ো-সেন্সর থেকে সিঙ্ক হওয়া ডেটা।',
      'ai_engine_live': 'এআই ইঞ্জিন লাইভ',
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
      'your_journey': 'নখোয়গী খোঙচৎ',
      'progress_wellness': 'চাউখৎপা অমসুং হকচাং ফনা লৈবা',
      'progress_wellness_sub': 'মতম চানা পুক্নীংগী খোঙচৎ অমসুং সেন্সরগী স্থিতি রিপোর্ত।',
      'listen_to_report': 'রিপোর্ত তাবীয়ু',
      'daily_streak': 'নোংমগী চত্থবা',
      'seven_days': 'নুমিৎ ৭',
      'consistency_streak': 'লেপ্তনা চত্থবা রেকোর্দ',
      'adherence_this_week': 'চয়োল অসিদা মপুং ফানা চত্থবা',
      'sessions_caps': 'সেসন',
      'completed_caps': 'লোইশিনবা',
      'cognitive_activities': 'ৱাখলগী থবকশিং',
      'completed_this_week': 'চয়োল অসিদা লোইশিনখ্রে',
      'accuracy_caps': 'অচুম্বা চাং',
      'working_memory_score': 'ৱাখলগী মেমোরি স্কোর',
      'progression_vs_baseline': 'হান্নগী চাংদগী হেনগৎলকপা (+৮%)',
      'kinematics_caps': 'খুৎ-শা খোঙচৎ',
      'motor_posture_balance': 'খুৎ কনবা থিংবগী স্থিতি',
      'sensor_stabilized': 'সেন্সরনা স্থিতি থম্বগী থবক',
      'weekly_accuracy_trend': 'চয়োলগী অচুম্বা চাংগী খোঙচৎ',
      'motor_stability_index': 'খুৎ কনবগী চাং য়েংশিনবা',
      'tap_data_points': 'স্কোর অমসুং নোদস য়েংনবা পোইন্ততা নাম্বিয়ু',
      'realtime_imu_curve': 'খুৎ কন্বা হন্থহন্নবা ফিল্তর',
      'memory_tab': 'মেমোরি',
      'stability_tab': 'স্থিতি',
      'recorded_session_score': 'রেকোর্দ তৌরবা সেসনগী চাং',
      'clinical_target': 'ক্লিনিকেল বেসলাইন (৭০%)',
      'ai_confidence': 'AI কনফিডেন্স ৯৪%',
      'clinical_domains_title': 'পুক্নীং অমসুং হকচাংগী ক্ষেত্রশিং',
      'clinical_domains_sub': 'মপুং ফাবা লম ৫ দা লেপ্তনা য়েংশিনবা।',
      'recent_milestones_title': 'হৌজিক্কী মায়পাকপশিং',
      'recent_milestones_sub': 'এক্সরসাইজ অমসুং ESP32 সেন্সরদগী সিঙ্ক তৌরবা দেতা।',
      'ai_engine_live': 'AI ইঞ্জিন লাইভ',
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
      'your_journey': 'नोंथांनि दावबायनाय',
      'progress_wellness': 'जौगानाय आरो गोरोबनाय',
      'progress_wellness_sub': 'थोंजों सोलो गोरोबनाय आरो सेन्सर थि खालामनाय खौरांथुं।',
      'listen_to_report': 'खौरांथुं खोनासौ',
      'daily_streak': 'सानफ्रोमनि थाखो',
      'seven_days': '७ सान',
      'consistency_streak': 'अराय थाग्रा फारिलाइ',
      'adherence_this_week': 'बे सप्ताहाव हाबा मावनाय',
      'sessions_caps': 'बाहागो',
      'completed_caps': 'फुंखांनाय',
      'cognitive_activities': 'सोलोनि हाबाफारिफोर',
      'completed_this_week': 'बे सप्ताहाव फुंखांबाय',
      'accuracy_caps': 'गोरोबनाय बिबां',
      'working_memory_score': 'हाबा मावग्रा गोसोखांनाय नम्बर',
      'progression_vs_baseline': 'सिगांनिख्रुइ मोजां जानाय (+८%)',
      'kinematics_caps': 'आथिं-आखाय सोमावनाय',
      'motor_posture_balance': 'मोदोम आरो आखाय थि',
      'sensor_stabilized': 'सेन्सर जों थि खालामनाय',
      'weekly_accuracy_trend': 'सप्ताहानि गोरोबनाय फारिलाइ',
      'motor_stability_index': 'आखाय सोमावनाय थि अनजिमा',
      'tap_data_points': 'नम्बर आरो लिरनाय नुनो थुनानै नाय',
      'realtime_imu_curve': 'सोमावनाय खम खालामग्रा',
      'memory_tab': 'गोसोखांनाय',
      'stability_tab': 'थि थासारि',
      'recorded_session_score': 'आनजाद खालामनाय गोरोबनाय',
      'clinical_target': 'थाखोनि बिबां (७०%)',
      'ai_confidence': 'AI फोथायनाय ९४%',
      'clinical_domains_title': 'गोसो आरो मोदोमनि बाहागो',
      'clinical_domains_sub': 'गाहाय ५ बाहागोआव नायबिजिरनाय।',
      'recent_milestones_title': 'दावगानायनि खौरांथुं',
      'recent_milestones_sub': 'आनजाद आरो ESP32 सेन्सरनिफ्राय फैनाय खौरां।',
      'ai_engine_live': 'AI इन्जिन सोलिगासिनो',
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
      'your_journey': 'तपाईंको यात्रा',
      'progress_wellness': 'प्रगति र स्वास्थ्य',
      'progress_wellness_sub': 'वास्तविक समय संज्ञानात्मक प्रगति र सेन्सर स्थिरीकरण सारांश।',
      'listen_to_report': 'प्रतिवेदन सुन्नुहोस्',
      'daily_streak': 'दैनिक निरन्तरता',
      'seven_days': '७ दिन',
      'consistency_streak': 'निरन्तरता रेकर्ड',
      'adherence_this_week': 'यस हप्ता सक्रिय सहभागिता',
      'sessions_caps': 'सत्रहरू',
      'completed_caps': 'पूरा',
      'cognitive_activities': 'संज्ञानात्मक गतिविधिहरू',
      'completed_this_week': 'यस हप्ता पूरा भयो',
      'accuracy_caps': 'शुद्धता',
      'working_memory_score': 'कार्यकारी स्मरण स्कोर',
      'progression_vs_baseline': 'आधार रेखा भन्दा सुधार (+८%)',
      'kinematics_caps': 'गतिशीलता',
      'motor_posture_balance': 'मोटर र कम्पन स्थिरता',
      'sensor_stabilized': 'सेन्सर-स्थिरीकृत अन्तरक्रिया',
      'weekly_accuracy_trend': 'साप्ताहिक शुद्धता प्रवृत्ति',
      'motor_stability_index': 'मोटर कम्पन स्थिरता सूचकांक',
      'tap_data_points': 'रेकर्ड गरिएको स्कोर र टिपोट हेर्न बिन्दुहरूमा ट्याप गर्नुहोस्',
      'realtime_imu_curve': 'कम्पन कम गर्ने काइनेमेटिक फिल्टर',
      'memory_tab': 'स्मरण',
      'stability_tab': 'स्थिरता',
      'recorded_session_score': 'रेकर्ड गरिएको सत्र शुद्धता',
      'clinical_target': 'क्लिनिकल बेसलाइन (७०%)',
      'ai_confidence': 'AI विश्वसनीयता ९४%',
      'clinical_domains_title': 'क्लिनिकल संज्ञानात्मक र मोटर डोमेन',
      'clinical_domains_sub': '५ मुख्य पुनर्वास आयामहरूमा निरन्तर अनुगमन।',
      'recent_milestones_title': 'हालैका उपलब्धिहरू र सत्रहरू',
      'recent_milestones_sub': 'अभ्यास र ESP32 बायो-सेन्सरहरूबाट सिंक गरिएको डेटा।',
      'ai_engine_live': 'AI इन्जिन सक्रिय',
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
      'your_journey': 'I Kawngzawh',
      'progress_wellness': 'Hmasawnna & Hriselna',
      'progress_wellness_sub': 'Rilru vawn nghehna leh khur tihtlem dinhmun tlangpui.',
      'listen_to_report': 'Report ngaithla rawh',
      'daily_streak': 'Ni Tin Zawn',
      'seven_days': 'Ni 7',
      'consistency_streak': 'Bansan lohna',
      'adherence_this_week': 'Karkhat chhung zawm ṭhat',
      'sessions_caps': 'Sessions',
      'completed_caps': 'Zawh tawh',
      'cognitive_activities': 'Rilru Sawizawina',
      'completed_this_week': 'Kar kalta a zawh',
      'accuracy_caps': 'Dikna',
      'working_memory_score': 'Hriatrengna Mark',
      'progression_vs_baseline': 'A hma aia ṭha zawk (+8%)',
      'kinematics_caps': 'Chetsualna',
      'motor_posture_balance': 'Kut Khur Tihtlemna',
      'sensor_stabilized': 'Sensor hmanga enkawl',
      'weekly_accuracy_trend': 'Karkhat dikna hmasawn dan',
      'motor_stability_index': 'Kut Khur Tlem Dan Tehna',
      'tap_data_points': 'Mark leh thuziak en turin point-ah hmet rawh',
      'realtime_imu_curve': 'Kut khur tihtlemna filter',
      'memory_tab': 'Hriatrengna',
      'stability_tab': 'Nghehna',
      'recorded_session_score': 'Session Dik Zat',
      'clinical_target': 'A tlangpui bituk (70%)',
      'ai_confidence': 'AI Rintlakna 94%',
      'clinical_domains_title': 'Rilru & Taksa Thiltih Domain',
      'clinical_domains_sub': 'Enkawlna hmun 5-ah chian zui zel a ni.',
      'recent_milestones_title': 'Hmasawnna Hnuhnungte',
      'recent_milestones_sub': 'Damlo chetzia leh ESP32 sensor atanga lak data.',
      'ai_engine_live': 'AI ENGINE NUNG',
    },
  };
}
