import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/detection_card.dart';

class ResultScreen extends StatelessWidget {
  final AnalysisResponse response;

  const ResultScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Résultat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Carte sujet ─────────────────────────────────────────────────
          _SubjectCard(subject: response.subject),
          const SizedBox(height: 16),

          // ─── Titre section détections ────────────────────────────────────
          Row(
            children: [
              Icon(Icons.search, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '${response.detections.length} détection(s)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ─── Liste des détections ────────────────────────────────────────
          if (response.detections.isEmpty)
            _EmptyDetections()
          else
            ...response.detections
                .map((d) => DetectionCard(detection: d))
                .toList(),
        ],
      ),
    );
  }
}

// ─── Carte sujet ──────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final AnalysisSubject subject;
  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidencePct =
        (subject.confidence * 100).toStringAsFixed(0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SubjectTypeBadge(type: subject.subjectType),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subject.description,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Confiance : $confidencePct%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: subject.confidence,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectTypeBadge extends StatelessWidget {
  final String type;
  const _SubjectTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (type) {
      'PLANT' => (Colors.green, Icons.eco_rounded, 'Plante'),
      'PEST' => (Colors.red, Icons.bug_report_rounded, 'Ravageur'),
      'SATELLITE_PLOT' => (Colors.blue, Icons.satellite_alt_rounded, 'Satellite'),
      'DRONE_PLOT' => (Colors.purple, Icons.flight_rounded, 'Drone'),
      _ => (Colors.grey, Icons.help_outline, type),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDetections extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 52),
            SizedBox(height: 12),
            Text(
              'Aucune anomalie détectée',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'La plante ou la parcelle semble saine.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
