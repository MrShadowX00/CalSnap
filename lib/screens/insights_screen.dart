import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';
import '../services/insights_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  DailyStats?   _today;
  MonthlyStats? _month;
  List<Insight> _insights = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today   = await InsightsService.getTodayStats();
    final month   = await InsightsService.getMonthlyStats();
    final insights = InsightsService.generateInsights(today, month);
    if (mounted) setState(() {
      _today = today; _month = month;
      _insights = insights; _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : CustomScrollView(slivers: [
                // Header
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textColor, size: 20),
                    ),
                    const Gap(12),
                    Text('Tahlil', style: GoogleFonts.inter(
                      fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textColor)),
                  ]).animate().fadeIn(),
                )),

                const SliverToBoxAdapter(child: Gap(20)),

                // Today summary
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _TodaySummary(stats: _today!),
                ).animate().fadeIn(delay: 100.ms)),

                const SliverToBoxAdapter(child: Gap(16)),

                // Smart Insights
                if (_insights.isNotEmpty) ...[
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('🧠 Bugungi Tavsiyalar', style: GoogleFonts.inter(
                      fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
                  ).animate().fadeIn(delay: 150.ms)),
                  const SliverToBoxAdapter(child: Gap(10)),
                  SliverList(delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                      child: _InsightCard(insight: _insights[i])
                          .animate().slideX(begin: 0.2, delay: Duration(milliseconds: 200 + i * 100), duration: 350.ms),
                    ),
                    childCount: _insights.length,
                  )),
                ],

                const SliverToBoxAdapter(child: Gap(16)),

                // Monthly overview
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('📅 30 kunlik statistika', style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
                ).animate().fadeIn(delay: 300.ms)),
                const SliverToBoxAdapter(child: Gap(12)),

                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _MonthlyOverview(stats: _month!),
                ).animate().fadeIn(delay: 350.ms)),

                const SliverToBoxAdapter(child: Gap(16)),

                // 30-day calorie chart
                if (_month!.dailyCalories.isNotEmpty)
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _CalorieChart(data: _month!.dailyCalories, goal: _month!.goalCalories),
                  ).animate().fadeIn(delay: 450.ms)),

                const SliverToBoxAdapter(child: Gap(16)),

                // Macro breakdown
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _MacroBreakdown(stats: _month!),
                ).animate().fadeIn(delay: 500.ms)),

                // Day breakdown
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: _DayBreakdown(stats: _month!),
                ).animate().fadeIn(delay: 550.ms)),

                const SliverToBoxAdapter(child: Gap(100)),
              ]),
        ),
      ),
    );
  }
}

// ── Today Summary ────────────────────────────────────────────────
class _TodaySummary extends StatelessWidget {
  final DailyStats stats;
  const _TodaySummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.glassBorder),
        boxShadow: [BoxShadow(
          color: AppTheme.primary.withValues(alpha: 0.12),
          blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Bugun', style: GoogleFonts.inter(
          fontSize: 13, color: AppTheme.muted, fontWeight: FontWeight.w600)),
        const Gap(12),
        Row(children: [
          Expanded(child: _ring(
            stats.calProgress.clamp(0.0, 1.0),
            '${stats.calories}',
            'kcal',
            stats.isCalOver ? AppTheme.danger : stats.isCalUnder ? AppTheme.warning : AppTheme.neon,
          )),
          const Gap(16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _row('🔥', 'Kaloriya', '${stats.calories} / ${stats.goal}',
              stats.isCalOver ? AppTheme.danger : stats.isCalUnder ? AppTheme.warning : AppTheme.success),
            const Gap(8),
            _row('💧', 'Suv', '${(stats.waterMl / 1000).toStringAsFixed(1)}L / ${(stats.waterGoal / 1000).toStringAsFixed(1)}L',
              stats.isWaterLow ? AppTheme.warning : const Color(0xFF0EA5E9)),
            const Gap(8),
            _row('🥩', 'Protein', '${stats.protein.toStringAsFixed(0)}g',
              const Color(0xFF3B82F6)),
          ])),
        ]),
        const Gap(12),
        _statusBanner(stats),
      ]),
    );
  }

  Widget _ring(double p, String val, String label, Color color) => Column(children: [
    CircularPercentIndicator(
      radius: 46, lineWidth: 8, percent: p,
      progressColor: color,
      backgroundColor: AppTheme.surface,
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      center: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(val, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textColor)),
        Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.muted)),
      ]),
    ),
  ]);

  Widget _row(String emoji, String label, String val, Color color) =>
    Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const Gap(6),
      Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted)),
      const Spacer(),
      Text(val, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]);

  Widget _statusBanner(DailyStats s) {
    String msg; Color color; String emoji;
    if (s.isCalOver) {
      msg = 'Me\'yordan oshib ketdi'; color = AppTheme.danger; emoji = '⚠️';
    } else if (s.isCalUnder && s.calories > 0) {
      msg = 'Kam kaloriya'; color = AppTheme.warning; emoji = '📉';
    } else if (s.calories == 0) {
      msg = 'Hali ovqat qo\'shilmagan'; color = AppTheme.muted; emoji = '📸';
    } else {
      msg = 'Kun muvozanatda — ajoyib!'; color = AppTheme.success; emoji = '✅';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const Gap(8),
        Text(msg, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

// ── Monthly Overview ─────────────────────────────────────────────
class _MonthlyOverview extends StatelessWidget {
  final MonthlyStats stats;
  const _MonthlyOverview({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: _StatBox('📅', '${stats.daysLogged}', 'Kun kuzatildi', AppTheme.primary)),
        const Gap(10),
        Expanded(child: _StatBox('✅', '${stats.daysOnTarget}', 'Me\'yorda', AppTheme.success)),
        const Gap(10),
        Expanded(child: _StatBox('⬆️', '${stats.daysOverGoal}', 'Oshib ketgan', AppTheme.danger)),
        const Gap(10),
        Expanded(child: _StatBox('⬇️', '${stats.daysUnderGoal}', 'Kam iste\'mol', AppTheme.warning)),
      ]),
      const Gap(12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(children: [
          Expanded(child: Column(children: [
            Text('${stats.avgCalories}', style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textColor)),
            Text('O\'rtacha kcal/kun', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted)),
          ])),
          Container(width: 1, height: 40, color: AppTheme.cardBorder),
          Expanded(child: Column(children: [
            Text('${(stats.calAccuracy * 100).toInt()}%', style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.w900,
              color: stats.calAccuracy >= 0.7 ? AppTheme.success : AppTheme.warning)),
            Text('Aniqlik darajasi', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted)),
          ])),
          Container(width: 1, height: 40, color: AppTheme.cardBorder),
          Expanded(child: Column(children: [
            Text('${stats.goalCalories}', style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary)),
            Text('Maqsad kcal', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted)),
          ])),
        ]),
      ),
    ]);
  }
}

class _StatBox extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _StatBox(this.emoji, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const Gap(2),
      Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.muted), textAlign: TextAlign.center),
    ]),
  );
}

// ── 30-Day Calorie Chart ─────────────────────────────────────────
class _CalorieChart extends StatelessWidget {
  final List<int> data;
  final int goal;
  const _CalorieChart({required this.data, required this.goal});

  @override
  Widget build(BuildContext context) {
    final maxY = (data.reduce((a, b) => a > b ? a : b) * 1.2)
        .clamp(goal * 1.5, goal * 2.0).toDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📈 30 kunlik kaloriya', style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
        const Gap(12),
        Expanded(child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.cardBorder, strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              // Actual calories
              LineChartBarData(
                spots: data.asMap().entries
                    .where((e) => e.value > 0)
                    .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                    .toList(),
                isCurved: true,
                color: AppTheme.primary,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.primary.withValues(alpha: 0.1),
                ),
              ),
              // Goal line
              LineChartBarData(
                spots: List.generate(30, (i) => FlSpot(i.toDouble(), goal.toDouble())),
                isCurved: false,
                color: AppTheme.accent.withValues(alpha: 0.6),
                barWidth: 1.5,
                dotData: const FlDotData(show: false),
                dashArray: [6, 4],
              ),
            ],
          ),
        )),
        const Gap(8),
        Row(children: [
          _legend(AppTheme.primary, 'Iste\'mol qilingan'),
          const Gap(16),
          _legend(AppTheme.accent, 'Maqsad'),
        ]),
      ]),
    );
  }

  Widget _legend(Color c, String label) => Row(children: [
    Container(width: 12, height: 3, color: c),
    const Gap(4),
    Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.muted)),
  ]);
}

// ── Macro Breakdown ──────────────────────────────────────────────
class _MacroBreakdown extends StatelessWidget {
  final MonthlyStats stats;
  const _MacroBreakdown({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.daysLogged == 0) return const SizedBox.shrink();
    final total = stats.avgProtein + stats.avgCarbs + stats.avgFat;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('🥗 O\'rtacha makrolar (kunlik)', style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
        const Gap(14),
        _bar('🥩 Protein', stats.avgProtein, total, const Color(0xFF3B82F6)),
        const Gap(8),
        _bar('🍞 Uglevodlar', stats.avgCarbs, total, AppTheme.accent),
        const Gap(8),
        _bar('🧈 Yog\'', stats.avgFat, total, const Color(0xFFEF4444)),
      ]),
    );
  }

  Widget _bar(String label, double val, double total, Color color) {
    final pct = (val / total).clamp(0.0, 1.0);
    return Row(children: [
      SizedBox(width: 110, child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedLight))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: pct, minHeight: 10,
          backgroundColor: AppTheme.surface,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      )),
      const Gap(8),
      SizedBox(width: 40, child: Text('${val.toStringAsFixed(0)}g',
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color),
        textAlign: TextAlign.right)),
    ]);
  }
}

// ── Day Breakdown ─────────────────────────────────────────────────
class _DayBreakdown extends StatelessWidget {
  final MonthlyStats stats;
  const _DayBreakdown({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.daysLogged == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📊 Kunlar tahlili (30 kun)', style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
        const Gap(14),
        _pie(stats),
        const Gap(14),
        _recommend(stats),
      ]),
    );
  }

  Widget _pie(MonthlyStats s) {
    final on    = s.daysOnTarget;
    final over  = s.daysOverGoal;
    final under = s.daysUnderGoal;
    final rest  = 30 - s.daysLogged;

    return Row(children: [
      SizedBox(
        width: 100, height: 100,
        child: PieChart(PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 30,
          sections: [
            if (on > 0)    _section(on.toDouble(),    AppTheme.success, ''),
            if (over > 0)  _section(over.toDouble(),  AppTheme.danger,  ''),
            if (under > 0) _section(under.toDouble(), AppTheme.warning, ''),
            if (rest > 0)  _section(rest.toDouble(),  AppTheme.surface, ''),
          ],
        )),
      ),
      const Gap(16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _legend(AppTheme.success, 'Me\'yorda: $on kun'),
        const Gap(6),
        _legend(AppTheme.danger,  'Oshib ketgan: $over kun'),
        const Gap(6),
        _legend(AppTheme.warning, 'Kam iste\'mol: $under kun'),
        if (rest > 0) ...[
          const Gap(6),
          _legend(AppTheme.muted, 'Qo\'shilmagan: $rest kun'),
        ],
      ]),
    ]);
  }

  PieChartSectionData _section(double val, Color color, String title) =>
    PieChartSectionData(value: val, color: color, title: title, radius: 20);

  Widget _legend(Color c, String label) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(
      color: c, borderRadius: BorderRadius.circular(3))),
    const Gap(6),
    Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.mutedLight)),
  ]);

  Widget _recommend(MonthlyStats s) {
    String msg;
    if (s.calAccuracy >= 0.7) {
      msg = '🏆 Zo\'r natija! ${(s.calAccuracy * 100).toInt()}% kunlarda maqsad doirasida bo\'ldingiz.';
    } else if (s.daysOverGoal > s.daysUnderGoal) {
      msg = '💡 Ko\'proq porsiyalarni kamaytiring. Tushlik va kechki ovqat kaloriyas katta ta\'sir ko\'rsatadi.';
    } else if (s.daysUnderGoal > s.daysOnTarget) {
      msg = '⚡ Energiya yetishmasligi kuzatilmoqda. Kuniga 3-4 marta ovqatlaning, proteinni ko\'paytiring.';
    } else {
      msg = '📈 Kuzatishni davom eting. Ko\'proq ma\'lumot to\'plangach chuqur tahlil beraman.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Text(msg, style: GoogleFonts.inter(
        fontSize: 13, color: AppTheme.mutedLight, height: 1.5)),
    );
  }
}

// ── Insight Card ─────────────────────────────────────────────────
class _InsightCard extends StatelessWidget {
  final Insight insight;
  const _InsightCard({required this.insight});

  Color get _bg => switch (insight.type) {
    InsightType.success => const Color(0xFF10B981).withValues(alpha: 0.12),
    InsightType.warning => const Color(0xFFF59E0B).withValues(alpha: 0.12),
    InsightType.danger  => const Color(0xFFEF4444).withValues(alpha: 0.12),
    InsightType.info    => const Color(0xFF3B82F6).withValues(alpha: 0.12),
  };

  Color get _border => switch (insight.type) {
    InsightType.success => const Color(0xFF10B981).withValues(alpha: 0.4),
    InsightType.warning => const Color(0xFFF59E0B).withValues(alpha: 0.4),
    InsightType.danger  => const Color(0xFFEF4444).withValues(alpha: 0.4),
    InsightType.info    => const Color(0xFF3B82F6).withValues(alpha: 0.4),
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _bg, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(insight.emoji, style: const TextStyle(fontSize: 26)),
      const Gap(12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(insight.title, style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
        const Gap(4),
        Text(insight.body, style: GoogleFonts.inter(
          fontSize: 12, color: AppTheme.mutedLight, height: 1.5)),
      ])),
    ]),
  );
}
