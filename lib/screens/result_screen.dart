import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../widgets/detection_card.dart';

class ResultScreen extends StatefulWidget {
  final AnalysisResponse response;
  const ResultScreen({super.key, required this.response});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  final AudioPlayer _player = AudioPlayer();

  bool _speaking = false;
  bool _loadingVoice = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _speaking = false);
    });
  }

  Future<void> _onVoiceTap() async {
    if (_speaking) {
      await _player.stop();
      setState(() => _speaking = false);
      return;
    }

    setState(() => _loadingVoice = true);
    try {
      final (wavBytes, _) = await ApiService.fetchVoiceAudio(widget.response);
      if (!mounted) return;
      setState(() {
        _speaking = true;
        _loadingVoice = false;
      });
      await _player.play(BytesSource(wavBytes));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingVoice = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Impossible de générer le résumé vocal.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final response = widget.response;
    final hasDetections = response.detections.isNotEmpty;

    return Scaffold(
      floatingActionButton: _VoiceButton(
        speaking: _speaking,
        loading: _loadingVoice,
        onTap: _onVoiceTap,
      ),
      body: CustomScrollView(
        slivers: [
          // ─── AppBar ──────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            expandedHeight: 90,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 52, bottom: 14),
              title: const Text(
                'Résultats',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, const Color(0xFF1B5E20)],
                  ),
                ),
              ),
            ),
          ),

          // ─── Subject card ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SubjectCard(subject: response.subject),
              ),
            ),
          ),

          // ─── Detection count badge ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Row(children: [
                _CountBadge(
                  count: response.detections.length,
                  hasDetections: hasDetections,
                ),
              ]),
            ),
          ),

          // ─── Detections list ──────────────────────────────────────────────────
          if (!hasDetections)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HealthyCard(),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _AnimatedCard(
                    detection: response.detections[i],
                    index: i,
                  ),
                  childCount: response.detections.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Animated Detection Card Wrapper ─────────────────────────────────────────

class _AnimatedCard extends StatefulWidget {
  final Detection detection;
  final int index;
  const _AnimatedCard({required this.detection, required this.index});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 80),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: 150 + widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(_anim),
      child: FadeTransition(
        opacity: _anim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DetectionCard(detection: widget.detection),
        ),
      ),
    );
  }
}

// ─── Subject Card ─────────────────────────────────────────────────────────────

class _SubjectCard extends StatefulWidget {
  final AnalysisSubject subject;
  const _SubjectCard({required this.subject});

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _barCtrl;
  late final Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _barCtrl.forward();
    });
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final pct = (widget.subject.confidence * 100).toStringAsFixed(0);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeBadge(type: widget.subject.subjectType),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                      height: 1,
                    ),
                  ),
                  Text(
                    'confiance',
                    style: TextStyle(fontSize: 11, color: cs.outline),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.subject.description,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _barAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: widget.subject.confidence * _barAnim.value,
                minHeight: 10,
                backgroundColor: cs.surfaceVariant,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Count Badge ──────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  final bool hasDetections;
  const _CountBadge({required this.count, required this.hasDetections});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = hasDetections ? cs.error : Colors.green;
    final icon = hasDetections
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline;
    final label =
        hasDetections ? '$count détection(s)' : 'Aucune anomalie';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Healthy Card ─────────────────────────────────────────────────────────────

class _HealthyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 68),
          SizedBox(height: 16),
          Text(
            'Plante saine !',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Aucune maladie ni ravageur détecté.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Voice Button ─────────────────────────────────────────────────────────────

class _VoiceButton extends StatefulWidget {
  final bool speaking;
  final bool loading;
  final VoidCallback onTap;

  const _VoiceButton({
    required this.speaking,
    required this.loading,
    required this.onTap,
  });

  @override
  State<_VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<_VoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.speaking)
          Container(
            margin: const EdgeInsets.only(bottom: 8, right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.inverseSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Résumé wolof en cours…',
              style: TextStyle(
                color: cs.onInverseSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Transform.scale(
            scale: widget.speaking ? _pulse.value : 1.0,
            child: child,
          ),
          child: FloatingActionButton(
            onPressed: widget.loading ? null : widget.onTap,
            backgroundColor: widget.speaking ? cs.error : cs.primary,
            tooltip: widget.speaking ? 'Arrêter' : 'Écouter en wolof',
            child: widget.loading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Icon(
                    widget.speaking
                        ? Icons.stop_rounded
                        : Icons.record_voice_over_rounded,
                    color: Colors.white,
                  ),
          ),
        ),
      ],
    );
  }
}
