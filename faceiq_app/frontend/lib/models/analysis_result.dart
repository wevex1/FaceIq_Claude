// models/analysis_result.dart

class RatioMetric {
  final String name;
  final double value;
  final double? idealMin;
  final double? idealMax;
  final String unit;
  final double score;
  final String interpretation;
  final String category;

  const RatioMetric({
    required this.name,
    required this.value,
    this.idealMin,
    this.idealMax,
    required this.unit,
    required this.score,
    required this.interpretation,
    required this.category,
  });

  factory RatioMetric.fromJson(Map<String, dynamic> j) => RatioMetric(
        name: j['name'] as String,
        value: (j['value'] as num).toDouble(),
        idealMin: j['ideal_min'] != null ? (j['ideal_min'] as num).toDouble() : null,
        idealMax: j['ideal_max'] != null ? (j['ideal_max'] as num).toDouble() : null,
        unit: j['unit'] as String,
        score: (j['score'] as num).toDouble(),
        interpretation: j['interpretation'] as String,
        category: j['category'] as String,
      );

  String get displayValue {
    switch (unit) {
      case '%': return '${value.toStringAsFixed(1)}%';
      case '°': return '${value.toStringAsFixed(1)}°';
      case '×': return '${value.toStringAsFixed(2)}×';
      case 'mm': return '${value.toStringAsFixed(1)} mm';
      default: return value.toStringAsFixed(2);
    }
  }

  String get idealRange {
    if (idealMin == null || idealMax == null) return 'N/A';
    return '${_fmt(idealMin!)} – ${_fmt(idealMax!)} $unit';
  }

  String _fmt(double v) {
    switch (unit) {
      case '%': return v.toStringAsFixed(1);
      case '°': return v.toStringAsFixed(1);
      default: return v.toStringAsFixed(2);
    }
  }

  bool get isIdeal {
    if (idealMin == null || idealMax == null) return true;
    return value >= idealMin! && value <= idealMax!;
  }
}

class CategoryResult {
  final String category;
  final double averageScore;
  final List<RatioMetric> metrics;

  const CategoryResult({
    required this.category,
    required this.averageScore,
    required this.metrics,
  });

  factory CategoryResult.fromJson(Map<String, dynamic> j) => CategoryResult(
        category: j['category'] as String,
        averageScore: (j['average_score'] as num).toDouble(),
        metrics: (j['metrics'] as List)
            .map((e) => RatioMetric.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class AnalysisResult {
  final bool success;
  final String? error;
  final String imageType;
  final double overallScore;
  final int landmarkCount;
  final List<CategoryResult> categories;
  final int totalMetrics;
  final Map<String, List<double>> landmarks;

  const AnalysisResult({
    required this.success,
    this.error,
    required this.imageType,
    required this.overallScore,
    required this.landmarkCount,
    required this.categories,
    required this.totalMetrics,
    required this.landmarks,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> j) => AnalysisResult(
        success: j['success'] as bool,
        error: j['error'] as String?,
        imageType: j['image_type'] as String,
        overallScore: (j['overall_score'] as num).toDouble(),
        landmarkCount: (j['landmark_count'] as num).toInt(),
        categories: (j['categories'] as List? ?? [])
            .map((e) => CategoryResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalMetrics: (j['total_metrics'] as num? ?? 0).toInt(),
        landmarks: (j['landmarks'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(
            k,
            (v as List).map((e) => (e as num).toDouble()).toList(),
          ),
        ),
      );

  List<RatioMetric> get allMetrics =>
      categories.expand((c) => c.metrics).toList();

  String get scoreLabel {
    if (overallScore >= 8.5) return 'Exceptional';
    if (overallScore >= 7.0) return 'Excellent';
    if (overallScore >= 5.5) return 'Good';
    if (overallScore >= 4.0) return 'Average';
    return 'Below Average';
  }
}

class CombinedResult {
  final AnalysisResult? frontal;
  final AnalysisResult? profile;
  final double combinedScore;

  const CombinedResult({
    this.frontal,
    this.profile,
    required this.combinedScore,
  });

  factory CombinedResult.fromJson(Map<String, dynamic> j) => CombinedResult(
        frontal: j['frontal'] != null
            ? AnalysisResult.fromJson(j['frontal'] as Map<String, dynamic>)
            : null,
        profile: j['profile'] != null
            ? AnalysisResult.fromJson(j['profile'] as Map<String, dynamic>)
            : null,
        combinedScore: (j['combined_score'] as num).toDouble(),
      );
}
