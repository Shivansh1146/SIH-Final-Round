// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../models/patient_profile.dart';

class SpeechPlatformHelper {
  static void speakText(
    String text,
    AppLanguage lang, {
    VoidCallback? onStart,
    VoidCallback? onDone,
    VoidCallback? onError,
  }) {
    if (html.window.speechSynthesis == null) {
      debugPrint('[WebSpeech] SpeechSynthesis is not supported in this browser environment.');
      onError?.call();
      return;
    }

    try {
      // Clear any pending/paused speech in browser queue
      html.window.speechSynthesis!.cancel();

      final utterance = html.SpeechSynthesisUtterance(text);

      String primaryLocale = 'en-US';
      List<String> candidateLocales = ['en-US'];

      switch (lang) {
        case AppLanguage.hindi:
          primaryLocale = 'hi-IN';
          candidateLocales = ['hi-IN', 'hi', 'en-IN', 'en-US'];
          break;
        case AppLanguage.assamese:
          primaryLocale = 'as-IN';
          candidateLocales = ['as-IN', 'as', 'bn-IN', 'bn', 'hi-IN', 'en-IN'];
          break;
        case AppLanguage.bengali:
          primaryLocale = 'bn-IN';
          candidateLocales = ['bn-IN', 'bn', 'hi-IN', 'en-IN', 'en-US'];
          break;
        case AppLanguage.manipuri:
          primaryLocale = 'mni-IN';
          candidateLocales = ['mni-IN', 'mni', 'bn-IN', 'hi-IN', 'en-IN'];
          break;
        case AppLanguage.bodo:
          primaryLocale = 'brx-IN';
          candidateLocales = ['brx-IN', 'brx', 'hi-IN', 'en-IN'];
          break;
        case AppLanguage.nepali:
          primaryLocale = 'ne-NP';
          candidateLocales = ['ne-NP', 'ne', 'hi-IN', 'en-IN', 'en-US'];
          break;
        case AppLanguage.mizo:
          primaryLocale = 'lus-IN';
          candidateLocales = ['lus-IN', 'lus', 'en-IN', 'en-US', 'en-GB'];
          break;
        case AppLanguage.english:
        default:
          primaryLocale = 'en-US';
          candidateLocales = ['en-US', 'en-IN', 'en-GB', 'en'];
          break;
      }

      // Check available browser synthesis voices
      final voices = html.window.speechSynthesis!.getVoices();
      html.SpeechSynthesisVoice? matchedVoice;

      if (voices.isNotEmpty) {
        for (final cand in candidateLocales) {
          final candLower = cand.toLowerCase();
          final match = voices.where((v) {
            final vLang = (v.lang ?? '').toLowerCase();
            return vLang == candLower || vLang.startsWith(candLower) || candLower.startsWith(vLang);
          }).firstOrNull;

          if (match != null) {
            matchedVoice = match;
            break;
          }
        }
      }

      if (matchedVoice != null) {
        utterance.voice = matchedVoice;
        utterance.lang = matchedVoice.lang ?? primaryLocale;
      } else {
        utterance.lang = primaryLocale;
      }

      utterance.rate = 0.95;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;

      utterance.onStart.listen((_) {
        onStart?.call();
      });

      utterance.onEnd.listen((_) {
        onDone?.call();
      });

      utterance.onError.listen((e) {
        debugPrint('[WebSpeech] Utterance event notice: $e');
        onDone?.call();
      });

      html.window.speechSynthesis!.speak(utterance);
    } catch (e) {
      debugPrint('[WebSpeech] Speech synthesis error: $e');
      onError?.call();
    }
  }

  static void stopSpeech() {
    try {
      html.window.speechSynthesis?.cancel();
    } catch (_) {}
  }
}
