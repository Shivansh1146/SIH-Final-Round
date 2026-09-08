import 'package:flutter/material.dart';
import '../models/patient_profile.dart';

class SpeechPlatformHelper {
  static void speakText(
    String text,
    AppLanguage lang, {
    VoidCallback? onStart,
    VoidCallback? onDone,
    VoidCallback? onError,
  }) {}

  static void stopSpeech() {}
}
