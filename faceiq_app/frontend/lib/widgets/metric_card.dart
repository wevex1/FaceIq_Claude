// widgets/metric_card.dart
import 'package:flutter/material.dart';
import '../models/analysis_result.dart';

class MetricCard extends StatelessWidget {
  final RatioMetric metric;
  final bool expanded;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.metric,
    this.expanded = false,
    this.onTap,
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _scoreColor.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Score badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _scoreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _scoreColor.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      metric.score.toStringAsFixed(1),
                      style: TextStyle(
                        color: _scoreColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name & value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            metric.displayValue,
                            style: TextStyle(
                              color: _scoreColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ideal: ${metric.idealRange}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Ideal indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            // Progress bar
            const SizedBox(height: 10),
            _ScoreBar(score: metric.score, color: _scoreColor),
            // Interpretation (if expanded)
            if (expanded) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  metric.interpretation,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.5,
                  ),
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
        builder: (_, constraints) => Stack(
          children: [
            // Track
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Fill
            Container(
              height: 4,
              width: constraints.maxWidth * _w.value,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [widget.color.withOpacity(0.5), widget.color]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expandable category section with all its metrics
class CategorySection extends StatefulWidget {
  final CategoryResult category;

  const CategorySection({super.key, required this.category});

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  bool _open = true;
  int? _expandedIndex;

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
        // Header row
        GestureDetector(
          onTap: () => setState(() => _open = !_open),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF111622),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Category icon dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _avgColor(avg),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: _avgColor(avg).withOpacity(0.6), blurRadius: 6)
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.category.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Avg badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _avgColor(avg).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _avgColor(avg).withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    '${avg.toStringAsFixed(1)}/10',
                    style: TextStyle(
                      color: _avgColor(avg),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white38,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          ...widget.category.metrics.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return MetricCard(
              metric: m,
              expanded: _expandedIndex == i,
              onTap: () =>
                  setState(() => _expandedIndex = _expandedIndex == i ? null : i),
            );
          }),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
