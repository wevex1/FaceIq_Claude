// widgets/score_gauge.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ScoreGauge extends StatefulWidget {
  final double score; // 0–10
  final double size;
  final bool showLabel;
  final String? centerLabel;

  const ScoreGauge({
    super.key,
    required this.score,
    this.size = 120,
    this.showLabel = true,
    this.centerLabel,
  });

  @override
  State<ScoreGauge> createState() => _ScoreGaugeState();
}

class _ScoreGaugeState extends State<ScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = Tween<double>(begin: 0, end: widget.score / 10)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(ScoreGauge old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _anim = Tween<double>(begin: _anim.value, end: widget.score / 10)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _scoreColor(double score) {
    if (score >= 8.0) return const Color(0xFF00D4AA);
    if (score >= 6.0) return const Color(0xFF7BC8F6);
    if (score >= 4.0) return const Color(0xFFF5C842);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(widget.score);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _GaugePainter(progress: _anim.value, color: color),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.score.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: widget.size * 0.22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -1,
                  ),
                ),
                if (widget.showLabel)
                  Text(
                    '/10',
                    style: TextStyle(
                      fontSize: widget.size * 0.1,
                      color: Colors.white38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (widget.centerLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.centerLabel!,
                      style: TextStyle(
                        fontSize: widget.size * 0.09,
                        color: Colors.white60,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.shortestSide / 2) - 8;
    const startAngle = math.pi * 0.75;
    const sweepFull = math.pi * 1.5;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepFull,
      false,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Progress
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        startAngle,
        sweepFull * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: startAngle,
            endAngle: startAngle + sweepFull * progress,
            colors: [color.withOpacity(0.4), color],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          ),
      );
    }

    // Glow dot at tip
    if (progress > 0.02) {
      final tipAngle = startAngle + sweepFull * progress;
      final tipX = cx + radius * math.cos(tipAngle);
      final tipY = cy + radius * math.sin(tipAngle);
      canvas.drawCircle(
        Offset(tipX, tipY),
        5,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(Offset(tipX, tipY), 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.color != color;
}
