// ─────────────────────────────────────────────────────────────────────────────
// Modèles de données — PestAI Mobile
// Miroir du schéma retourné par l'API v12.
// ─────────────────────────────────────────────────────────────────────────────

enum AnalysisType {
  plantPest('PLANT_PEST', '🌿 Plante / Ravageur'),
  satellite('SATELLITE_REMOTE_SENSING', '🛰️ Satellite'),
  drone('DRONE_ANALYSIS', '🚁 Drone');

  final String value;
  final String label;
  const AnalysisType(this.value, this.label);
}

// ─── Réponse principale ───────────────────────────────────────────────────────

class AnalysisResponse {
  final AnalysisSubject subject;
  final List<Detection> detections;

  const AnalysisResponse({required this.subject, required this.detections});

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisResponse(
      subject: AnalysisSubject.fromJson(json['subject'] as Map<String, dynamic>),
      detections: (json['detections'] as List<dynamic>)
          .map((d) => Detection.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── Sujet identifié ─────────────────────────────────────────────────────────

class AnalysisSubject {
  final String subjectType;
  final String description;
  final double confidence;

  const AnalysisSubject({
    required this.subjectType,
    required this.description,
    required this.confidence,
  });

  factory AnalysisSubject.fromJson(Map<String, dynamic> json) {
    return AnalysisSubject(
      subjectType: json['subjectType'] as String,
      description: json['description'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

// ─── Détection ───────────────────────────────────────────────────────────────

class Detection {
  final String className;
  final double confidenceScore;
  final String severity;
  final String? croppedImageUrl;
  final DetectionDetails details;

  const Detection({
    required this.className,
    required this.confidenceScore,
    required this.severity,
    this.croppedImageUrl,
    required this.details,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      className: json['className'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      severity: json['severity'] as String,
      croppedImageUrl: json['croppedImageUrl'] as String?,
      details: DetectionDetails.fromJson(json['details'] as Map<String, dynamic>),
    );
  }
}

// ─── Détails d'une détection ──────────────────────────────────────────────────

class DetectionDetails {
  final String description;
  final String impact;
  final Recommendations recommendations;
  final List<String> knowledgeBaseTags;

  const DetectionDetails({
    required this.description,
    required this.impact,
    required this.recommendations,
    required this.knowledgeBaseTags,
  });

  factory DetectionDetails.fromJson(Map<String, dynamic> json) {
    return DetectionDetails(
      description: json['description'] as String,
      impact: json['impact'] as String,
      recommendations: Recommendations.fromJson(
        json['recommendations'] as Map<String, dynamic>,
      ),
      knowledgeBaseTags: (json['knowledgeBaseTags'] as List<dynamic>)
          .map((t) => t as String)
          .toList(),
    );
  }
}

// ─── Recommandations ─────────────────────────────────────────────────────────

class Recommendations {
  final List<RecommendationItem> biological;
  final List<RecommendationItem> chemical;
  final List<RecommendationItem> cultural;

  const Recommendations({
    required this.biological,
    required this.chemical,
    required this.cultural,
  });

  factory Recommendations.fromJson(Map<String, dynamic> json) {
    List<RecommendationItem> parse(String key) =>
        (json[key] as List<dynamic>? ?? [])
            .map((r) => RecommendationItem.fromJson(r as Map<String, dynamic>))
            .toList();

    return Recommendations(
      biological: parse('biological'),
      chemical: parse('chemical'),
      cultural: parse('cultural'),
    );
  }

  bool get isEmpty =>
      biological.isEmpty && chemical.isEmpty && cultural.isEmpty;
}

class RecommendationItem {
  final String solution;
  final String details;
  final String? source;

  const RecommendationItem({
    required this.solution,
    required this.details,
    this.source,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      solution: json['solution'] as String,
      details: json['details'] as String,
      source: json['source'] as String?,
    );
  }
}
