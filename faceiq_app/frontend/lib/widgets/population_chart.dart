// lib/widgets/population_chart.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class PopulationChart extends StatelessWidget {
  final double score;
  final Color color;
  const PopulationChart({super.key, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(score: score, color: color),
      child: const SizedBox(width: double.infinity, height: 180),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final double score;
  final Color color;
  _ChartPainter({required this.score, required this.color});

  static double _s2p(double s) => 100 / (1 + math.exp(0.8 * (s - 5)));

  @override
  void paint(Canvas canvas, Size size) {
    const l = 32.0, r = 12.0, t = 18.0, b = 26.0;
    final cw = size.width - l - r;
    final ch = size.height - t - b;

    double xPx(double pct) => l + (1 - pct / 100) * cw;
    double yPx(double s) => t + (1 - (s - 1) / 9) * ch;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;
    final textStyle = TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 8);

    // Grid lines + Y labels
    for (final s in [2.0, 4.0, 6.0, 8.0, 10.0]) {
      final y = yPx(s);
      canvas.drawLine(Offset(l, y), Offset(size.width - r, y), gridPaint);
      _drawText(canvas, s.toInt().toString(), Offset(l - 4, y - 4), textStyle, TextAlign.right);
    }
    // X grid + labels
    for (final p in [75.0, 50.0, 25.0]) {
      final x = xPx(p);
      canvas.drawLine(Offset(x, t), Offset(x, size.height - b), gridPaint);
      _drawText(canvas, '${p.toInt()}%', Offset(x, size.height - b + 4), textStyle, TextAlign.center);
    }

    // Axes
    final axisPaint = Paint()..color = Colors.white.withOpacity(0.2)..strokeWidth = 0.5;
    canvas.drawLine(Offset(l, t), Offset(l, size.height - b), axisPaint);
    canvas.drawLine(Offset(l, size.height - b), Offset(size.width - r, size.height - b), axisPaint);

    // Axis label
    _drawText(canvas, 'population %  (100 → 0)',
        Offset(l + cw / 2, size.height - 2), textStyle, TextAlign.center);

    // Curve points
    final pts = <Offset>[];
    for (double s = 1.0; s <= 10.0; s += 0.1) {
      pts.add(Offset(xPx(_s2p(s)), yPx(s)));
    }

    // Area
    final areaPath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final pt in pts.skip(1)) areaPath.lineTo(pt.dx, pt.dy);
    areaPath.lineTo(xPx(_s2p(10)), yPx(10));
    areaPath.lineTo(l, t);
    areaPath.close();
    canvas.drawPath(areaPath, Paint()..color = color.withOpacity(0.1));

    // Curve line
    final curvePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final pt in pts.skip(1)) curvePath.lineTo(pt.dx, pt.dy);
    canvas.drawPath(
      curvePath,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // User dot
    final userPct = _s2p(score);
    final mx = xPx(userPct);
    final my = yPx(score);

    // Crosshairs
    final dashPaint = Paint()..color = color.withOpacity(0.6)..strokeWidth = 0.8;
    _drawDashed(canvas, Offset(l, my), Offset(size.width - r, my), dashPaint);
    _drawDashed(canvas, Offset(mx, t), Offset(mx, size.height - b), dashPaint);

    // Glow + dot
    canvas.drawCircle(Offset(mx, my), 7,
        Paint()..color = color.withOpacity(0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawCircle(Offset(mx, my), 3.5, Paint()..color = color);

    // Label
    final labelTxt = 'top ${userPct.toStringAsFixed(1)}%';
    final labelStyle = TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700);
    _drawText(canvas, labelTxt, Offset(mx < l + cw * 0.75 ? mx + 6 : mx - 6, my - 10),
        labelStyle, mx < l + cw * 0.75 ? TextAlign.left : TextAlign.right);
  }

  void _drawDashed(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final total = (p2 - p1).distance;
    final dir = (p2 - p1) / total;
    double d = 0;
    bool on = true;
    while (d < total) {
      const seg = 4.0;
      if (on) canvas.drawLine(p1 + dir * d, p1 + dir * math.min(d + seg, total), paint);
      d += seg;
      on = !on;
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, TextStyle style, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    double dx;
    if (align == TextAlign.center) dx = pos.dx - tp.width / 2;
    else if (align == TextAlign.right) dx = pos.dx - tp.width;
    else dx = pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.score != score || old.color != color;
}
