// lib/screens/category_panel_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analysis_result.dart';
import '../widgets/landmark_overlay.dart';

// ─── Category config ──────────────────────────────────────────────────────────

class _CatMeta {
  final String key, name, fullName, sub, understand;
  final Color color, light, accent;
  final bool hasSide;
  const _CatMeta(this.key, this.name, this.fullName, this.sub,
      this.understand, this.color, this.light, this.accent, this.hasSide);
}

const _metas = [
  _CatMeta('harmony', 'Harmony', 'Harmony metrics', 'frontal & profile',
    'Facial harmony measures the proportional balance and symmetry between your facial features, evaluating how well different parts of your face work together as a cohesive whole.',
    Color(0xFF534AB7), Color(0xFFEEEDFE), Color(0xFF7F77DD), true),
  _CatMeta('angularity', 'Angularity', 'Angularity metrics', 'jawline & structure',
    'Facial angularity measures the sharpness and definition of your facial structure, evaluating bone prominence, jawline definition, and the interplay between soft tissue and underlying skeletal features.',
    Color(0xFF0F6E56), Color(0xFFE1F5EE), Color(0xFF1D9E75), false),
  _CatMeta('dimorphism', 'Dimorphism', 'Sexual dimorphism', 'structure',
    'Dimorphism reflects how strongly your facial features align with typically masculine or feminine traits, based on shape, structure, and soft‑tissue cues.',
    Color(0xFFD85A30), Color(0xFFFAECE7), Color(0xFFD85A30), false),
  _CatMeta('features', 'Features', 'Feature metrics', 'health & attractiveness',
    'Features assessment evaluates skin quality, eye area health, facial creasing, hair condition, and brow definition—key markers of health, youthfulness, and facial attractiveness.',
    Color(0xFFD4537E), Color(0xFFFBEAF0), Color(0xFFD4537E), false),
];

_CatMeta _meta(String key) => _metas.firstWhere((m) => m.key == key, orElse: () => _metas[0]);

// ─── Category Panel Screen ────────────────────────────────────────────────────

class CategoryPanelScreen extends StatefulWidget {
  final String initialCategory;
  final String initialSide;
  final CombinedResult result;
  final Uint8List? frontalBytes, profileBytes;

  const CategoryPanelScreen({
    super.key,
    required this.initialCategory,
    this.initialSide = 'front',
    required this.result,
    this.frontalBytes,
    this.profileBytes,
  });

  @override
  State<CategoryPanelScreen> createState() => _CategoryPanelScreenState();
}

class _CategoryPanelScreenState extends State<CategoryPanelScreen> {
  late String _curCat;
  late String _curSub; // 'front' | 'side'
  bool _understandOpen = false;
  String? _hoveredMetric;

  @override
  void initState() {
    super.initState();
    _curCat = widget.initialCategory;
    _curSub = widget.initialSide;
  }

  _CatMeta get _m => _meta(_curCat);

  AnalysisResult? get _analysis => widget.result.frontal;
  AnalysisResult? get _profileAnalysis => widget.result.profile;

  CategoryResult? get _catResult {
    final src = (_curSub == 'side' && _m.hasSide) ? _profileAnalysis : _analysis;
    if (src == null || !src.success) return null;
    final name = _m.name.toLowerCase();
    try {
      return src.categories.firstWhere((c) => c.category.toLowerCase().contains(name));
    } catch (_) {
      return src.categories.isNotEmpty ? src.categories.first : null;
    }
  }

  double get _frontScore {
    if (_analysis == null || !_analysis!.success) return 0;
    final name = _m.name.toLowerCase();
    try {
      return _analysis!.categories
          .firstWhere((c) => c.category.toLowerCase().contains(name))
          .averageScore;
    } catch (_) {
      return _analysis!.overallScore;
    }
  }

  double get _sideScore => _profileAnalysis?.overallScore ?? 0;

  Uint8List? get _currentPhoto =>
      _curSub == 'side' ? widget.profileBytes : widget.frontalBytes;

  void _switchCat(String key) {
    setState(() {
      _curCat = key;
      _curSub = 'front';
      _understandOpen = false;
      _hoveredMetric = null;
    });
  }

  void _switchSub(String sub) {
    setState(() {
      _curSub = sub;
      _hoveredMetric = null;
    });
  }

  String get _metricsTitle {
    if (_m.hasSide) {
      return _curSub == 'side' ? 'Your Side Ratios' : 'Your Front Ratios';
    }
    return 'Your Measurements';
  }

  String get _photoLabel {
    if (_m.hasSide) {
      return '${_curSub == 'side' ? 'Side' : 'Front'} ${_m.name}';
    }
    return _m.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(children: [
          // ── Top nav bar ─────────────────────────────────────────────────
          _PanelNav(
            curCat: _curCat,
            onBack: () => Navigator.pop(context),
            onCatTap: _switchCat,
          ),
          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: band + photo
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.38,
                  child: Column(children: [
                    // Band above photo
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
                      child: _m.hasSide
                          ? _HarmonyThumbRow(
                              frontScore: _frontScore,
                              sideScore: _sideScore,
                              frontalBytes: widget.frontalBytes,
                              profileBytes: widget.profileBytes,
                              curSub: _curSub,
                              onSwitchSub: _switchSub,
                            )
                          : _CatInfoBand(
                              meta: _m,
                              score: _frontScore,
                              imageBytes: widget.frontalBytes,
                            ),
                    ),
                    // Sticky photo
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 8, 12),
                        child: _StickyPhoto(
                          imageBytes: _currentPhoto,
                          label: _photoLabel,
                          landmarks: _analysis?.landmarks ?? {},
                          hoveredMetric: _hoveredMetric,
                        ),
                      ),
                    ),
                  ]),
                ),
                // Right column: metrics
                Expanded(
                  child: _MetricsPanel(
                    meta: _m,
                    catResult: _catResult,
                    understandOpen: _understandOpen,
                    metricsTitle: _metricsTitle,
                    hoveredMetric: _hoveredMetric,
                    onToggleUnderstand: () =>
                        setState(() => _understandOpen = !_understandOpen),
                    onMetricHover: (n) => setState(() => _hoveredMetric = n),
                    onMetricLeave: () => setState(() => _hoveredMetric = null),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Panel Nav ────────────────────────────────────────────────────────────────

class _PanelNav extends StatelessWidget {
  final String curCat;
  final VoidCallback onBack;
  final ValueChanged<String> onCatTap;

  const _PanelNav({required this.curCat, required this.onBack, required this.onCatTap});

  @override
  Widget build(BuildContext context) {
    const keys = ['harmony', 'angularity', 'dimorphism', 'features'];
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16),
          onPressed: onBack,
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: keys.map((k) {
              final m = _meta(k);
              final active = k == curCat;
              return GestureDetector(
                onTap: () => onCatTap(k),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: active ? Colors.white : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Text(
                    m.name,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white38,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 13,
                      fontFamily: GoogleFonts.inter().fontFamily,
                    ),
                  ),
                ),
              );
            }).toList()),
          ),
        ),
      ]),
    );
  }
}

// ─── Harmony thumb row ────────────────────────────────────────────────────────

class _HarmonyThumbRow extends StatelessWidget {
  final double frontScore, sideScore;
  final Uint8List? frontalBytes, profileBytes;
  final String curSub;
  final ValueChanged<String> onSwitchSub;

  const _HarmonyThumbRow({
    required this.frontScore, required this.sideScore,
    required this.frontalBytes, required this.profileBytes,
    required this.curSub, required this.onSwitchSub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _ThumbCard(
        label: 'FRONT', score: frontScore,
        imageBytes: frontalBytes,
        active: curSub == 'front',
        onTap: () => onSwitchSub('front'),
      )),
      const SizedBox(width: 8),
      Expanded(child: _ThumbCard(
        label: 'SIDE', score: sideScore,
        imageBytes: profileBytes,
        active: curSub == 'side',
        onTap: () => onSwitchSub('side'),
      )),
    ]);
  }
}

class _ThumbCard extends StatelessWidget {
  final String label;
  final double score;
  final Uint8List? imageBytes;
  final bool active;
  final VoidCallback onTap;
  const _ThumbCard({required this.label, required this.score,
      required this.imageBytes, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF111622),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? Colors.white : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: const Color(0xFF1A1F2E),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageBytes != null
                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                : const Icon(Icons.face, color: Colors.white12, size: 18),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(
                color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            Text('${score.toStringAsFixed(1)} ',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
        ]),
      ),
    );
  }
}

// ─── Cat info band (non-harmony) ──────────────────────────────────────────────

class _CatInfoBand extends StatelessWidget {
  final _CatMeta meta;
  final double score;
  final Uint8List? imageBytes;
  const _CatInfoBand({required this.meta, required this.score, required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF111622),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: const Color(0xFF1A1F2E),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageBytes != null
              ? Image.memory(imageBytes!, fit: BoxFit.cover)
              : const Icon(Icons.face, color: Colors.white12, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(meta.name.toUpperCase(),
              style: const TextStyle(color: Colors.white38, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          Text('${score.toStringAsFixed(1)} ',
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ]),
    );
  }
}

// ─── Sticky photo ─────────────────────────────────────────────────────────────

class _StickyPhoto extends StatelessWidget {
  final Uint8List? imageBytes;
  final String label;
  final Map<String, List<double>> landmarks;
  final String? hoveredMetric;

  const _StickyPhoto({
    required this.imageBytes, required this.label,
    required this.landmarks, required this.hoveredMetric,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(children: [
        // Photo or placeholder
        AspectRatio(
          aspectRatio: 3 / 4,
          child: imageBytes != null
              ? Image.memory(imageBytes!, fit: BoxFit.cover, width: double.infinity)
              : Container(
                  color: const Color(0xFF111622),
                  child: const Center(child: Icon(Icons.face_outlined,
                      color: Colors.white12, size: 48)),
                ),
        ),
        // Landmark overlay
        if (hoveredMetric != null && landmarks.isNotEmpty && imageBytes != null)
          Positioned.fill(
            child: LayoutBuilder(builder: (_, c) {
              // compute contain rect
              const nat = Size(3, 4);
              final ctnAr = c.maxWidth / c.maxHeight;
              final imgAr = nat.width / nat.height;
              Size ds;
              Offset off;
              if (imgAr > ctnAr) {
                ds = Size(c.maxWidth, c.maxWidth / imgAr);
                off = Offset(0, (c.maxHeight - ds.height) / 2);
              } else {
                ds = Size(c.maxHeight * imgAr, c.maxHeight);
                off = Offset((c.maxWidth - ds.width) / 2, 0);
              }
              return CustomPaint(
                painter: LandmarkOverlayPainter(
                  landmarks: landmarks,
                  selectedMetric: hoveredMetric,
                  imageDisplaySize: ds,
                  imageDisplayOffset: off,
                ),
              );
            }),
          ),
        // Gradient overlay + label
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xCC0A0E1A), Colors.transparent],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('FACEIQAPP.COM',
                  style: const TextStyle(color: Colors.white38,
                      fontSize: 8, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(label,
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              Text('Score', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Metrics panel ────────────────────────────────────────────────────────────

class _MetricsPanel extends StatelessWidget {
  final _CatMeta meta;
  final CategoryResult? catResult;
  final bool understandOpen;
  final String metricsTitle;
  final String? hoveredMetric;
  final VoidCallback onToggleUnderstand;
  final ValueChanged<String?> onMetricHover;
  final VoidCallback onMetricLeave;

  const _MetricsPanel({
    required this.meta, required this.catResult,
    required this.understandOpen, required this.metricsTitle,
    required this.hoveredMetric,
    required this.onToggleUnderstand,
    required this.onMetricHover, required this.onMetricLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Understanding header
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onToggleUnderstand,
          child: Row(children: [
            Text('Understanding ${meta.name}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: understandOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.keyboard_arrow_down, color: Colors.white38, size: 16),
            ),
          ]),
        ),
        // Understanding body
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111622),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Text(meta.understand,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12, height: 1.6)),
          ),
          crossFadeState:
              understandOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        const SizedBox(height: 10),
        // Title
        Text(metricsTitle,
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 10),
        // Metrics list
        Expanded(
          child: catResult == null
              ? const Center(child: Text('No data', style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  itemCount: catResult!.metrics.length,
                  itemBuilder: (_, i) {
                    final m = catResult!.metrics[i];
                    final isHov = hoveredMetric == m.name;
                    return _MetricRow(
                      metric: m,
                      isHovered: isHov,
                      accentColor: meta.color,
                      onEnter: () => onMetricHover(m.name),
                      onExit: () => onMetricHover(null),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ─── Metric row ───────────────────────────────────────────────────────────────

class _MetricRow extends StatelessWidget {
  final RatioMetric metric;
  final bool isHovered;
  final Color accentColor;
  final VoidCallback onEnter, onExit;

  const _MetricRow({
    required this.metric, required this.isHovered,
    required this.accentColor, required this.onEnter, required this.onExit,
  });

  Color get _valColor {
    final s = metric.score;
    if (s >= 7) return const Color(0xFF2D7A2D);
    if (s >= 5) return const Color(0xFF92400E);
    return const Color(0xFF991B1B);
  }

  Color get _badgeBg {
    final s = metric.score;
    if (s >= 7) return const Color(0xFFEBF5EB);
    if (s >= 5) return const Color(0xFFFEF3C7);
    return const Color(0xFFFEE2E2);
  }

  static const _barGradients = {
    'red':    [Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFF22C55E)],
    'yellow': [Color(0xFFF59E0B), Color(0xFF22C55E)],
    'green':  [Color(0xFF22C55E), Color(0xFF22C55E)],
  };

  List<Color> get _barColors {
    final s = metric.score;
    if (s >= 7) return _barGradients['green']!;
    if (s >= 5) return _barGradients['yellow']!;
    return _barGradients['red']!;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onEnter(),
      onExit: (_) => onExit(),
      child: GestureDetector(
        onTap: onEnter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 2),
          padding: EdgeInsets.symmetric(
              horizontal: isHovered ? 8 : 0, vertical: 10),
          decoration: BoxDecoration(
            color: isHovered
                ? Colors.white.withOpacity(0.04)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
          ),
          child: Row(children: [
            // Name + badge
            SizedBox(
              width: 140,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(metric.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _badgeBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(metric.displayValue,
                      style: TextStyle(color: _valColor,
                          fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            // Gradient bar
            Expanded(
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(colors: _barColors),
                  ),
                ),
                // Thumb
                Positioned(
                  left: (metric.score / 10 * 1).clamp(0.0, 1.0) *
                      (MediaQuery.of(context).size.width * 0.28) - 9,
                  top: -5,
                  child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black.withOpacity(0.15), width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            // Score value
            SizedBox(
              width: 34,
              child: Text(metric.score.toStringAsFixed(2),
                  textAlign: TextAlign.right,
                  style: TextStyle(color: _valColor,
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 14),
          ]),
        ),
      ),
    );
  }
}
