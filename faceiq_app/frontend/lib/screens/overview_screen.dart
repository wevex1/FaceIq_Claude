// lib/screens/overview_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analysis_result.dart';
import '../widgets/population_chart.dart';
import 'category_panel_screen.dart';

// ─── Category config ──────────────────────────────────────────────────────────

class _CatConfig {
  final String key, name;
  final Color color, light;
  final IconData icon;
  const _CatConfig(this.key, this.name, this.color, this.light, this.icon);
}

const _cats = [
  _CatConfig('harmony',    'Harmony',    Color(0xFF534AB7), Color(0xFFEEEDFE), Icons.balance),
  _CatConfig('angularity', 'Angularity', Color(0xFF0F6E56), Color(0xFFE1F5EE), Icons.show_chart),
  _CatConfig('dimorphism', 'Dimorphism', Color(0xFFD85A30), Color(0xFFFAECE7), Icons.person),
  _CatConfig('features',   'Features',   Color(0xFFD4537E), Color(0xFFFBEAF0), Icons.face_retouching_natural),
];

// ─── Overview Screen ──────────────────────────────────────────────────────────

class OverviewScreen extends StatefulWidget {
  final CombinedResult result;
  final Uint8List? frontalBytes;
  final Uint8List? profileBytes;

  const OverviewScreen({
    super.key,
    required this.result,
    this.frontalBytes,
    this.profileBytes,
  });

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  int _activeTab = 0; // 0=harmony 1=angularity 2=dimorphism 3=features

  double get _overallScore {
    final scores = <double>[];
    if (widget.result.frontal?.success == true) scores.add(widget.result.frontal!.overallScore);
    if (widget.result.profile?.success == true) scores.add(widget.result.profile!.overallScore);
    if (scores.isEmpty) return widget.result.combinedScore;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  // Map categories from analysis results by name
  CategoryResult? _catResult(String key) {
    final frontal = widget.result.frontal;
    if (frontal == null || !frontal.success) return null;
    final name = _cats.firstWhere((c) => c.key == key).name.toLowerCase();
    try {
      return frontal.categories.firstWhere(
        (c) => c.category.toLowerCase().contains(name),
      );
    } catch (_) {
      return frontal.categories.isNotEmpty ? frontal.categories.first : null;
    }
  }

  double _catScore(String key) => _catResult(key)?.averageScore ?? 0.0;
  double _frontScore(String key) => _catResult(key)?.averageScore ?? 0.0;
  double? _sideScore(String key) => key == 'harmony' ? widget.result.profile?.overallScore : null;

  _CatConfig get _activeCat => _cats[_activeTab];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Analysis Results',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _ScorePill(score: _overallScore),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(children: [
          // ── Row 1: 4 category cards ──────────────────────────────────────
          Row(children: List.generate(4, (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
              child: _CategoryNavCard(
                config: _cats[i],
                score: _catScore(_cats[i].key),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CategoryPanelScreen(
                    initialCategory: _cats[i].key,
                    result: widget.result,
                    frontalBytes: widget.frontalBytes,
                    profileBytes: widget.profileBytes,
                  ),
                )),
              ),
            ),
          ))),

          const SizedBox(height: 10),

          // ── Row 2: Overall score panel ───────────────────────────────────
          _ScorePanel(
            overallScore: _overallScore,
            activeTab: _activeTab,
            activeCat: _activeCat,
            catScore: _catScore(_activeCat.key),
            frontScore: _frontScore(_activeCat.key),
            sideScore: _sideScore(_activeCat.key),
            frontalBytes: widget.frontalBytes,
            profileBytes: widget.profileBytes,
            onTabChanged: (i) => setState(() => _activeTab = i),
            onPhotoTap: (sub) => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CategoryPanelScreen(
                initialCategory: _activeCat.key,
                initialSide: sub,
                result: widget.result,
                frontalBytes: widget.frontalBytes,
                profileBytes: widget.profileBytes,
              ),
            )),
          ),
        ]),
      ),
    );
  }
}

// ─── Category nav card ────────────────────────────────────────────────────────

class _CategoryNavCard extends StatelessWidget {
  final _CatConfig config;
  final double score;
  final VoidCallback onTap;
  const _CategoryNavCard({required this.config, required this.score, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF111622),
          borderRadius: BorderRadius.circular(12),
          border: Border(top: BorderSide(color: config.color, width: 2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(color: config.light, borderRadius: BorderRadius.circular(6)),
              child: Icon(config.icon, color: config.color, size: 14),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward, color: Colors.white38, size: 12),
          ]),
          const SizedBox(height: 6),
          Text('category', style: TextStyle(color: Colors.white38, fontSize: 9,
              letterSpacing: 0.8, fontFamily: GoogleFonts.inter().fontFamily)),
          Text(config.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600,
              fontSize: 12, fontFamily: GoogleFonts.inter().fontFamily)),
          const SizedBox(height: 2),
          Text(score.toStringAsFixed(1),
              style: TextStyle(color: config.color, fontWeight: FontWeight.w600, fontSize: 17,
                  fontFamily: GoogleFonts.spaceGrotesk().fontFamily)),
        ]),
      ),
    );
  }
}

// ─── Score panel ─────────────────────────────────────────────────────────────

class _ScorePanel extends StatelessWidget {
  final double overallScore;
  final int activeTab;
  final _CatConfig activeCat;
  final double catScore, frontScore;
  final double? sideScore;
  final Uint8List? frontalBytes, profileBytes;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onPhotoTap;

  const _ScorePanel({
    required this.overallScore,
    required this.activeTab,
    required this.activeCat,
    required this.catScore,
    required this.frontScore,
    required this.sideScore,
    required this.frontalBytes,
    required this.profileBytes,
    required this.onTabChanged,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111622),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: [
        // Header: overall score
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: Row(children: [
            Text(overallScore.toStringAsFixed(1),
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 34)),
            const SizedBox(width: 4),
            Text('/10', style: const TextStyle(color: Colors.white54, fontSize: 15)),
            const SizedBox(width: 8),
            Text('overall score', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ),
        Divider(height: 1, thickness: 0.5, color: Colors.white.withOpacity(0.08),
            indent: 18, endIndent: 18),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Left col
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Tab buttons
                Row(children: List.generate(4, (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 5 : 0),
                    child: _TabButton(
                      label: _cats[i].name,
                      color: _cats[i].color,
                      light: _cats[i].light,
                      active: activeTab == i,
                      onTap: () => onTabChanged(i),
                    ),
                  ),
                ))),
                const SizedBox(height: 12),
                // Category score row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(catScore.toStringAsFixed(1),
                        style: GoogleFonts.spaceGrotesk(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 36)),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${activeCat.name} metrics',
                          style: const TextStyle(color: Colors.white60, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('frontal & profile',
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                // Photo cards
                Row(children: [
                  Expanded(child: _PhotoThumb(
                    label: 'Front',
                    score: frontScore,
                    imageBytes: frontalBytes,
                    onTap: () => onPhotoTap('front'),
                  )),
                  const SizedBox(width: 8),
                  if (sideScore != null)
                    Expanded(child: _PhotoThumb(
                      label: 'Side',
                      score: sideScore!,
                      imageBytes: profileBytes,
                      onTap: () => onPhotoTap('side'),
                    ))
                  else
                    const Expanded(child: SizedBox()),
                ]),
              ]),
            ),
            const SizedBox(width: 14),
            // Right col: chart
            Expanded(
              child: SizedBox(
                height: 200,
                child: PopulationChart(score: catScore, color: activeCat.color),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Tab button ───────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final Color color, light;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.color, required this.light,
      required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: active ? light : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color.withOpacity(0.6) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                color: active ? color : Colors.white54,
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                fontFamily: GoogleFonts.inter().fontFamily,
              )),
        ),
      ),
    );
  }
}

// ─── Photo thumb ──────────────────────────────────────────────────────────────

class _PhotoThumb extends StatelessWidget {
  final String label;
  final double score;
  final Uint8List? imageBytes;
  final VoidCallback onTap;
  const _PhotoThumb({required this.label, required this.score,
      required this.imageBytes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: imageBytes != null
                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFF1A1F2E),
                    child: const Center(
                      child: Icon(Icons.face, color: Colors.white12, size: 28),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF0F1420),
            child: Row(children: [
              Text(score.toStringAsFixed(1),
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 9,
                      fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Score pill ───────────────────────────────────────────────────────────────

class _ScorePill extends StatelessWidget {
  final double score;
  const _ScorePill({required this.score});

  Color get _color {
    if (score >= 8.0) return const Color(0xFF00D4AA);
    if (score >= 6.0) return const Color(0xFF7BC8F6);
    if (score >= 4.0) return const Color(0xFFF5C842);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text('${score.toStringAsFixed(1)}/10',
          style: TextStyle(color: _color, fontWeight: FontWeight.w800, fontSize: 13,
              fontFamily: GoogleFonts.spaceGrotesk().fontFamily)),
    );
  }
}
