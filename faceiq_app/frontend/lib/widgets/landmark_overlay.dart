// widgets/landmark_overlay.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ─── Visual instruction types ─────────────────────────────────────────────────
// Each element is a list: first item is the type, rest are landmark keys
//  ['line',   'lm1', 'lm2']          → line between two landmarks
//  ['hline',  'lm']                  → full-width horizontal line at landmark's y
//  ['angle',  'A', 'vertex', 'C']    → two lines + arc at vertex
//  ['dot',    'lm']                  → highlighted circle at landmark
//  ['vline',  'lm']                  → vertical line at landmark's x

class _Viz {
  final List<List<String>> primary;
  final List<List<String>> secondary;
  const _Viz(this.primary, [this.secondary = const []]);
}

// ─── Per-metric visual definitions ────────────────────────────────────────────
const Map<String, _Viz> kMetricVisuals = {
  // ── Facial Thirds ──────────────────────────────────────────────────────────
  'Upper Third': _Viz([
    ['hline', 'glabella'],
    ['hline', 'nasion'],
  ]),
  'Middle Third': _Viz([
    ['hline', 'nasion'],
    ['hline', 'subnasale'],
  ]),
  'Lower Third': _Viz([
    ['hline', 'subnasale'],
    ['hline', 'pogonion'],
  ]),
  'Upper-to-Lower Third Ratio': _Viz([
    ['hline', 'glabella'],
    ['hline', 'nasion'],
  ], [
    ['hline', 'subnasale'],
    ['hline', 'pogonion'],
  ]),
  'Mid-to-Lower Third Ratio': _Viz([
    ['hline', 'nasion'],
    ['hline', 'subnasale'],
  ], [
    ['hline', 'subnasale'],
    ['hline', 'pogonion'],
  ]),

  // ── Face Shape ─────────────────────────────────────────────────────────────
  'Face Width-to-Height Ratio (FWHR)': _Viz([
    ['line', 'zy_L', 'zy_R'],
  ], [
    ['line', 'nasion', 'ls'],
  ]),
  'Total Facial Width/Height Ratio': _Viz([
    ['line', 'zy_L', 'zy_R'],
  ], [
    ['line', 'nasion', 'pogonion'],
  ]),
  'Midface Ratio': _Viz([
    ['line', 'nasion', 'subnasale'],
  ], [
    ['line', 'subnasale', 'pogonion'],
  ]),
  'Bitemporal Width': _Viz([
    ['line', 'temp_L', 'temp_R'],
  ], [
    ['line', 'zy_L', 'zy_R'],
  ]),
  'Bigonial Width': _Viz([
    ['line', 'go_L', 'go_R'],
  ], [
    ['line', 'zy_L', 'zy_R'],
  ]),
  'Facial Index': _Viz([
    ['line', 'nasion', 'pogonion'],
  ], [
    ['line', 'zy_L', 'zy_R'],
  ]),

  // ── Eyes & Brows ───────────────────────────────────────────────────────────
  'Eye Aspect Ratio': _Viz([
    ['line', 'ex_L', 'en_L'],
    ['line', 'ex_R', 'en_R'],
  ], [
    ['line', 'eye_top_L', 'eye_bot_L'],
    ['line', 'eye_top_R', 'eye_bot_R'],
  ]),
  'Eye Symmetry': _Viz([
    ['line', 'ex_L', 'en_L'],
    ['line', 'eye_top_L', 'eye_bot_L'],
  ], [
    ['line', 'ex_R', 'en_R'],
    ['line', 'eye_top_R', 'eye_bot_R'],
  ]),
  'Eye Separation Ratio': _Viz([
    ['line', 'en_L', 'en_R'],
  ], [
    ['line', 'zy_L', 'zy_R'],
  ]),
  'One-Eye-Apart Test': _Viz([
    ['line', 'pupil_L', 'pupil_R'],
  ], [
    ['line', 'ex_L', 'en_L'],
  ]),
  'Lateral Canthal Tilt': _Viz([
    ['line', 'ex_L', 'ex_R'],
    ['dot', 'ex_L'],
    ['dot', 'ex_R'],
  ]),
  'Eyebrow Tilt': _Viz([
    ['line', 'brow_out_L', 'brow_out_R'],
    ['dot', 'brow_out_L'],
    ['dot', 'brow_out_R'],
  ]),
  'Brow Length / Face Width': _Viz([
    ['line', 'brow_out_L', 'brow_in_L'],
    ['line', 'brow_out_R', 'brow_in_R'],
  ], [
    ['line', 'zy_L', 'zy_R'],
  ]),
  'Eyebrow Height (L)': _Viz([
    ['line', 'brow_apex_L', 'eye_top_L'],
    ['dot', 'brow_apex_L'],
    ['dot', 'eye_top_L'],
  ]),
  'Brow Arch Height Ratio': _Viz([
    ['line', 'brow_in_L', 'brow_apex_L'],
    ['line', 'brow_apex_L', 'brow_out_L'],
    ['dot', 'brow_apex_L'],
  ]),
  'Intercanthal / Eye Width': _Viz([
    ['line', 'en_L', 'en_R'],
  ], [
    ['line', 'ex_L', 'en_L'],
  ]),

  // ── Nose (Frontal) ─────────────────────────────────────────────────────────
  'Intercanthal / Nasal Width Ratio': _Viz([
    ['line', 'en_L', 'en_R'],
  ], [
    ['line', 'al_L', 'al_R'],
  ]),
  'Nose Bridge / Width Ratio': _Viz([
    ['line', 'nasion', 'pronasale'],
  ], [
    ['line', 'al_L', 'al_R'],
  ]),
  'Nasal Width / Face Width': _Viz([
    ['line', 'al_L', 'al_R'],
  ], [
    ['line', 'zy_L', 'zy_R'],
  ]),
  'Nose Tip Deviation': _Viz([
    ['line', 'nasion', 'pogonion'],
    ['dot', 'pronasale'],
  ]),
  'Ipsilateral Alar Angle (Left)': _Viz([
    ['angle', 'al_L', 'subnasale', 'pronasale'],
  ]),
  'Ipsilateral Alar Angle (Right)': _Viz([
    ['angle', 'al_R', 'subnasale', 'pronasale'],
  ]),
  'IAA Left-Right Deviation': _Viz([
    ['angle', 'al_L', 'subnasale', 'pronasale'],
  ], [
    ['angle', 'al_R', 'subnasale', 'pronasale'],
  ]),
  'Jaw Frontal Angle': _Viz([
    ['angle', 'go_L', 'pogonion', 'go_R'],
  ]),
  'Nose Height / Face Height': _Viz([
    ['line', 'nasion', 'subnasale'],
  ], [
    ['line', 'nasion', 'pogonion'],
  ]),

  // ── Mouth & Lips ───────────────────────────────────────────────────────────
  'Lower / Upper Lip Ratio': _Viz([
    ['line', 'subnasale', 'ls'],
  ], [
    ['line', 'ls', 'li'],
  ]),
  'Mouth Width / Interpupillary Distance': _Viz([
    ['line', 'ch_L', 'ch_R'],
  ], [
    ['line', 'pupil_L', 'pupil_R'],
  ]),
  'Mouth Width / Nose Width': _Viz([
    ['line', 'ch_L', 'ch_R'],
  ], [
    ['line', 'al_L', 'al_R'],
  ]),
  'Mouth Width / Face Width': _Viz([
    ['line', 'ch_L', 'ch_R'],
  ], [
    ['line', 'zy_L', 'zy_R'],
  ]),
  'Chin / Philtrum Ratio': _Viz([
    ['line', 'subnasale', 'pogonion'],
  ], [
    ['line', 'subnasale', 'ls'],
  ]),
  'Philtrum Height / Face Height': _Viz([
    ['line', 'subnasale', 'ls'],
    ['dot', 'subnasale'],
    ['dot', 'ls'],
  ]),
  'Mouth Corner Tilt': _Viz([
    ['line', 'ch_L', 'ch_R'],
    ['dot', 'ch_L'],
    ['dot', 'ch_R'],
  ]),
  'Upper Vermilion Height / Face Height': _Viz([
    ['line', 'ls', 'upper_lip_top'],
    ['dot', 'ls'],
    ['dot', 'upper_lip_top'],
  ]),
  'Lower Lip / Chin Height Ratio': _Viz([
    ['line', 'li', 'pogonion'],
  ], [
    ['line', 'ls', 'li'],
  ]),

  // ── Jaw & Chin ─────────────────────────────────────────────────────────────
  'Lower Third Proportion': _Viz([
    ['hline', 'subnasale'],
    ['hline', 'pogonion'],
  ], [
    ['hline', 'nasion'],
  ]),
  'Jaw Slope Angle': _Viz([
    ['line', 'go_L', 'pogonion'],
    ['line', 'pogonion', 'go_R'],
    ['dot', 'pogonion'],
  ]),
  'Bigonial / Bizygomatic Ratio': _Viz([
    ['line', 'go_L', 'go_R'],
  ], [
    ['line', 'zy_L', 'zy_R'],
  ]),
  'Face Taper Index': _Viz([
    ['line', 'zy_L', 'zy_R'],
  ], [
    ['line', 'go_L', 'go_R'],
  ]),
  'Neck Width / Face Width': _Viz([
    ['line', 'neck_L', 'neck_R'],
  ], [
    ['line', 'zy_L', 'zy_R'],
  ]),
  'Chin Height / Lower Third': _Viz([
    ['line', 'li', 'pogonion'],
  ], [
    ['line', 'subnasale', 'pogonion'],
  ]),
  'Gonion Position (% from nasion)': _Viz([
    ['hline', 'go_L'],
    ['dot', 'go_L'],
    ['dot', 'go_R'],
  ]),

  // ── Upper Face Profile ─────────────────────────────────────────────────────
  'Upper Forehead Slope': _Viz([
    ['line', 'glabella', 'trichion'],
    ['dot', 'glabella'],
    ['dot', 'trichion'],
  ]),
  'Browridge Inclination': _Viz([
    ['line', 'glabella', 'brow_apex_L'],
    ['dot', 'glabella'],
    ['dot', 'brow_apex_L'],
  ]),
  'Nasofrontal Angle': _Viz([
    ['angle', 'glabella', 'nasion', 'pronasale'],
  ]),
  'Forehead Height / Face Height': _Viz([
    ['line', 'glabella', 'nasion'],
  ], [
    ['line', 'nasion', 'pogonion'],
  ]),

  // ── Facial Convexity ───────────────────────────────────────────────────────
  'Facial Convexity (Glabella)': _Viz([
    ['angle', 'glabella', 'subnasale', 'pogonion'],
  ]),
  'Facial Convexity (Nasion)': _Viz([
    ['angle', 'nasion', 'subnasale', 'pogonion'],
  ]),
  'Total Facial Convexity': _Viz([
    ['angle', 'glabella', 'pronasale', 'pogonion'],
  ]),
  'Anterior Facial Depth Ratio': _Viz([
    ['line', 'nasion', 'pogonion'],
    ['dot', 'nasion'],
    ['dot', 'pogonion'],
  ]),
  'Facial Depth / Height Ratio': _Viz([
    ['line', 'glabella', 'pogonion'],
  ], [
    ['line', 'nasion', 'pogonion'],
  ]),
  'Z Angle': _Viz([
    ['angle', 'ex_L', 'pogonion', 'pronasale'],
  ]),
  'Interior Midface Projection Angle': _Viz([
    ['line', 'nasion', 'pronasale'],
    ['dot', 'nasion'],
    ['dot', 'pronasale'],
  ]),

  // ── Nose Profile ───────────────────────────────────────────────────────────
  'Nasolabial Angle': _Viz([
    ['angle', 'pronasale', 'subnasale', 'ls'],
  ]),
  'Nasomental Angle': _Viz([
    ['angle', 'nasion', 'pronasale', 'pogonion'],
  ]),
  'Nasofacial Angle': _Viz([
    ['angle', 'glabella', 'nasion', 'pronasale'],
  ]),
  'Nasal Projection Ratio': _Viz([
    ['line', 'nasion', 'pronasale'],
  ], [
    ['line', 'nasion', 'pogonion'],
  ]),
  'Nose Tip Rotation Angle': _Viz([
    ['line', 'subnasale', 'pronasale'],
    ['dot', 'pronasale'],
  ]),
  'Nasal Tip Angle': _Viz([
    ['angle', 'nasion', 'pronasale', 'subnasale'],
  ]),
  'Frankfort-Tip Angle': _Viz([
    ['angle', 'ex_L', 'nasion', 'pronasale'],
  ]),
  'Nasal Bridge Inclination': _Viz([
    ['line', 'nasion', 'pronasale'],
    ['dot', 'nasion'],
    ['dot', 'pronasale'],
  ]),

  // ── Lips Profile ───────────────────────────────────────────────────────────
  'Upper Lip E-Line Position': _Viz([
    ['line', 'pronasale', 'pogonion'],
    ['dot', 'ls'],
  ]),
  'Lower Lip E-Line Position': _Viz([
    ['line', 'pronasale', 'pogonion'],
    ['dot', 'li'],
  ]),
  'Upper Lip S-Line Position': _Viz([
    ['line', 'subnasale', 'pogonion'],
    ['dot', 'ls'],
  ]),
  'Lower Lip S-Line Position': _Viz([
    ['line', 'subnasale', 'pogonion'],
    ['dot', 'li'],
  ]),
  'Upper Lip Burstone Position': _Viz([
    ['line', 'subnasale', 'pogonion'],
    ['dot', 'ls'],
  ]),
  'Lower Lip Burstone Position': _Viz([
    ['line', 'subnasale', 'pogonion'],
    ['dot', 'li'],
  ]),
  'Holdaway H-Line Position': _Viz([
    ['line', 'ls', 'pogonion'],
    ['dot', 'subnasale'],
  ]),
  'Mentolabial Angle': _Viz([
    ['angle', 'ls', 'li', 'pogonion'],
  ]),
  'Upper Lip Projection': _Viz([
    ['line', 'nasion', 'pogonion'],
    ['dot', 'ls'],
  ]),

  // ── Jaw Profile ────────────────────────────────────────────────────────────
  'Mandibular Plane Angle': _Viz([
    ['line', 'go_L', 'pogonion'],
    ['dot', 'go_L'],
    ['dot', 'pogonion'],
  ]),
  'Gonial Angle': _Viz([
    ['angle', 'nasion', 'go_L', 'pogonion'],
  ]),
  'Ramus / Mandible Ratio': _Viz([
    ['line', 'nasion', 'go_L'],
  ], [
    ['line', 'go_L', 'pogonion'],
  ]),
  'Chin Projection vs Nasion': _Viz([
    ['line', 'nasion', 'pogonion'],
    ['dot', 'pogonion'],
    ['dot', 'nasion'],
  ]),
  'Chin Height / Lower Third (Profile)': _Viz([
    ['line', 'li', 'pogonion'],
  ], [
    ['line', 'subnasale', 'pogonion'],
  ]),
  'Submental Angle': _Viz([
    ['angle', 'subnasale', 'pogonion', 'go_L'],
  ]),
  'Gonion-to-Mouth Distance': _Viz([
    ['line', 'go_L', 'ch_L'],
    ['dot', 'go_L'],
    ['dot', 'ch_L'],
  ]),
  'Chin Recession vs Eye Vertical': _Viz([
    ['line', 'ex_L', 'pogonion'],
    ['dot', 'ex_L'],
    ['dot', 'pogonion'],
  ]),
};

// ─── CustomPainter ────────────────────────────────────────────────────────────

class LandmarkOverlayPainter extends CustomPainter {
  final Map<String, List<double>> landmarks;
  final String? selectedMetric;
  final Size imageDisplaySize;
  final Offset imageDisplayOffset;

  const LandmarkOverlayPainter({
    required this.landmarks,
    required this.selectedMetric,
    required this.imageDisplaySize,
    required this.imageDisplayOffset,
  });

  /// Map a normalised [0,1] landmark to canvas coordinates
  Offset? _pt(String key) {
    final l = landmarks[key];
    if (l == null || l.length < 2) return null;
    return Offset(
      imageDisplayOffset.dx + l[0] * imageDisplaySize.width,
      imageDisplayOffset.dy + l[1] * imageDisplaySize.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedMetric == null) return;
    final viz = kMetricVisuals[selectedMetric];
    if (viz == null) return;

    const primary   = Color(0xFF00D4AA);
    const secondary = Color(0xFF7BC8F6);

    _drawGroup(canvas, size, viz.primary,   primary);
    _drawGroup(canvas, size, viz.secondary, secondary);
  }

  void _drawGroup(Canvas canvas, Size size,
      List<List<String>> elements, Color color) {
    if (elements.isEmpty) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final dotFill = Paint()..color = color..style = PaintingStyle.fill;

    // Face horizontal span (for hlines)
    final zyL = _pt('zy_L');
    final zyR = _pt('zy_R');
    final xMin = (zyL?.dx ?? imageDisplayOffset.dx) - 18;
    final xMax = (zyR?.dx ?? imageDisplayOffset.dx + imageDisplaySize.width) + 18;

    for (final el in elements) {
      if (el.isEmpty) continue;
      switch (el[0]) {

        case 'line':
          if (el.length < 3) break;
          final p1 = _pt(el[1]);
          final p2 = _pt(el[2]);
          if (p1 == null || p2 == null) break;
          canvas.drawLine(p1, p2, glowPaint);
          canvas.drawLine(p1, p2, linePaint);
          _drawEndDot(canvas, p1, color);
          _drawEndDot(canvas, p2, color);

        case 'hline':
          if (el.length < 2) break;
          final lm = _pt(el[1]);
          if (lm == null) break;
          final p1 = Offset(xMin.clamp(0, size.width), lm.dy);
          final p2 = Offset(xMax.clamp(0, size.width), lm.dy);
          canvas.drawLine(p1, p2, glowPaint);
          canvas.drawLine(p1, p2, linePaint);
          // Tick marks at ends
          for (final px in [p1, p2]) {
            canvas.drawLine(
                Offset(px.dx, px.dy - 6), Offset(px.dx, px.dy + 6), linePaint);
          }

        case 'dot':
          if (el.length < 2) break;
          final lm = _pt(el[1]);
          if (lm == null) break;
          // Glow ring
          canvas.drawCircle(lm, 9,
            Paint()
              ..color = color.withOpacity(0.25)
              ..style = PaintingStyle.fill
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
          // Outer ring
          canvas.drawCircle(lm, 6,
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.8);
          // Inner dot
          canvas.drawCircle(lm, 3, dotFill);

        case 'angle':
          if (el.length < 4) break;
          final A = _pt(el[1]);
          final V = _pt(el[2]); // vertex
          final C = _pt(el[3]);
          if (A == null || V == null || C == null) break;

          // Glow arms
          canvas.drawLine(V, A, glowPaint);
          canvas.drawLine(V, C, glowPaint);
          // Arms
          canvas.drawLine(V, A, linePaint);
          canvas.drawLine(V, C, linePaint);
          // Arc
          _drawAngleArc(canvas, A, V, C, color);
          // Dots
          canvas.drawCircle(V, 4, dotFill);
          canvas.drawCircle(A, 3, dotFill);
          canvas.drawCircle(C, 3, dotFill);
      }
    }
  }

  void _drawEndDot(Canvas canvas, Offset p, Color color) {
    canvas.drawCircle(
        p, 3.5, Paint()..color = color..style = PaintingStyle.fill);
  }

  void _drawAngleArc(
      Canvas canvas, Offset A, Offset V, Offset C, Color color) {
    final VA = A - V;
    final VC = C - V;
    final angleA = math.atan2(VA.dy, VA.dx);
    final angleC = math.atan2(VC.dy, VC.dx);

    final radius = math.min(
      math.min(VA.distance, VC.distance) * 0.28,
      28.0,
    ).clamp(10.0, 28.0);

    double sweep = angleC - angleA;
    while (sweep > math.pi) sweep -= 2 * math.pi;
    while (sweep < -math.pi) sweep += 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: V, radius: radius),
      angleA,
      sweep,
      false,
      Paint()
        ..color = color.withOpacity(0.85)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(LandmarkOverlayPainter old) =>
      old.selectedMetric != selectedMetric ||
      old.landmarks != landmarks ||
      old.imageDisplayOffset != imageDisplayOffset ||
      old.imageDisplaySize != imageDisplaySize;
}

// ─── Overlay Widget ────────────────────────────────────────────────────────────

class LandmarkOverlayWidget extends StatefulWidget {
  final Uint8List imageBytes;
  final Map<String, List<double>> landmarks;
  final String? selectedMetric;
  final double height;

  const LandmarkOverlayWidget({
    super.key,
    required this.imageBytes,
    required this.landmarks,
    this.selectedMetric,
    this.height = 320,
  });

  @override
  State<LandmarkOverlayWidget> createState() => _LandmarkOverlayWidgetState();
}

class _LandmarkOverlayWidgetState extends State<LandmarkOverlayWidget> {
  ui.Image? _uiImage;
  Size? _naturalSize;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(LandmarkOverlayWidget old) {
    super.didUpdateWidget(old);
    if (old.imageBytes != widget.imageBytes) _decodeImage();
  }

  Future<void> _decodeImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _uiImage = frame.image;
        _naturalSize = Size(
            frame.image.width.toDouble(), frame.image.height.toDouble());
      });
    }
  }

  /// Compute where the image is actually rendered (BoxFit.contain)
  (Size displaySize, Offset offset) _computeContainRect(
      Size container, Size natural) {
    final imgAspect = natural.width / natural.height;
    final ctnAspect = container.width / container.height;
    double dw, dh, ox, oy;
    if (imgAspect > ctnAspect) {
      dw = container.width;
      dh = container.width / imgAspect;
      ox = 0;
      oy = (container.height - dh) / 2;
    } else {
      dh = container.height;
      dw = container.height * imgAspect;
      ox = (container.width - dw) / 2;
      oy = 0;
    }
    return (Size(dw, dh), Offset(ox, oy));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final containerSize =
          Size(constraints.maxWidth, widget.height);

      Size displaySize = containerSize;
      Offset displayOffset = Offset.zero;

      if (_naturalSize != null) {
        final (ds, ofs) = _computeContainRect(containerSize, _naturalSize!);
        displaySize = ds;
        displayOffset = ofs;
      }

      return SizedBox(
        width: containerSize.width,
        height: widget.height,
        child: Stack(
          children: [
            // Dark background (visible in letterbox areas)
            Container(color: const Color(0xFF0A0E1A)),
            // Image (BoxFit.contain)
            Positioned(
              left: displayOffset.dx,
              top: displayOffset.dy,
              width: displaySize.width,
              height: displaySize.height,
              child: Image.memory(
                widget.imageBytes,
                fit: BoxFit.fill,
                gaplessPlayback: true,
              ),
            ),
            // Overlay
            if (widget.selectedMetric != null && _naturalSize != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: LandmarkOverlayPainter(
                    landmarks: widget.landmarks,
                    selectedMetric: widget.selectedMetric,
                    imageDisplaySize: displaySize,
                    imageDisplayOffset: displayOffset,
                  ),
                ),
              ),
            // Legend pill
            if (widget.selectedMetric != null)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF00D4AA).withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00D4AA),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.selectedMetric!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // "Tap a metric" hint when nothing selected
            if (widget.selectedMetric == null)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tap any metric below to see its measurement',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
