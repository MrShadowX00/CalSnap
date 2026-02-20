import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../theme/app_theme.dart';
import '../services/insights_service.dart';

class InsightsWidget extends StatefulWidget {
  const InsightsWidget({super.key});
  @override
  State<InsightsWidget> createState() => _InsightsWidgetState();
}

class _InsightsWidgetState extends State<InsightsWidget> {
  List<Insight> _insights = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = await InsightsService.getTodayStats();
    final month = await InsightsService.getMonthlyStats();
    final insights = InsightsService.generateInsights(today, month);
    if (mounted) setState(() { _insights = insights; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_insights.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('🧠 Smart Tavsiyalar', style: GoogleFonts.inter(
          fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/insights'),
          child: Text('Batafsil →', style: GoogleFonts.inter(
            fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
        ),
      ]),
      const Gap(12),
      ..._insights.asMap().entries.map((e) =>
        _InsightCard(insight: e.value, index: e.key)
            .animate()
            .slideX(begin: 0.2, delay: Duration(milliseconds: e.key * 100), duration: 350.ms, curve: Curves.easeOut)
            .fadeIn(delay: Duration(milliseconds: e.key * 100)),
      ),
    ]);
  }
}

class _InsightCard extends StatelessWidget {
  final Insight insight;
  final int index;
  const _InsightCard({required this.insight, required this.index});

  Color get _bgColor {
    switch (insight.type) {
      case InsightType.success: return const Color(0xFF10B981).withValues(alpha: 0.12);
      case InsightType.warning: return const Color(0xFFF59E0B).withValues(alpha: 0.12);
      case InsightType.danger:  return const Color(0xFFEF4444).withValues(alpha: 0.12);
      case InsightType.info:    return const Color(0xFF3B82F6).withValues(alpha: 0.12);
    }
  }

  Color get _borderColor {
    switch (insight.type) {
      case InsightType.success: return const Color(0xFF10B981).withValues(alpha: 0.4);
      case InsightType.warning: return const Color(0xFFF59E0B).withValues(alpha: 0.4);
      case InsightType.danger:  return const Color(0xFFEF4444).withValues(alpha: 0.4);
      case InsightType.info:    return const Color(0xFF3B82F6).withValues(alpha: 0.4);
    }
  }

  Color get _accentColor {
    switch (insight.type) {
      case InsightType.success: return const Color(0xFF10B981);
      case InsightType.warning: return const Color(0xFFF59E0B);
      case InsightType.danger:  return const Color(0xFFEF4444);
      case InsightType.info:    return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(insight.emoji, style: const TextStyle(fontSize: 26)),
        const Gap(12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(insight.title, style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
          const Gap(4),
          Text(insight.body, style: GoogleFonts.inter(
            fontSize: 12, color: AppTheme.mutedLight, height: 1.5)),
          if (insight.action != null) ...[
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _accentColor.withValues(alpha: 0.4)),
              ),
              child: Text(insight.action!, style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700, color: _accentColor)),
            ),
          ],
        ])),
      ]),
    );
  }
}
