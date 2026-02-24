import 'package:flutter/material.dart';

class SeverityBadge extends StatelessWidget {
  final String severity;

  const SeverityBadge({super.key, required this.severity});

  static (Color, String) _props(String s) => switch (s) {
        'LOW' => (const Color(0xFF4CAF50), 'Faible'),
        'MEDIUM' => (const Color(0xFFFF9800), 'Moyen'),
        'HIGH' => (const Color(0xFFF44336), 'Élevé'),
        'CRITICAL' => (const Color(0xFFB71C1C), 'Critique'),
        _ => (Colors.grey, s),
      };

  @override
  Widget build(BuildContext context) {
    final (color, label) = _props(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
