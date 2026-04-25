// screens/landmark_editor_screen.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'results_screen.dart';


// ─── Landmark metadata ────────────────────────────────────────────────────────

const Map<String, String> kLandmarkLabels = {
  'nasion': 'Nasion (Nose Bridge)',
  'pronasale': 'Nose Tip',
  'subnasale': 'Subnasale',
  'al_L': 'Left Nostril',
  'al_R': 'Right Nostril',
  'ex_L': 'Left Eye — Outer Corner',
  'ex_R': 'Right Eye — Outer Corner',
  'en_L': 'Left Eye — Inner Corner',
  'en_R': 'Right Eye — Inner Corner',
  'eye_top_L': 'Left Upper Eyelid',
  'eye_bot_L': 'Left Lower Eyelid',
  'eye_top_R': 'Right Upper Eyelid',
  'eye_bot_R': 'Right Lower Eyelid',
  'pupil_L': 'Left Pupil',
  'pupil_R': 'Right Pupil',
  'brow_out_L': 'Left Brow — Outer',
  'brow_in_L': 'Left Brow — Inner',
  'brow_apex_L': 'Left Brow — Peak',
  'brow_out_R': 'Right Brow — Outer',
  'brow_in_R': 'Right Brow — Inner',
  'brow_apex_R': 'Right Brow — Peak',
  'ls': 'Upper Lip Centre',
  'li': 'Lower Lip Centre',
  'ch_L': 'Left Mouth Corner',
  'ch_R': 'Right Mouth Corner',
  'upper_lip_top': 'Upper Lip Top',
  'lower_lip_bot': 'Lower Lip Bottom',
  'pogonion': 'Chin (Pogonion)',
  'go_L': 'Left Jaw Angle',
  'go_R': 'Right Jaw Angle',
  'zy_L': 'Left Cheekbone',
  'zy_R': 'Right Cheekbone',
  'glabella': 'Glabella',
  'trichion': 'Hairline',
  'temp_L': 'Left Temple',
  'temp_R': 'Right Temple',
  'neck_L': 'Left Neck',
  'neck_R': 'Right Neck',
  'cheek_L': 'Left Cheek',
  'cheek_R': 'Right Cheek',
  'philtrum_top': 'Philtrum',
  'nose_bridge': 'Mid Nose Bridge',
  'columella_L': 'Left Columella',
  'columella_R': 'Right Columella',
  'jaw_L': 'Left Jaw',
  'jaw_R': 'Right Jaw',
};

String _label(String key) => kLandmarkLabels[key] ?? key;

Color _dotColor(String key) {
  if (key.contains('ex_') || key.contains('en_') ||
      key.contains('eye') || key.contains('pupil')) {
    return const Color(0xFF7BC8F6); // blue — eyes
  }
  if (key.contains('brow')) return const Color(0xFFB983FF); // purple — brows
  if (key.contains('nasion') || key.contains('pronasale') ||
      key.contains('subnasale') || key.startsWith('al_') ||
      key.contains('nose') || key.contains('columella')) {
    return const Color(0xFFF5C842); // yellow — nose
  }
  if (key.contains('ls') || key.contains('li') ||
      key.startsWith('ch_') || key.contains('lip') ||
      key.contains('philtrum')) {
    return const Color(0xFFFF9BAE); // pink — mouth
  }
  if (key.startsWith('go_') || key.contains('pogonion') ||
      key.startsWith('jaw')) {
    return const Color(0xFFFF8C42); // orange — jaw
  }
  if (key.startsWith('zy_') || key.contains('temp') ||
      key.contains('cheek') || key.contains('neck')) {
    return const Color(0xFF00D4AA); // teal — face outline
  }
  return const Color(0xFF98E4C4); // mint — other
}

// Structural connection lines drawn as context guides
const List<List<String>> kConnections = [
  ['ex_L', 'en_L'], ['ex_R', 'en_R'],              // eyes
  ['brow_out_L', 'brow_apex_L'], ['brow_apex_L', 'brow_in_L'],
  ['brow_out_R', 'brow_apex_R'], ['brow_apex_R', 'brow_in_R'],
  ['nasion', 'pronasale'],                           // nose bridge
  ['al_L', 'subnasale'], ['subnasale', 'al_R'],
  ['ch_L', 'ch_R'], ['ls', 'li'],                   // mouth
  ['zy_L', 'go_L'], ['go_L', 'pogonion'],           // left jaw
  ['zy_R', 'go_R'], ['go_R', 'pogonion'],           // right jaw
  ['zy_L', 'temp_L'], ['zy_R', 'temp_R'],
];

// ─── Painter ──────────────────────────────────────────────────────────────────

class _EditorPainter extends CustomPainter {
  final Map<String, List<double>> landmarks;
  final String? activeKey;
  final Size displaySize;
  final Offset displayOffset;
  final double scale;
  final Offset panOffset;

  const _EditorPainter({
    required this.landmarks,
    required this.activeKey,
    required this.displaySize,
    required this.displayOffset,
    required this.scale,
    required this.panOffset,
  });

  // Convert normalised [0,1] landmark to zoomed screen position
  Offset? _toScreen(String key) {
    final v = landmarks[key];
    if (v == null || v.length < 2) return null;
    // Base position in un-zoomed image space
    final bx = displayOffset.dx + v[0] * displaySize.width;
    final by = displayOffset.dy + v[1] * displaySize.height;
    // Apply scale around the image center
    final cx = displayOffset.dx + displaySize.width / 2;
    final cy = displayOffset.dy + displaySize.height / 2;
    return Offset(
      cx + (bx - cx) * scale + panOffset.dx,
      cy + (by - cy) * scale + panOffset.dy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Connection lines
    final connPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (final conn in kConnections) {
      final p1 = _toScreen(conn[0]);
      final p2 = _toScreen(conn[1]);
      if (p1 != null && p2 != null) canvas.drawLine(p1, p2, connPaint);
    }

    // 2. Regular dots (fixed size regardless of zoom)
    for (final entry in landmarks.entries) {
      final key = entry.key;
      if (key == activeKey) continue;
      final pt = _toScreen(key);
      if (pt == null) continue;
      final color = _dotColor(key);
      canvas.drawCircle(pt, 4.5,
          Paint()..color = Colors.black.withOpacity(0.5));
      canvas.drawCircle(pt, 4.0, Paint()..color = color);
      canvas.drawCircle(pt, 4.0,
          Paint()
            ..color = Colors.white.withOpacity(0.6)
            ..strokeWidth = 0.8
            ..style = PaintingStyle.stroke);
    }

    // 3. Active dot
    if (activeKey != null) {
      final pt = _toScreen(activeKey!);
      if (pt != null) {
        final color = _dotColor(activeKey!);
        canvas.drawCircle(pt, 18,
            Paint()
              ..color = color.withOpacity(0.2)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        canvas.drawCircle(pt, 12,
            Paint()
              ..color = color.withOpacity(0.5)
              ..strokeWidth = 1.5
              ..style = PaintingStyle.stroke);
        canvas.drawCircle(pt, 7, Paint()..color = color);
        canvas.drawCircle(pt, 7,
            Paint()
              ..color = Colors.white
              ..strokeWidth = 1.5
              ..style = PaintingStyle.stroke);
        final cp = Paint()..color = color.withOpacity(0.7)..strokeWidth = 0.8;
        canvas.drawLine(Offset(pt.dx - 16, pt.dy), Offset(pt.dx - 9, pt.dy), cp);
        canvas.drawLine(Offset(pt.dx + 9, pt.dy), Offset(pt.dx + 16, pt.dy), cp);
        canvas.drawLine(Offset(pt.dx, pt.dy - 16), Offset(pt.dx, pt.dy - 9), cp);
        canvas.drawLine(Offset(pt.dx, pt.dy + 9), Offset(pt.dx, pt.dy + 16), cp);
        _drawLabel(canvas, pt, _label(activeKey!), color, size);
      }
    }
  }

  void _drawLabel(Canvas canvas, Offset pt, String text, Color color, Size canvasSize) {
    final tp = TextPainter(
      text: TextSpan(text: text,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();

    const pad = 6.0, arrowH = 6.0;
    final rw = tp.width + pad * 2, rh = tp.height + pad * 2;
    double rx = pt.dx - rw / 2;
    double ry = pt.dy - rh - arrowH - 14;
    bool above = true;
    if (ry < 4) { ry = pt.dy + 14 + arrowH; above = false; }
    rx = rx.clamp(4, canvasSize.width - rw - 4);

    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(rx, ry, rw, rh), const Radius.circular(6));
    canvas.drawRRect(rect, Paint()..color = Colors.black.withOpacity(0.82));
    canvas.drawRRect(rect,
        Paint()..color = color.withOpacity(0.7)..strokeWidth = 1..style = PaintingStyle.stroke);

    final cx = (rx + rw / 2).clamp(rx + 8, rx + rw - 8);
    final arrowPath = Path();
    if (above) {
      arrowPath..moveTo(cx - 5, ry + rh)..lineTo(cx + 5, ry + rh)..lineTo(cx, ry + rh + arrowH)..close();
    } else {
      arrowPath..moveTo(cx - 5, ry)..lineTo(cx + 5, ry)..lineTo(cx, ry - arrowH)..close();
    }
    canvas.drawPath(arrowPath, Paint()..color = Colors.black.withOpacity(0.82));
    canvas.drawPath(arrowPath,
        Paint()..color = color.withOpacity(0.7)..strokeWidth = 0.8..style = PaintingStyle.stroke);
    tp.paint(canvas, Offset(rx + pad, ry + pad));
  }

  @override
  bool shouldRepaint(_EditorPainter old) =>
      old.activeKey != activeKey ||
      old.landmarks != landmarks ||
      old.scale != scale ||
      old.panOffset != panOffset;
}

// ─── Landmark Editor Screen ───────────────────────────────────────────────────

class LandmarkEditorScreen extends StatefulWidget {
  final XFile? frontalXFile;
  final Uint8List? frontalBytes;
  final XFile? profileXFile;
  final Uint8List? profileBytes;

  const LandmarkEditorScreen({
    super.key,
    this.frontalXFile,
    this.frontalBytes,
    this.profileXFile,
    this.profileBytes,
  });

  @override
  State<LandmarkEditorScreen> createState() => _LandmarkEditorScreenState();
}

class _LandmarkEditorScreenState extends State<LandmarkEditorScreen> {
  int _step = 0; // 0 = frontal, 1 = profile
  Map<String, List<double>> _frontalLandmarks = {};
  Map<String, List<double>> _profileLandmarks = {};
  Map<String, List<double>> _initialFrontalLandmarks = {};
  Map<String, List<double>> _initialProfileLandmarks = {};

  double _scale = 1.0;
  final double _minScale = 1.0;
  Offset _panOffset = Offset.zero;
  double _scaleStart = 1.0;
  Offset _panStart = Offset.zero;
  Offset _focalStart = Offset.zero;
  bool _isDraggingLandmark = false;
  bool _isDetecting = true;
  bool _isAnalyzing = false;
  String? _error;
  String? _activeKey;
  Size? _naturalSize;


  @override
  void initState() {
    super.initState();
    // Start at frontal if available, otherwise go straight to profile
    _step = widget.frontalBytes != null ? 0 : 1;
    _decodeAndDetect();
  }

  // ── Getters ──────────────────────────────────────────────────────────────────
  XFile? get _currentXFile =>
      _step == 0 ? widget.frontalXFile : widget.profileXFile;

  Uint8List? get _currentBytes =>
      _step == 0 ? widget.frontalBytes : widget.profileBytes;

  Map<String, List<double>> get _currentLandmarks =>
      _step == 0 ? _frontalLandmarks : _profileLandmarks;

  bool get _hasProfileStep =>
      widget.profileBytes != null && widget.profileXFile != null;

  bool get _isLastStep => _step == 1 || !_hasProfileStep;

  int get _totalSteps => widget.frontalBytes != null && _hasProfileStep ? 2 : 1;
  int get _currentStepDisplay =>
      widget.frontalBytes != null ? _step + 1 : 2;

  String get _stepTitle =>
      _step == 0 ? 'Front View Landmarks' : 'Profile View Landmarks';

  // ── Image decode + detect ─────────────────────────────────────────────────
  Future<void> _decodeAndDetect() async {
    setState(() {
      _isDetecting = true;
      _error = null;
      _naturalSize = null;
      _activeKey = null;
      _scale = 1.0;
      _panOffset = Offset.zero;
    });
    await _decodeCurrentImage();
    await _detectCurrentLandmarks();
  }

  Future<void> _decodeCurrentImage() async {
    final bytes = _currentBytes;
    if (bytes == null) return;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() => _naturalSize =
            Size(frame.image.width.toDouble(), frame.image.height.toDouble()));
      }
    } catch (_) {}
  }

  Future<void> _detectCurrentLandmarks() async {
    final xf = _currentXFile;
    if (xf == null) {
      if (mounted) setState(() => _isDetecting = false);
      return;
    }
    try {
      final lm = await ApiService.detectLandmarks(
        xfile: xf,
        type: _step == 0 ? 'frontal' : 'profile',
      );
      if (!mounted) return;
      // Deep copy for reset
      final copy = lm.map((k, v) => MapEntry(k, List<double>.from(v)));
      setState(() {
        if (_step == 0) {
          _frontalLandmarks = lm;
          _initialFrontalLandmarks = copy;
        } else {
          _profileLandmarks = lm;
          _initialProfileLandmarks = copy;
        }
        _isDetecting = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isDetecting = false;
        });
      }
    }
  }

  // ── Contain rect helper ───────────────────────────────────────────────────
  (Size, Offset) _containRect(Size container, Size natural) {
    final ia = natural.width / natural.height;
    final ca = container.width / container.height;
    double dw, dh, ox, oy;
    if (ia > ca) {
      dw = container.width;
      dh = container.width / ia;
      ox = 0;
      oy = (container.height - dh) / 2;
    } else {
      dh = container.height;
      dw = container.height * ia;
      ox = (container.width - dw) / 2;
      oy = 0;
    }
    return (Size(dw, dh), Offset(ox, oy));
  }

  void _reset() {
    setState(() {
      _scale = 1.0;
      _panOffset = Offset.zero;
      if (_step == 0) {
        _frontalLandmarks = _initialFrontalLandmarks
            .map((k, v) => MapEntry(k, List<double>.from(v)));
      } else {
        _profileLandmarks = _initialProfileLandmarks
            .map((k, v) => MapEntry(k, List<double>.from(v)));
      }
      _activeKey = null;
    });
  }

  void _goNext() {
    setState(() => _step = 1);
    _decodeAndDetect();
  }

  Future<void> _analyze() async {
    setState(() { _isAnalyzing = true; _error = null; });
    try {
      final result = await ApiService.analyzeCombinedWithLandmarks(
        frontalXFile: widget.frontalXFile,
        profileXFile: widget.profileXFile,
        frontalLandmarks:
            _frontalLandmarks.isNotEmpty ? _frontalLandmarks : null,
        profileLandmarks:
            _profileLandmarks.isNotEmpty ? _profileLandmarks : null,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, a, __) => ResultsScreen(
              result: result,
              frontalBytes: widget.frontalBytes,
              profileBytes: widget.profileBytes,
            ),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isAnalyzing = false;
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_stepTitle,
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            Text('Step $_currentStepDisplay of $_totalSteps',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 11)),
          ],
        ),
        actions: [
          if (!_isDetecting && _error == null)
            TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh,
                  color: Color(0xFF7BC8F6), size: 16),
              label: Text('Reset',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF7BC8F6), fontSize: 13)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          _ProgressBar(current: _currentStepDisplay, total: _totalSteps),

          // Image editor area (expands to fill available space)
          Expanded(child: _buildImageArea()),

          // Bottom control panel
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    final bytes = _currentBytes;

    if (_isDetecting) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF00D4AA))),
          SizedBox(height: 16),
          Text('Detecting face landmarks…',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
        ]),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.face_retouching_off,
                color: Color(0xFFFF6B6B), size: 48),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _decodeAndDetect,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4AA),
                  foregroundColor: Colors.black),
            ),
          ]),
        ),
      );
    }

    if (bytes == null || _naturalSize == null) {
      return const Center(
          child: Text('No image', style: TextStyle(color: Colors.white38)));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
      final (displaySize, displayOffset) =
          _containRect(containerSize, _naturalSize!);

      return Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            _onScrollZoom(event, displaySize, displayOffset);
          }
        },
        child: GestureDetector(
          onScaleStart: (d) => _onScaleStart(d, displaySize, displayOffset),
          onScaleUpdate: (d) => _onScaleUpdate(d, displaySize, displayOffset),
          onScaleEnd: (_) => setState(() {
            _activeKey = null;
            _isDraggingLandmark = false;
          }),
          child: Stack(children: [
            // Background
            Container(color: Colors.black),
            // Zoomed image
            Positioned.fill(
              child: ClipRect(
                child: Transform(
                  transform: _buildTransform(displaySize, displayOffset),
                  child: Stack(children: [
                    Positioned(
                      left: displayOffset.dx,
                      top: displayOffset.dy,
                      width: displaySize.width,
                      height: displaySize.height,
                      child: Image.memory(bytes,
                          fit: BoxFit.fill, gaplessPlayback: true),
                    ),
                  ]),
                ),
              ),
            ),
            // Landmark overlay (NOT inside transform — stays screen-space)
            Positioned.fill(
              child: CustomPaint(
                painter: _EditorPainter(
                  landmarks: _currentLandmarks,
                  activeKey: _activeKey,
                  displaySize: displaySize,
                  displayOffset: displayOffset,
                  scale: _scale,
                  panOffset: _panOffset,
                ),
              ),
            ),
            // Legend
            Positioned(top: 10, right: 10, child: _LegendBadge()),
            // Zoom level indicator
            Positioned(
              top: 10,
              left: 10,
              child: _scale > 1.01
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF00D4AA).withOpacity(0.5)),
                      ),
                      child: Text(
                        '${_scale.toStringAsFixed(1)}×',
                        style: const TextStyle(
                            color: Color(0xFF00D4AA),
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    )
                  : const SizedBox(),
            ),
          ]),
        ),
      );
    });
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF111622),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active landmark info / hint
          if (_activeKey != null)
            _ActiveLandmarkInfo(
                name: _label(_activeKey!), color: _dotColor(_activeKey!))
          else
            const _HintRow(),

          const SizedBox(height: 14),

          // Error
          if (_error != null && !_isDetecting)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFFF6B6B), fontSize: 12)),
            ),

          // Action buttons
          Row(children: [
            // Landmark count
            Text(
              '${_currentLandmarks.length} pts',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const Spacer(),
            // Skip button (use auto-detected without editing)
            if (!_isAnalyzing)
              TextButton(
                onPressed: _isLastStep ? _analyze : _goNext,
                child: Text(
                  'Skip →',
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 13),
                ),
              ),
            const SizedBox(width: 8),
            // Main action button
            _ActionButton(
              label: _isLastStep ? 'Analyze' : 'Next →',
              icon: _isLastStep
                  ? Icons.analytics_outlined
                  : Icons.arrow_forward,
              loading: _isAnalyzing,
              onTap: _isLastStep ? _analyze : _goNext,
            ),
          ]),
        ],
      ),
    );
  }

  /// Matrix used to zoom/pan the raw image layer
  Matrix4 _buildTransform(Size displaySize, Offset displayOffset) {
    final cx = displayOffset.dx + displaySize.width / 2;
    final cy = displayOffset.dy + displaySize.height / 2;
    return Matrix4.identity()
      ..translate(cx + _panOffset.dx, cy + _panOffset.dy)
      ..scale(_scale, _scale)
      ..translate(-cx, -cy);
  }

  /// Convert zoomed screen position back to normalised [0,1] image coords
  List<double> _screenToNorm(
      Offset screenPos, Size displaySize, Offset displayOffset) {
    final cx = displayOffset.dx + displaySize.width / 2;
    final cy = displayOffset.dy + displaySize.height / 2;
    final unzoomed = Offset(
      (screenPos.dx - cx - _panOffset.dx) / _scale + cx,
      (screenPos.dy - cy - _panOffset.dy) / _scale + cy,
    );
    final nx = ((unzoomed.dx - displayOffset.dx) / displaySize.width)
        .clamp(0.0, 1.0);
    final ny = ((unzoomed.dy - displayOffset.dy) / displaySize.height)
        .clamp(0.0, 1.0);
    return [nx, ny];
  }

  /// Find the nearest landmark to a screen position (in zoomed space)
  String? _nearestLandmark(
      Offset screenPos, Size displaySize, Offset displayOffset) {
    final cx = displayOffset.dx + displaySize.width / 2;
    final cy = displayOffset.dy + displaySize.height / 2;
    double closest = double.infinity;
    String? key;
    for (final e in _currentLandmarks.entries) {
      final bx = displayOffset.dx + e.value[0] * displaySize.width;
      final by = displayOffset.dy + e.value[1] * displaySize.height;
      final sx = cx + (bx - cx) * _scale + _panOffset.dx;
      final sy = cy + (by - cy) * _scale + _panOffset.dy;
      final d = (screenPos - Offset(sx, sy)).distance;
      if (d < closest && d < 30) { closest = d; key = e.key; }
    }
    return key;
  }

  void _onScaleStart(ScaleStartDetails d, Size ds, Offset off) {
    final nearKey = _nearestLandmark(d.localFocalPoint, ds, off);
    if (nearKey != null && d.pointerCount == 1) {
      // Single finger near landmark → drag mode
      setState(() {
        _isDraggingLandmark = true;
        _activeKey = nearKey;
      });
    } else {
      // Pinch or single finger on empty area → zoom/pan mode
      _isDraggingLandmark = false;
      _scaleStart = _scale;
      _panStart = _panOffset;
      _focalStart = d.localFocalPoint;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails d, Size ds, Offset off) {
    if (_isDraggingLandmark && _activeKey != null) {
      final norm = _screenToNorm(d.localFocalPoint, ds, off);
      setState(() {
        if (_step == 0) _frontalLandmarks[_activeKey!] = norm;
        else _profileLandmarks[_activeKey!] = norm;
      });
    } else {
      // Zoom + pan
      final newScale =
          (_scaleStart * d.scale).clamp(_minScale, 6.0);
      final panDelta = d.localFocalPoint - _focalStart;
      setState(() {
        _scale = newScale;
        _panOffset = _panStart + panDelta;
      });
    }
  }

  void _onScrollZoom(
    PointerScrollEvent event,
    Size displaySize,
    Offset displayOffset,
  ) {
    // Zoom sensitivity (tweak this)
    const zoomSpeed = 0.0015;

    final zoomDelta = -event.scrollDelta.dy * zoomSpeed;

    final newScale = (_scale + zoomDelta).clamp(_minScale, 6.0);

    // 🔥 KEY PART: zoom towards cursor (not center)
    final focalPoint = event.localPosition;

    final cx = displayOffset.dx + displaySize.width / 2;
    final cy = displayOffset.dy + displaySize.height / 2;

    final before = Offset(
      (focalPoint.dx - cx - _panOffset.dx) / _scale,
      (focalPoint.dy - cy - _panOffset.dy) / _scale,
    );

    final after = Offset(
      (focalPoint.dx - cx - _panOffset.dx) / newScale,
      (focalPoint.dy - cy - _panOffset.dy) / newScale,
    );

    setState(() {
      _scale = newScale;

      // adjust pan so zoom centers on cursor
      _panOffset += (after - before) * newScale;
    });
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 1.0 : current / total;
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.white12,
      valueColor: const AlwaysStoppedAnimation(Color(0xFF00D4AA)),
      minHeight: 2,
    );
  }
}

class _LegendBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const groups = [
      ('Eyes', Color(0xFF7BC8F6)),
      ('Brows', Color(0xFFB983FF)),
      ('Nose', Color(0xFFF5C842)),
      ('Mouth', Color(0xFFFF9BAE)),
      ('Jaw', Color(0xFFFF8C42)),
      ('Face', Color(0xFF00D4AA)),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groups
            .map((g) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                              color: g.$2, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(g.$1,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 9)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ActiveLandmarkInfo extends StatelessWidget {
  final String name;
  final Color color;
  const _ActiveLandmarkInfo({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          'Dragging: $name',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    ]);
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(Icons.touch_app_outlined, color: Color(0xFF00D4AA), size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'Drag any coloured dot to adjust its position for better accuracy',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
        ),
      ),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF00D4AA), Color(0xFF0099CC)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF00D4AA).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ],
        ),
        child: loading
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white)))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: Colors.white, size: 17),
                const SizedBox(width: 8),
                Text(label,
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ]),
      ),
    );
  }
}
