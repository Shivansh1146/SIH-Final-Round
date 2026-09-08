/// session_service.dart
/// Persists per-patient game session results in Hive so that AI stats
/// in the Caregiver Overview always reflect real gameplay data.
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/patient_profile.dart';

// ─── Session result record ────────────────────────────────────────────────────
class GameSession {
  final String sessionId;
  final String patientId;
  final String gameType; // 'memory_match' | 'clock_drawing'
  final DateTime playedAt;
  final double accuracyRatio;   // 0.0–1.0
  final double responseTimeSec; // average seconds per interaction
  final int totalMoves;
  final Map<String, dynamic> extras; // game-specific raw metrics

  GameSession({
    required this.sessionId,
    required this.patientId,
    required this.gameType,
    required this.playedAt,
    required this.accuracyRatio,
    required this.responseTimeSec,
    required this.totalMoves,
    this.extras = const {},
  });

  Map<String, dynamic> toMap() => {
        'sessionId': sessionId,
        'patientId': patientId,
        'gameType': gameType,
        'playedAt': playedAt.toIso8601String(),
        'accuracyRatio': accuracyRatio,
        'responseTimeSec': responseTimeSec,
        'totalMoves': totalMoves,
        'extras': Map<String, dynamic>.from(extras),
      };

  factory GameSession.fromMap(Map<dynamic, dynamic> m) => GameSession(
        sessionId: m['sessionId'] ?? '',
        patientId: m['patientId'] ?? '',
        gameType: m['gameType'] ?? 'unknown',
        playedAt: DateTime.tryParse(m['playedAt'] ?? '') ?? DateTime.now(),
        accuracyRatio: (m['accuracyRatio'] as num?)?.toDouble() ?? 0.5,
        responseTimeSec: (m['responseTimeSec'] as num?)?.toDouble() ?? 3.0,
        totalMoves: (m['totalMoves'] as num?)?.toInt() ?? 0,
        extras: m['extras'] is Map
            ? Map<String, dynamic>.from(m['extras'] as Map)
            : {},
      );
}

// ─── Session Service ──────────────────────────────────────────────────────────
class SessionService extends ChangeNotifier {
  static final SessionService instance = SessionService._internal();
  SessionService._internal();

  static const _boxKey = 'user_preferences';
  static const _hiveKey = 'game_sessions';

  /// Saves a completed game session to Hive and notifies listeners.
  void saveSession(GameSession session) {
    try {
      final box = Hive.box(_boxKey);
      final raw = box.get(_hiveKey);
      final all = <Map<dynamic, dynamic>>[];
      if (raw is List) {
        all.addAll(raw.cast<Map<dynamic, dynamic>>());
      }
      all.add(session.toMap());
      box.put(_hiveKey, all);
      notifyListeners();
    } catch (e) {
      debugPrint('[SessionService] save error: $e');
    }
  }

  /// Returns all sessions for the active patient, most recent first.
  List<GameSession> getSessionsFor(String patientId) {
    try {
      if (patientId == 'patient-ramesh') {
        ensureDemoDataSeeded();
      }
      final box = Hive.box(_boxKey);
      final raw = box.get(_hiveKey);
      if (raw is! List) return [];
      return raw
          .cast<Map<dynamic, dynamic>>()
          .map(GameSession.fromMap)
          .where((s) => s.patientId == patientId)
          .toList()
        ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
    } catch (e) {
      debugPrint('[SessionService] load error: $e');
      return [];
    }
  }

  /// Deletes all sessions for a given patient (e.g., on profile reset).
  void clearSessionsFor(String patientId) {
    try {
      final box = Hive.box(_boxKey);
      final raw = box.get(_hiveKey);
      if (raw is! List) return;
      final filtered = raw
          .cast<Map<dynamic, dynamic>>()
          .where((m) => m['patientId'] != patientId)
          .toList();
      box.put(_hiveKey, filtered);
      notifyListeners();
    } catch (e) {
      debugPrint('[SessionService] clear error: $e');
    }
  }

  /// Convenience: compute aggregate stats for a patient from stored sessions.
  ({
    int totalSessions,
    double avgAccuracy,
    double avgResponseSec,
    List<double> last7Scores,
  }) getStatsFor(String patientId) {
    final sessions = getSessionsFor(patientId);
    if (sessions.isEmpty) {
      return (
        totalSessions: 0,
        avgAccuracy: 0.0,
        avgResponseSec: 0.0,
        last7Scores: [],
      );
    }
    final total = sessions.length;
    final avgAcc =
        sessions.map((s) => s.accuracyRatio).reduce((a, b) => a + b) / total;
    final avgResp =
        sessions.map((s) => s.responseTimeSec).reduce((a, b) => a + b) / total;

    // Last 7 scores for the line chart (oldest → newest)
    final last7 = sessions.take(7).toList().reversed.toList();
    final scores = last7.map((s) => s.accuracyRatio.clamp(0.0, 1.0)).toList();

    return (
      totalSessions: total,
      avgAccuracy: avgAcc,
      avgResponseSec: avgResp,
      last7Scores: scores,
    );
  }

  /// Generates a unique session ID.
  static String generateId(String patientId, String gameType) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '$patientId-$gameType-$ts';
  }

  /// Quick helper: active patient ID from Hive.
  static String? get activePatientId {
    try {
      final box = Hive.box(_boxKey);
      final id = box.get('active_patient_id') as String?;
      if (id != null && id.isNotEmpty) return id;
      return PatientProfile.loadFromHive()?.id;
    } catch (_) {
      return null;
    }
  }

  /// Seeds initial demonstration sessions ONLY for 'patient-ramesh' (the demo profile)
  /// so fresh installs show realistic data for Ramesh, while any new patient starts at 0.
  void ensureDemoDataSeeded() {
    try {
      final box = Hive.box(_boxKey);
      final raw = box.get(_hiveKey);
      final all = <Map<dynamic, dynamic>>[];
      if (raw is List) {
        all.addAll(raw.cast<Map<dynamic, dynamic>>());
      }
      final rameshSessions =
          all.where((m) => m['patientId'] == 'patient-ramesh');
      if (rameshSessions.isEmpty) {
        final now = DateTime.now();
        final demoAccuracies = [0.65, 0.70, 0.68, 0.74, 0.72, 0.78, 0.81];
        final demoResponses = [2.8, 2.5, 2.6, 2.3, 2.4, 2.1, 1.9];
        for (int i = 0; i < demoAccuracies.length; i++) {
          final s = GameSession(
            sessionId: 'demo-ramesh-$i',
            patientId: 'patient-ramesh',
            gameType: i.isEven ? 'memory_match' : 'clock_drawing',
            playedAt: now.subtract(Duration(days: 7 - i, hours: 2)),
            accuracyRatio: demoAccuracies[i],
            responseTimeSec: demoResponses[i],
            totalMoves: 12 + i,
          );
          all.add(s.toMap());
        }
        box.put(_hiveKey, all);
      }
    } catch (e) {
      debugPrint('[SessionService] seed error: $e');
    }
  }
}
