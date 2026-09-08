import 'dart:math';

/// ============================================================================
/// SHAYAK-AI: Kinematic Assessment Point Model
/// Captures high-frequency drawing stroke coordinates (x, y), stylus/touch pressure,
/// millisecond monotonic timestamp, instantaneous velocity, and inter-stroke hesitation.
/// ============================================================================
class AssessmentPoint {
  final double x;
  final double y;
  final double pressure; // 0.0 to 1.0 (default 1.0 if capacitive screen)
  final int timestampMs; // Monotonic millisecond timestamp

  const AssessmentPoint({
    required this.x,
    required this.y,
    required this.pressure,
    required this.timestampMs,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'pressure': pressure,
    'timestamp_ms': timestampMs,
  };

  factory AssessmentPoint.fromJson(Map<String, dynamic> json) => AssessmentPoint(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    pressure: (json['pressure'] as num).toDouble(),
    timestampMs: json['timestamp_ms'] as int,
  );
}

/// A continuous drawing stroke composed of sequential AssessmentPoints
class Stroke {
  final List<AssessmentPoint> points;
  final int strokeId;
  final int startTimestampMs;

  Stroke({
    required this.strokeId,
    required this.startTimestampMs,
    List<AssessmentPoint>? points,
  }) : points = points ?? [];

  void addPoint(double x, double y, double pressure, int timestamp) {
    points.add(AssessmentPoint(
      x: x,
      y: y,
      pressure: pressure,
      timestampMs: timestamp,
    ));
  }

  /// Calculates total kinematic path length in logical pixels
  double get totalLength {
    if (points.length < 2) return 0.0;
    double length = 0.0;
    for (int i = 1; i < points.length; i++) {
      final dx = points[i].x - points[i - 1].x;
      final dy = points[i].y - points[i - 1].y;
      length += sqrt(dx * dx + dy * dy);
    }
    return length;
  }

  /// Calculates total active stroke duration in milliseconds
  int get durationMs {
    if (points.isEmpty) return 0;
    return points.last.timestampMs - points.first.timestampMs;
  }

  /// Calculates mean drawing velocity in pixels / millisecond
  double get meanVelocity {
    final dur = durationMs;
    if (dur <= 0) return 0.0;
    return totalLength / dur;
  }
}

/// Session-level Drawing Summary for on-device clinical analysis & TFLite input
class DrawingAssessmentSummary {
  final List<Stroke> strokes;
  final int totalHesitations; // Number of inter-stroke pauses > 500 ms
  final double averageVelocity;
  final double tremorJitterVariance;
  final int totalDurationMs;

  DrawingAssessmentSummary({
    required this.strokes,
    required this.totalHesitations,
    required this.averageVelocity,
    required this.tremorJitterVariance,
    required this.totalDurationMs,
  });

  /// Factory analyzer extracting clinical biomarkers from raw strokes
  factory DrawingAssessmentSummary.fromStrokes(List<Stroke> strokes) {
    if (strokes.isEmpty) {
      return DrawingAssessmentSummary(
        strokes: [],
        totalHesitations: 0,
        averageVelocity: 0.0,
        tremorJitterVariance: 0.0,
        totalDurationMs: 0,
      );
    }

    int hesitations = 0;
    double totalVelocitySum = 0.0;
    int validVelocityStrokes = 0;

    // Detect inter-stroke hesitation pauses (> 500 ms between pen-up and next pen-down)
    for (int i = 1; i < strokes.length; i++) {
      final prevStrokeEnd = strokes[i - 1].points.isNotEmpty
          ? strokes[i - 1].points.last.timestampMs
          : strokes[i - 1].startTimestampMs;
      final currentStrokeStart = strokes[i].startTimestampMs;

      final pause = currentStrokeStart - prevStrokeEnd;
      if (pause > 500) {
        hesitations++;
      }
    }

    for (final s in strokes) {
      if (s.durationMs > 20) {
        totalVelocitySum += s.meanVelocity;
        validVelocityStrokes++;
      }
    }

    final avgVel = validVelocityStrokes > 0 ? totalVelocitySum / validVelocityStrokes : 0.0;

    // Estimate micro-tremor jitter variance along stroke paths
    double jitterVariance = 0.0;
    int pointCount = 0;
    for (final s in strokes) {
      if (s.points.length >= 3) {
        for (int j = 1; j < s.points.length - 1; j++) {
          // Curvature / deviation jitter from local straight line
          final midX = (s.points[j - 1].x + s.points[j + 1].x) / 2.0;
          final midY = (s.points[j - 1].y + s.points[j + 1].y) / 2.0;
          final devX = s.points[j].x - midX;
          final devY = s.points[j].y - midY;
          jitterVariance += (devX * devX + devY * devY);
          pointCount++;
        }
      }
    }

    final meanJitterVar = pointCount > 0 ? jitterVariance / pointCount : 0.0;
    final totalDuration = strokes.last.points.isNotEmpty
        ? strokes.last.points.last.timestampMs - strokes.first.startTimestampMs
        : 0;

    return DrawingAssessmentSummary(
      strokes: strokes,
      totalHesitations: hesitations,
      averageVelocity: avgVel,
      tremorJitterVariance: meanJitterVar,
      totalDurationMs: totalDuration,
    );
  }
}
