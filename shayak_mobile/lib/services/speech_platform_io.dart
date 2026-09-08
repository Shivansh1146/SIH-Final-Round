import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/patient_profile.dart';

class SpeechPlatformHelper {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInit = false;

  static Future<void> _init(VoidCallback? onStart, VoidCallback? onDone, VoidCallback? onError) async {
    if (_isInit) return;
    _isInit = true;

    try {
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() => onStart?.call());
      _flutterTts.setCompletionHandler(() => onDone?.call());
      _flutterTts.setCancelHandler(() => onDone?.call());
      _flutterTts.setErrorHandler((msg) {
        debugPrint('[MobileTTS] Error: $msg');
        onError?.call();
      });
    } catch (e) {
      debugPrint('[MobileTTS] Init note: $e');
    }
  }

  static void speakText(
    String text,
    AppLanguage lang, {
    VoidCallback? onStart,
    VoidCallback? onDone,
    VoidCallback? onError,
  }) async {
    await _init(onStart, onDone, onError);

    String locale = 'en-US';
    switch (lang) {
      case AppLanguage.hindi:     locale = 'hi-IN'; break;
      case AppLanguage.assamese:  locale = 'as-IN'; break;
      case AppLanguage.bengali:   locale = 'bn-IN'; break;
      case AppLanguage.manipuri:  locale = 'mni-IN'; break;
      case AppLanguage.bodo:      locale = 'brx-IN'; break;
      case AppLanguage.nepali:    locale = 'ne-NP'; break;
      case AppLanguage.mizo:      locale = 'lus-IN'; break;
      case AppLanguage.english:
      default:                    locale = 'en-US'; break;
    }

    try {
      await _flutterTts.stop();
      final isAvailable = await _flutterTts.isLanguageAvailable(locale);
      if (isAvailable == 1 || isAvailable == true) {
        await _flutterTts.setLanguage(locale);
      } else {
        if (lang == AppLanguage.assamese || lang == AppLanguage.manipuri) {
          await _flutterTts.setLanguage('bn-IN');
        } else if (lang == AppLanguage.bodo || lang == AppLanguage.nepali) {
          await _flutterTts.setLanguage('hi-IN');
        } else {
          await _flutterTts.setLanguage('en-US');
        }
      }
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('[MobileTTS] Speak error: $e');
      onError?.call();
    }
  }

  static void stopSpeech() {
    try {
      _flutterTts.stop();
    } catch (_) {}
  }
}
