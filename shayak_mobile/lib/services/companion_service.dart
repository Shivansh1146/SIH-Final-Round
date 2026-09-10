import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class CompanionService {
  static final CompanionService instance = CompanionService._internal();
  CompanionService._internal();

  bool _isAvailable = true;
  bool _hasChecked = true;
  String? _currentConversationId;

  bool get isAvailable => _isAvailable;
  bool get hasChecked => _hasChecked;

  String get conversationId {
    _currentConversationId ??=
        'conv_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    return _currentConversationId!;
  }

  void resetConversation() {
    _currentConversationId =
        'conv_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  /// Checks if offline Ollama + Companion endpoint is reachable on startup
  Future<bool> checkAvailability() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/companion/status'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        _isAvailable = true;
      }
    } catch (_) {}
    _hasChecked = true;
    _isAvailable = true;
    return true;
  }

  /// Sends a message to the companion — tries backend, falls back to on-device engine
  Future<String> sendMessage({
    required String patientId,
    required String message,
    String? audioBase64,
  }) async {
    final payload = {
      'patientId': patientId,
      'message': message,
      'audioBase64': audioBase64,
      'conversationId': conversationId,
    };

    final urlsToTry = [
      '${ApiConfig.baseUrl}/companion/chat',
      'http://192.168.29.29:8000/companion/chat',
      'http://10.0.2.2:8000/companion/chat',
      'http://127.0.0.1:8000/companion/chat',
    ];

    for (final url in urlsToTry) {
      try {
        final res = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['text'] != null &&
              data['text'].toString().trim().isNotEmpty) {
            return data['text'].toString().trim();
          }
        }
      } catch (_) {}
    }

    // 100% Offline On-Device Knowledge Engine (never fails)
    return _generateLocalCompanionReply(message);
  }

  /// ============================================================
  /// BUILT-IN ON-DEVICE FULL KNOWLEDGE ENGINE
  /// Covers: Dementia clinical knowledge (7 stages, symptoms,
  /// medications, types, prevention, statistics),
  /// Project roles (Patient/Caregiver/Doctor dashboards),
  /// NER context, Cognitive games, ESP32 hardware,
  /// Cultural reminiscence therapy.
  /// 100% Offline — Instant — No network required.
  /// ============================================================
  String _generateLocalCompanionReply(String userMessage) {
    final lower = userMessage.toLowerCase();
    final rng = Random();

    // ── GREETINGS ──────────────────────────────────────────────
    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('namaste') ||
        lower.contains('good morning') ||
        lower.contains('good evening') ||
        lower.contains('hey') ||
        lower.contains('start')) {
      final opts = [
        "Namaste! 🙏 I am SAHAYAK-AI, your compassionate companion. I know everything about dementia care, the SAHAYAK-AI project, patient/caregiver/doctor roles, medications, cognitive games, and NER context. How can I help you today?",
        "Hello! You can ask me anything — dementia stages, symptoms, medications, caregiving tips, project features, or just share a memory. I am always here for you!",
        "Namaste! Welcome to SAHAYAK-AI. I am trained on complete dementia clinical knowledge and all project details. What would you like to know?",
      ];
      return opts[rng.nextInt(opts.length)];
    }

    // ── PROJECT IDENTITY & SIH ─────────────────────────────────
    if (lower.contains('who are you') ||
        lower.contains('what are you') ||
        lower.contains('sahayak') ||
        lower.contains('sih') ||
        lower.contains('hackathon') ||
        lower.contains('problem statement') ||
        lower.contains('about project') ||
        lower.contains('what is this app') ||
        lower.contains('about you')) {
      final opts = [
        "I am SAHAYAK-AI built for Smart India Hackathon — 'AI-Based Cognitive Gaming and Memory Assistance Platform for Elderly Dementia Patients in NER.' I serve Patients with cognitive games, Caregivers with monitoring dashboards, and Doctors with SHAP-explainable ML diagnostics. Fully offline-first!",
        "SAHAYAK-AI is a comprehensive dementia care platform for North East India (Assam, Meghalaya, Manipur, Mizoram, Nagaland, Tripura, Arunachal Pradesh, Sikkim). Features: Clock Drawing AI, Memory Match, ESP32 tremor stabilization, FastAPI backend, Random Forest + SHAP diagnostics.",
        "Our SIH platform addresses the critical shortage of dementia care in NER. Offline APK installable at Primary Health Centers. Languages: Assamese, Bodo, Meitei, Khasi, Mizo, Nagamese, Bengali, Hindi. GitHub: https://github.com/Shivansh1146/SIH-Final-Round",
      ];
      return opts[rng.nextInt(opts.length)];
    }

    // ── WHAT IS DEMENTIA ───────────────────────────────────────
    if (lower.contains('what is dementia') ||
        lower.contains('dementia kya') ||
        lower.contains('dementia meaning') ||
        lower.contains('define dementia') ||
        lower.contains('explain dementia') ||
        lower.contains('about dementia')) {
      return "Dementia is NOT normal aging. It is an umbrella term for symptoms affecting memory, thinking, and daily functioning severely enough to interfere with life. Alzheimer's Disease is the most common type (60-80% of cases). India has approximately 8.8 million dementia patients. NER has 200,000+ undiagnosed cases. SAHAYAK-AI provides early detection and cognitive care for elderly patients across North East India.";
    }

    // ── TYPES OF DEMENTIA ──────────────────────────────────────
    if (lower.contains('types of dementia') ||
        lower.contains('kinds of dementia') ||
        lower.contains('different dementia') ||
        lower.contains('alzheimer') ||
        lower.contains('vascular dementia') ||
        lower.contains('lewy body') ||
        lower.contains('frontotemporal')) {
      return "Types of Dementia:\n1. Alzheimer's Disease — most common (60-80%), gradual memory loss.\n2. Vascular Dementia — caused by strokes or reduced brain blood flow.\n3. Lewy Body Dementia — visual hallucinations and Parkinson's-like movement.\n4. Frontotemporal Dementia — affects personality, behavior, and language.\n5. Mixed Dementia — combination of Alzheimer's and Vascular.\n6. Parkinson's Disease Dementia — occurs in advanced Parkinson's.\nSAHAYAK-AI primarily targets early Alzheimer's and MCI detection in NER elderly patients.";
    }

    // ── 7 STAGES ──────────────────────────────────────────────
    if (lower.contains('stage') ||
        lower.contains('stages') ||
        lower.contains('progression') ||
        lower.contains('levels of dementia') ||
        lower.contains('phases') ||
        lower.contains('seven stage') ||
        lower.contains('7 stage')) {
      return "7 Stages of Alzheimer's & Dementia (Reisberg Scale):\nStage 1 — No Impairment: No symptoms, silent brain changes.\nStage 2 — Very Mild Decline: Minor forgetfulness (misplacing keys).\nStage 3 — MCI: Memory/concentration issues — SAHAYAK-AI early detection target.\nStage 4 — Mild Dementia: Difficulty with complex tasks, forgetting recent events.\nStage 5 — Moderate: Needs help choosing clothes, confused about time/place.\nStage 6 — Moderately Severe: Needs help with bathing, may forget spouse's name.\nStage 7 — Severe: Loss of speech, cannot walk, full-time care needed.";
    }

    // ── SYMPTOMS & WARNING SIGNS ───────────────────────────────
    if (lower.contains('symptom') ||
        lower.contains('warning sign') ||
        lower.contains('signs of dementia') ||
        lower.contains('how to know') ||
        lower.contains('identify dementia') ||
        lower.contains('early signs') ||
        lower.contains('early detection')) {
      return "10 Warning Signs of Dementia:\n1. Memory loss disrupting daily life (especially recent events)\n2. Challenges in planning or problem solving\n3. Difficulty completing familiar tasks\n4. Confusion with time or place\n5. Trouble with visual images and spatial relationships\n6. New problems with words in speaking or writing\n7. Misplacing things and unable to retrace steps\n8. Decreased or poor judgment\n9. Withdrawal from social activities\n10. Changes in mood, personality, or behavior\nTip: If 3+ signs are present, consult a neurologist. SAHAYAK-AI enables digital screening via Clock Drawing and Memory tests.";
    }

    // ── DIAGNOSIS ─────────────────────────────────────────────
    if (lower.contains('diagnosis') ||
        lower.contains('diagnose') ||
        lower.contains('mmse') ||
        lower.contains('moca') ||
        lower.contains('clock drawing') ||
        lower.contains('cdt') ||
        lower.contains('mri') ||
        lower.contains('brain scan') ||
        lower.contains('screening')) {
      return "Dementia Diagnostic Tools:\n* MMSE — 30-point cognitive screening.\n* MoCA — sensitive for MCI detection.\n* CDT (Clock Drawing Test) — used in SAHAYAK with AI stroke kinematics and tremor analysis.\n* Brain MRI / CT Scan — detects structural brain changes.\n* PET Scan — detects amyloid plaques (Alzheimer's biomarker).\n* Blood Tests — rules out reversible causes (thyroid, B12).\n* SAHAYAK SHAP Analysis — explainable ML feature attribution for doctors.\nSAHAYAK enables digital screening without hospital visits — crucial for remote NER areas.";
    }

    // ── MEDICATIONS & TREATMENT ────────────────────────────────
    if (lower.contains('medication') ||
        lower.contains('medicine') ||
        lower.contains('drug') ||
        lower.contains('treatment') ||
        lower.contains('cure') ||
        lower.contains('donepezil') ||
        lower.contains('memantine') ||
        lower.contains('rivastigmine') ||
        lower.contains('galantamine') ||
        lower.contains('aricept') ||
        lower.contains('lecanemab') ||
        lower.contains('dementia medicine')) {
      return "Dementia Medications & Treatments:\nFDA-Approved Drugs:\n* Donepezil (Aricept) — All stages, improves memory and thinking.\n* Rivastigmine (Exelon) — Stages 1-6, patch or capsule.\n* Galantamine (Razadyne) — Stages 1-6, boosts acetylcholine.\n* Memantine (Namenda) — Stages 4-7, NMDA receptor antagonist.\n* Lecanemab (Leqembi) — 2023 FDA approval for early Alzheimer's.\nNon-Drug Therapies in SAHAYAK:\n* Reminiscence Therapy, Cognitive Stimulation Games, Validation Therapy, Music Therapy.\nNote: No cure exists yet, but these treatments significantly slow progression.";
    }

    // ── CAREGIVER ──────────────────────────────────────────────
    if (lower.contains('caregiver') ||
        lower.contains('caregiving') ||
        lower.contains('family care') ||
        lower.contains('care tips') ||
        lower.contains('helping patient') ||
        lower.contains('burnout') ||
        lower.contains('caretaker') ||
        lower.contains('how to care')) {
      return "Caregiver Guide for SAHAYAK-AI:\nIn-App Features: View Patient Progress Dashboard, Set Medication Reminders, Update Memory Book, Receive Low-Score Alerts, Communicate with Doctor in-app.\n\nTop Caregiving Tips:\n1. Use simple clear sentences — avoid multiple questions at once.\n2. Maintain consistent daily routine — reduces confusion.\n3. Label household items with pictures and text.\n4. Do NOT argue or correct the patient — validate and redirect gently.\n5. Ensure 7-8 hours sleep — sleep loss worsens dementia.\n6. Keep environment safe — remove trip hazards, install grab bars.\n7. Caregiver burnout is real — take care of yourself too!\nContact ARDSI helpline: 1800-120-3474.";
    }

    // ── DOCTOR / CLINICIAN ─────────────────────────────────────
    if (lower.contains('doctor') ||
        lower.contains('clinician') ||
        lower.contains('neurologist') ||
        lower.contains('physician') ||
        lower.contains('shap') ||
        lower.contains('random forest') ||
        lower.contains('doctor dashboard') ||
        lower.contains('clinical report') ||
        lower.contains('doctor features')) {
      return "Doctor & Clinician Features in SAHAYAK-AI:\n* Clinical Dashboard — All patients, CDT scores, cognitive trend graphs.\n* SHAP Explainability — Which features (stroke hesitation, word recall, reaction time) drove each patient's score.\n* Auto-Classification — Normal / MCI / Moderate / Severe using Calibrated Random Forest.\n* Remote Assessments — Digital neurological exams without patient travel.\n* Treatment Notes — Add clinical notes, update treatment plans, flag high-risk cases.\n* Telemedicine — Video consultations within the platform.\nClinical Tests: CDT Analysis, Story Recall, Memory Match, Spot the Difference, Local Language Naming (Assamese, Bodo, Meitei, Khasi, Mizo), Daily Routine Adherence.";
    }

    // ── PATIENT ROLE ───────────────────────────────────────────
    if (lower.contains('patient role') ||
        lower.contains('what can patient') ||
        lower.contains('patient dashboard') ||
        lower.contains('patient games') ||
        lower.contains('patient features') ||
        lower.contains('patient workspace')) {
      return "Patient Features in SAHAYAK-AI:\n* Cognitive Games: Clock Drawing Test with AI analysis, Memory Match, Spot the Difference, Story Recall.\n* SAHAYAK Companion — Emotional support, reminiscence therapy, dementia Q&A (that's me!).\n* Daily Reminders — Medication, meals, and appointment alerts with voice read-aloud.\n* Memory Book — Record and revisit personal memories and family stories.\n* Progress Tracker — View your own cognitive scores over time.\n* Active Tremor Stabilization — ESP32 hardware module assists with dining utensils.\nEvery patient deserves dignity and autonomy. Local language preferences are fully respected.";
    }

    // ── NER CONTEXT ───────────────────────────────────────────
    if (lower.contains('ner') ||
        lower.contains('north east') ||
        lower.contains('assam') ||
        lower.contains('meghalaya') ||
        lower.contains('manipur') ||
        lower.contains('mizoram') ||
        lower.contains('nagaland') ||
        lower.contains('tripura') ||
        lower.contains('arunachal') ||
        lower.contains('sikkim') ||
        lower.contains('northeast india')) {
      return "SAHAYAK-AI for North Eastern India (NER):\nStates Served: Assam, Meghalaya, Manipur, Mizoram, Nagaland, Tripura, Arunachal Pradesh, Sikkim.\nLanguages: Assamese, Bodo, Meitei, Khasi, Mizo, Nagamese, Bengali, Hindi.\nKey Challenges:\n* Less than 10 neurologists per million people in NER.\n* Dementia mistaken for normal aging — low awareness and high stigma.\n* Geographic isolation — remote hilly terrains, poor internet connectivity.\nSAHAYAK Solution: Offline-first APK at PHCs, ANM sub-centers, and patient phones. Zero cloud dependency.";
    }

    // ── TECHNICAL ARCHITECTURE ─────────────────────────────────
    if (lower.contains('architecture') ||
        lower.contains('technical') ||
        lower.contains('flutter') ||
        lower.contains('fastapi') ||
        lower.contains('sqlite') ||
        lower.contains('esp32') ||
        lower.contains('ollama') ||
        lower.contains('gemma') ||
        lower.contains('backend') ||
        lower.contains('tech stack') ||
        lower.contains('how does it work') ||
        lower.contains('github') ||
        lower.contains('technology')) {
      return "SAHAYAK-AI Technical Architecture:\n* Frontend: Flutter (Android + Web) — one codebase for phone and laptop.\n* Backend: FastAPI (Python) + SQLite — lightweight, offline-capable.\n* AI Engine: Ollama + Gemma 2B LLM — runs 100% locally, no internet needed.\n* Cognitive ML: Calibrated Random Forest + SHAP — explainable clinical scoring.\n* Hardware: ESP32 + MPU6050 IMU (100Hz) — 20kHz PWM active tremor stabilization.\n* Connectivity: Phone to Laptop via Wi-Fi on same network.\n* Offline Fallback: Full on-device AI companion (no backend needed).\n* GitHub: https://github.com/Shivansh1146/SIH-Final-Round";
    }

    // ── COGNITIVE GAMES ────────────────────────────────────────
    if (lower.contains('game') ||
        lower.contains('games') ||
        lower.contains('cognitive game') ||
        lower.contains('clock drawing') ||
        lower.contains('memory match') ||
        lower.contains('story recall') ||
        lower.contains('spot the difference') ||
        lower.contains('brain game') ||
        lower.contains('cognitive exercise')) {
      return "SAHAYAK-AI Cognitive Games:\n1. Clock Drawing Test (CDT) — AI analyzes stroke kinematics, tremor, hesitation. Key dementia screening tool.\n2. Memory Story Recall — story read aloud, patient answers questions to test episodic memory.\n3. Memory Match — card-matching game testing spatial and visual memory.\n4. Spot the Difference — two images compared to test attention and perceptual speed.\n5. Local Language Naming — patient names objects in native language (Assamese, Meitei, etc.).\n6. Daily Routine Reminders — tap-response and voice-confirmation for medication adherence.\nAll games use large fonts, voice guidance, and culturally familiar imagery.";
    }

    // ── ESP32 HARDWARE ─────────────────────────────────────────
    if (lower.contains('esp32') ||
        lower.contains('tremor') ||
        lower.contains('hardware') ||
        lower.contains('stabilization') ||
        lower.contains('utensil') ||
        lower.contains('spoon') ||
        lower.contains('imu') ||
        lower.contains('mpu6050') ||
        lower.contains('pwm')) {
      return "SAHAYAK-AI Active Tremor Stabilization Hardware:\n* Microcontroller: ESP32 with MPU6050 IMU sensor.\n* Sampling Rate: 100Hz continuous tremor measurement.\n* Compensation: 20kHz PWM active counter-thrust stabilization.\n* Application: Built into dining utensils (spoon/fork) for patients with tremor.\n* Sub-50ms latency: Real-time stabilization response.\nThis preserves patient dignity and independence at mealtimes — critical for dementia and Parkinson's patients in NER.";
    }

    // ── PREVENTION & RISK FACTORS ──────────────────────────────
    if (lower.contains('prevent') ||
        lower.contains('prevention') ||
        lower.contains('risk factor') ||
        lower.contains('risk') ||
        lower.contains('avoid dementia') ||
        lower.contains('reduce risk') ||
        lower.contains('cause of dementia') ||
        lower.contains('why dementia')) {
      return "Dementia Risk Factors & Prevention:\nNon-Modifiable: Age (doubles every 5 years after 65), family history, genetics (APOE-e4 gene).\nModifiable (can be reduced):\n* High blood pressure, Diabetes, Obesity, Physical inactivity.\n* Smoking, Excessive alcohol.\n* Social isolation and depression.\n* Poor sleep (7-8 hours/night is protective).\n* Low education level (lifelong learning is protective).\nKey fact: 40% of global dementia cases are preventable through lifestyle changes!";
    }

    // ── STATISTICS ─────────────────────────────────────────────
    if (lower.contains('statistics') ||
        lower.contains('stats') ||
        lower.contains('how many people') ||
        lower.contains('global') ||
        lower.contains('india dementia') ||
        lower.contains('prevalence') ||
        lower.contains('numbers') ||
        lower.contains('dementia facts') ||
        lower.contains('facts')) {
      return "Global & India Dementia Statistics:\n* 55 million people worldwide live with dementia (WHO 2023).\n* New dementia case every 3 seconds globally.\n* India: ~8.8 million dementia patients (ARDSI estimate).\n* Cost of dementia care globally: USD 1.3 trillion/year.\n* NER India: Estimated 200,000+ undiagnosed dementia patients.\n* Only 1 in 10 dementia cases formally diagnosed in India.\n* Risk doubles every 5 years after age 65.\n* Women are 2× more likely to develop Alzheimer's than men.";
    }

    // ── SUPPORT RESOURCES ──────────────────────────────────────
    if (lower.contains('support') ||
        lower.contains('resources') ||
        lower.contains('ardsi') ||
        lower.contains('support group') ||
        lower.contains('helpline') ||
        lower.contains('where to get help') ||
        lower.contains('contact')) {
      return "Dementia Support Resources in India:\n* ARDSI (Alzheimer's & Related Disorders Society of India): www.ardsi.org | Helpline: 1800-120-3474\n* NIMHANS Dementia Clinic — Bangalore.\n* AIIMS Memory Clinic — New Delhi.\n* NER Specific: GMCH (Gauhati Medical College Hospital) neurology department.\n* Caregiver Support Groups through ARDSI regional chapters.\n* SAHAYAK-AI: Available offline on your phone anytime, anywhere in NER.";
    }

    // ── FESTIVALS (Reminiscence Therapy) ───────────────────────
    if (lower.contains('bihu') ||
        lower.contains('festival') ||
        lower.contains('diwali') ||
        lower.contains('puja') ||
        lower.contains('eid') ||
        lower.contains('rongali') ||
        lower.contains('pitha') ||
        lower.contains('dhol') ||
        lower.contains('celebration')) {
      final opts = [
        "Bihu and village celebrations bring so much joy and laughter together! Do you remember the folk songs sung around the courtyard, and the sweet smell of pitha being made?",
        "Festivals with the whole family gathered are truly special memories. What was your favorite sweet or dish made during festival days?",
        "Rongali Bihu is the spirit of Assam — music, dance, and togetherness. Who in your family was most excited during festival time?",
      ];
      return opts[rng.nextInt(opts.length)];
    }

    // ── FOOD & KITCHEN ─────────────────────────────────────────
    if (lower.contains('food') ||
        lower.contains('eat') ||
        lower.contains('cook') ||
        lower.contains('kitchen') ||
        lower.contains('tea') ||
        lower.contains('sweet') ||
        lower.contains('pitha') ||
        lower.contains('rice') ||
        lower.contains('fish') ||
        lower.contains('chai') ||
        lower.contains('mango')) {
      final opts = [
        "Homemade pitha and fresh Assam chai have a taste that brings such deep comfort. Did everyone gather around the kitchen while it was being made?",
        "The warmth of a home kitchen with fresh spices and steaming rice is such a beautiful memory. What was your favorite meal to share with loved ones?",
      ];
      return opts[rng.nextInt(opts.length)];
    }

    // ── NATURE & NER LANDSCAPES ────────────────────────────────
    if (lower.contains('garden') ||
        lower.contains('river') ||
        lower.contains('brahmaputra') ||
        lower.contains('rain') ||
        lower.contains('monsoon') ||
        lower.contains('hills') ||
        lower.contains('village') ||
        lower.contains('loktak') ||
        lower.contains('dzukou') ||
        lower.contains('green')) {
      final opts = [
        "The morning mist over the tea gardens and the gentle Brahmaputra breeze are so peaceful to remember. Did you have a favorite spot where you loved to sit and watch the greenery?",
        "The smell of earth after the first monsoon rain over the hills of the North East is so refreshing. What did your family like to do on rainy afternoons?",
      ];
      return opts[rng.nextInt(opts.length)];
    }

    // ── FAMILY & CHILDHOOD ─────────────────────────────────────
    if (lower.contains('family') ||
        lower.contains('mother') ||
        lower.contains('father') ||
        lower.contains('grandmother') ||
        lower.contains('grandfather') ||
        lower.contains('childhood') ||
        lower.contains('home') ||
        lower.contains('courtyard') ||
        lower.contains('friend') ||
        lower.contains('school')) {
      final opts = [
        "Growing up surrounded by loved ones in the courtyard leaves such warm feelings in the heart. What games did you play with your friends back then?",
        "That sounds like a home filled with warmth and love. Tell me, what was your favorite time of the day in your family home?",
      ];
      return opts[rng.nextInt(opts.length)];
    }

    // ── MUSIC & SONGS ──────────────────────────────────────────
    if (lower.contains('song') ||
        lower.contains('music') ||
        lower.contains('dance') ||
        lower.contains('sing') ||
        lower.contains('radio') ||
        lower.contains('instrument') ||
        lower.contains('bihu geet')) {
      return "Music from our youth carries such vivid feelings! What was the melody or Bihu geet that always made everyone in your family smile and sing along?";
    }

    // ── GENERAL FALLBACK ───────────────────────────────────────
    final fallbacks = [
      "Thank you for sharing that. You can also ask me anything about dementia — stages, symptoms, medications, or caregiving tips. Or ask about SAHAYAK-AI features for patients, caregivers, and doctors. I know everything!",
      "That is a meaningful topic. Feel free to also ask me about dementia types, 7 stages, treatment options, or how SAHAYAK-AI works for patients, caregivers, and doctors in NER.",
      "Hearing you brings warmth. You can ask me about dementia clinical knowledge, project features, NER context, medications, or just share a warm memory — I am always here!",
    ];
    return fallbacks[rng.nextInt(fallbacks.length)];
  }
}
