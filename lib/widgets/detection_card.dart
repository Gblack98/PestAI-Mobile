import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models.dart';
import 'severity_badge.dart';

class DetectionCard extends StatefulWidget {
  final Detection detection;

  const DetectionCard({super.key, required this.detection});

  @override
  State<DetectionCard> createState() => _DetectionCardState();
}

class _DetectionCardState extends State<DetectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = widget.detection;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // ─── En-tête cliquable ───────────────────────────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image découpée (ou placeholder)
                  _CroppedImage(url: d.croppedImageUrl),
                  const SizedBox(width: 12),

                  // Nom + confiance
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.className,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(d.confidenceScore * 100).toStringAsFixed(0)}% de confiance',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                        const SizedBox(height: 6),
                        SeverityBadge(severity: d.severity),
                      ],
                    ),
                  ),

                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),

          // ─── Détails (expandable) ────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _DetailsSection(details: d.details),
          ),
        ],
      ),
    );
  }
}

// ─── Image découpée ───────────────────────────────────────────────────────────

class _CroppedImage extends StatelessWidget {
  final String? url;
  const _CroppedImage({this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.eco_outlined, size: 28),
    );

    if (url == null || url!.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}

// ─── Section détails ──────────────────────────────────────────────────────────

class _DetailsSection extends StatelessWidget {
  final DetectionDetails details;
  const _DetailsSection({required this.details});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          _InfoTile(
            icon: Icons.description_outlined,
            label: 'Description',
            text: details.description,
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.warning_amber_rounded,
            label: 'Impact',
            text: details.impact,
          ),
          if (!details.recommendations.isEmpty) ...[
            const SizedBox(height: 12),
            _RecommendationsSection(recs: details.recommendations),
          ],
          if (details.knowledgeBaseTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: details.knowledgeBaseTags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      labelStyle: const TextStyle(fontSize: 11),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 2),
              Text(text, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecommendationsSection extends StatelessWidget {
  final Recommendations recs;
  const _RecommendationsSection({required this.recs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommandations',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        if (recs.biological.isNotEmpty)
          _RecGroup(
            icon: Icons.nature,
            color: Colors.green,
            label: 'Biologique',
            items: recs.biological,
          ),
        if (recs.chemical.isNotEmpty)
          _RecGroup(
            icon: Icons.science_outlined,
            color: Colors.blue,
            label: 'Chimique',
            items: recs.chemical,
          ),
        if (recs.cultural.isNotEmpty)
          _RecGroup(
            icon: Icons.agriculture,
            color: Colors.orange,
            label: 'Culturale',
            items: recs.cultural,
          ),
      ],
    );
  }
}

class _RecGroup extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final List<RecommendationItem> items;

  const _RecGroup({
    required this.icon,
    required this.color,
    required this.label,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
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
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 18, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ${item.solution}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    item.details,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
