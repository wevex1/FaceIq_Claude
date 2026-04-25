// screens/results_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analysis_result.dart';
import '../widgets/score_gauge.dart';
import '../widgets/metric_card.dart';
import '../widgets/landmark_overlay.dart';

class ResultsScreen extends StatefulWidget {
  final CombinedResult result;
  final Uint8List? frontalBytes;
  final Uint8List? profileBytes;

  const ResultsScreen({
    super.key,
    required this.result,
    this.frontalBytes,
    this.profileBytes,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  int get _tabCount {
    int n = 1;
    if (widget.result.frontal?.success == true) n++;
    if (widget.result.profile?.success == true) n++;
    return n;
  }

  List<String> get _tabLabels {
    final l = <String>['Overview'];
    if (widget.result.frontal?.success == true) l.add('Frontal');
    if (widget.result.profile?.success == true) l.add('Profile');
    return l;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF0A0E1A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white70, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Analysis Results',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _ScorePill(score: widget.result.combinedScore),
              ),
            ],
            bottom: TabBar(
              controller: _tabCtrl,
              tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
              indicatorColor: const Color(0xFF00D4AA),
              indicatorWeight: 2,
              labelColor: const Color(0xFF00D4AA),
              unselectedLabelColor: Colors.white38,
              labelStyle:
                  GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _OverviewTab(result: widget.result),
            if (widget.result.frontal?.success == true)
              _AnalysisTab(
                analysis: widget.result.frontal!,
                imageBytes: widget.frontalBytes,
              ),
            if (widget.result.profile?.success == true)
              _AnalysisTab(
                analysis: widget.result.profile!,
                imageBytes: widget.profileBytes,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final CombinedResult result;
  const _OverviewTab({required this.result});

  String _scoreLabel(double s) {
    if (s >= 8.5) return 'Exceptional';
    if (s >= 7.0) return 'Excellent';
    if (s >= 5.5) return 'Good';
    if (s >= 4.0) return 'Average';
    return 'Below Avg.';
  }

  List<RatioMetric> _topMetrics(AnalysisResult? f, AnalysisResult? p) {
    final all = [...?f?.allMetrics, ...?p?.allMetrics];
    all.sort((a, b) => b.score.compareTo(a.score));
    return all.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final frontal = result.frontal;
    final profile = result.profile;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(children: [
              const SizedBox(height: 10),
              ScoreGauge(
                  score: result.combinedScore,
                  size: 160,
                  centerLabel: _scoreLabel(result.combinedScore)),
              const SizedBox(height: 8),
              Text('Combined Harmony Score',
                  style: GoogleFonts.inter(
                      color: Colors.white54, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 28),
          if (frontal != null && frontal.success) ...[
            _SummaryCard(
              title: 'Frontal Analysis',
              score: frontal.overallScore,
              metrics: frontal.totalMetrics,
              scoreLabel: frontal.scoreLabel,
              icon: Icons.face,
            ),
            const SizedBox(height: 12),
          ],
          if (profile != null && profile.success) ...[
            _SummaryCard(
              title: 'Profile Analysis',
              score: profile.overallScore,
              metrics: profile.totalMetrics,
              scoreLabel: profile.scoreLabel,
              icon: Icons.face_retouching_natural,
            ),
            const SizedBox(height: 20),
          ],
          if (frontal != null && frontal.success) ...[
            _sectionHeader('Category Breakdown'),
            const SizedBox(height: 14),
            _CategoryRadarChart(analysis: frontal),
            const SizedBox(height: 20),
          ],
          _sectionHeader('Top Metrics'),
          const SizedBox(height: 14),
          ..._topMetrics(frontal, profile).map((m) => MetricCard(metric: m)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) => Text(label.toUpperCase(),
      style: GoogleFonts.spaceGrotesk(
          color: Colors.white38,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w700));
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double score;
  final int metrics;
  final String scoreLabel;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.score,
    required this.metrics,
    required this.scoreLabel,
    required this.icon,
  });

  Color get _color {
    if (score >= 8.0) return const Color(0xFF00D4AA);
    if (score >= 6.0) return const Color(0xFF7BC8F6);
    if (score >= 4.0) return const Color(0xFFF5C842);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111622),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
              color: _color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: _color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(height: 2),
            Text('$metrics metrics · $scoreLabel',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(score.toStringAsFixed(1),
              style: TextStyle(
                  color: _color,
                  fontWeight: FontWeight.w800,
                  fontSize: 24)),
          const Text('/10',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
      ]),
    );
  }
}

class _CategoryRadarChart extends StatelessWidget {
  final AnalysisResult analysis;
  const _CategoryRadarChart({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final cats = analysis.categories;
    if (cats.isEmpty) return const SizedBox();
    return Container(
      height: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111622),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: RadarChart(RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries:
                cats.map((c) => RadarEntry(value: c.averageScore)).toList(),
            fillColor: const Color(0xFF00D4AA).withOpacity(0.15),
            borderColor: const Color(0xFF00D4AA),
            borderWidth: 2,
            entryRadius: 3,
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        gridBorderData: const BorderSide(color: Colors.white12, width: 1),
        titleTextStyle:
            GoogleFonts.inter(color: Colors.white54, fontSize: 10),
        getTitle: (i, _) =>
            RadarChartTitle(text: cats[i].category.split(' ').first),
        tickCount: 2,
        tickBorderData: BorderSide.none,
        ticksTextStyle: const TextStyle(fontSize: 0),
        radarBorderData: BorderSide.none,
      )),
    );
  }
}

// ─── Analysis Tab (with landmark overlay) ─────────────────────────────────────

class _AnalysisTab extends StatefulWidget {
  final AnalysisResult analysis;
  final Uint8List? imageBytes;

  const _AnalysisTab({required this.analysis, this.imageBytes});

  @override
  State<_AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<_AnalysisTab> {
  String? _selectedMetric;

  void _selectMetric(String name) {
    setState(() {
      _selectedMetric = (_selectedMetric == name) ? null : name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageBytes != null;
    final hasLandmarks = widget.analysis.landmarks.isNotEmpty;
    final showOverlay = hasImage && hasLandmarks;

    return CustomScrollView(
      slivers: [
        // ── Image + overlay (sticky at top) ───────────────────────────────────
        if (showOverlay)
          SliverToBoxAdapter(
            child: LandmarkOverlayWidget(
              imageBytes: widget.imageBytes!,
              landmarks: widget.analysis.landmarks,
              selectedMetric: _selectedMetric,
              height: 320,
            ),
          ),

        // If image but no landmarks, show plain image
        if (hasImage && !hasLandmarks)
          SliverToBoxAdapter(
            child: ClipRRect(
              child: Image.memory(
                widget.imageBytes!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

        // ── Score summary ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(children: [
              ScoreGauge(
                  score: widget.analysis.overallScore,
                  size: 72,
                  centerLabel: widget.analysis.scoreLabel),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(widget.analysis.scoreLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(
                      '${widget.analysis.totalMetrics} metrics · '
                      '${widget.analysis.landmarkCount} landmarks',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  if (_selectedMetric != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '● Showing: $_selectedMetric',
                      style: const TextStyle(
                          color: Color(0xFF00D4AA),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ]),
              ),
            ]),
          ),
        ),

        // ── Category sections ─────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _CategorySectionSelectable(
                  category: widget.analysis.categories[i],
                  selectedMetric: _selectedMetric,
                  onMetricTap: _selectMetric,
                ),
              ),
              childCount: widget.analysis.categories.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Category section that knows about selected metric ────────────────────────

class _CategorySectionSelectable extends StatefulWidget {
  final CategoryResult category;
  final String? selectedMetric;
  final ValueChanged<String> onMetricTap;

  const _CategorySectionSelectable({
    required this.category,
    required this.selectedMetric,
    required this.onMetricTap,
  });

  @override
  State<_CategorySectionSelectable> createState() =>
      _CategorySectionSelectableState();
}

class _CategorySectionSelectableState
    extends State<_CategorySectionSelectable> {
  bool _open = true;

  Color _avgColor(double score) {
    if (score >= 8.0) return const Color(0xFF00D4AA);
    if (score >= 6.0) return const Color(0xFF7BC8F6);
    if (score >= 4.0) return const Color(0xFFF5C842);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    final avg = widget.category.averageScore;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF111622),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: _avgColor(avg),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: _avgColor(avg).withOpacity(0.6),
                        blurRadius: 6)
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.category.category,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _avgColor(avg).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _avgColor(avg).withOpacity(0.4), width: 1),
                ),
                child: Text('${avg.toStringAsFixed(1)}/10',
                    style: TextStyle(
                        color: _avgColor(avg),
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Icon(
                  _open
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white38,
                  size: 18),
            ]),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          ...widget.category.metrics.map((m) {
            final isSelected = widget.selectedMetric == m.name;
            return _SelectableMetricCard(
              metric: m,
              isSelected: isSelected,
              onTap: () => widget.onMetricTap(m.name),
            );
          }),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

// ─── Metric card with selection state ─────────────────────────────────────────

class _SelectableMetricCard extends StatelessWidget {
  final RatioMetric metric;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableMetricCard({
    required this.metric,
    required this.isSelected,
    required this.onTap,
  });

  Color get _scoreColor {
    final s = metric.score;
    if (s >= 8.0) return const Color(0xFF00D4AA);
    if (s >= 6.0) return const Color(0xFF7BC8F6);
    if (s >= 4.0) return const Color(0xFFF5C842);
    return const Color(0xFFFF6B6B);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00D4AA).withOpacity(0.08)
              : const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00D4AA).withOpacity(0.5)
                : _scoreColor.withOpacity(0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // Score badge
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _scoreColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _scoreColor.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(metric.score.toStringAsFixed(1),
                      style: TextStyle(
                          color: _scoreColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                      child: Text(metric.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                    // Eye icon to indicate overlay available
                    if (kMetricVisuals.containsKey(metric.name))
                      Icon(
                        isSelected
                            ? Icons.visibility
                            : Icons.visibility_outlined,
                        color: isSelected
                            ? const Color(0xFF00D4AA)
                            : Colors.white24,
                        size: 16,
                      ),
                  ]),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(metric.displayValue,
                        style: TextStyle(
                            color: _scoreColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(width: 8),
                    Text('Ideal: ${metric.idealRange}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ]),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: metric.isIdeal
                      ? const Color(0xFF00D4AA).withOpacity(0.15)
                      : const Color(0xFFFF6B6B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  metric.isIdeal ? '✓ Ideal' : '○ Off',
                  style: TextStyle(
                      color: metric.isIdeal
                          ? const Color(0xFF00D4AA)
                          : const Color(0xFFFF6B6B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ]),
            // Progress bar
            const SizedBox(height: 8),
            _ScoreBar(score: metric.score, color: _scoreColor),
            // Interpretation when selected
            if (isSelected) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF00D4AA).withOpacity(0.2)),
                ),
                child: Text(
                  metric.interpretation,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatefulWidget {
  final double score;
  final Color color;
  const _ScoreBar({required this.score, required this.color});

  @override
  State<_ScoreBar> createState() => _ScoreBarState();
}

class _ScoreBarState extends State<_ScoreBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _w;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _w = Tween<double>(begin: 0, end: widget.score / 10)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _w,
      builder: (_, __) => LayoutBuilder(
        builder: (_, constraints) => Stack(children: [
          Container(
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4))),
          Container(
            height: 4,
            width: constraints.maxWidth * _w.value,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [widget.color.withOpacity(0.5), widget.color]),
              borderRadius: BorderRadius.circular(4),
            ),
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
          style: TextStyle(
              color: _color, fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }
}
