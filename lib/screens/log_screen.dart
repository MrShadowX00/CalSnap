import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../models/food_entry.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});
  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  DateTime _selectedDate = DateTime.now();
  List<FoodEntry> _entries = [];
  bool _loading = true;

  // 28-day completion data for heatmap (0.0–1.0)
  final Map<String, double> _heatmapData = {};

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _loadHeatmap();
  }

  Future<void> _loadEntries() async {
    if (_user == null) return;
    setState(() => _loading = true);
    try {
      final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final end = start.add(const Duration(days: 1));
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(_user!.uid)
          .collection('food_entries')
          .where('loggedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('loggedAt', isLessThan: Timestamp.fromDate(end))
          .orderBy('loggedAt', descending: false)
          .get();
      setState(() {
        _entries = snap.docs.map((d) => FoodEntry.fromMap(d.data(), d.id)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadHeatmap() async {
    if (_user == null) return;
    try {
      final since = DateTime.now().subtract(const Duration(days: 28));
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(_user!.uid)
          .collection('food_entries')
          .where('loggedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .get();

      final dayMap = <String, int>{};
      for (final doc in snap.docs) {
        final entry = FoodEntry.fromMap(doc.data(), doc.id);
        final key = DateFormat('yyyy-MM-dd').format(entry.loggedAt);
        dayMap[key] = (dayMap[key] ?? 0) + entry.calories;
      }

      setState(() {
        _heatmapData.clear();
        dayMap.forEach((k, v) => _heatmapData[k] = (v / 2000).clamp(0.0, 1.0));
      });
    } catch (_) {}
  }

  Future<void> _deleteEntry(FoodEntry entry) async {
    if (_user == null) return;
    await FirebaseFirestore.instance
        .collection('users').doc(_user!.uid)
        .collection('food_entries').doc(entry.id)
        .delete();
    setState(() => _entries.remove(entry));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${entry.name} o\'chirildi'),
        backgroundColor: AppTheme.danger,
        action: SnackBarAction(
          label: 'Bekor',
          textColor: Colors.white,
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('users').doc(_user!.uid)
                .collection('food_entries').doc(entry.id)
                .set(entry.toMap());
            setState(() => _entries.add(entry));
          },
        ),
      ));
    }
  }

  int get _totalCalories => _entries.fold(0, (s, e) => s + e.calories);
  double get _totalProtein => _entries.fold(0.0, (s, e) => s + e.protein);
  double get _totalCarbs => _entries.fold(0.0, (s, e) => s + e.carbs);
  double get _totalFat => _entries.fold(0.0, (s, e) => s + e.fat);

  Map<String, List<FoodEntry>> get _grouped {
    final order = ['breakfast', 'lunch', 'dinner', 'snack'];
    final map = <String, List<FoodEntry>>{};
    for (final type in order) {
      final list = _entries.where((e) => e.mealType == type).toList();
      if (list.isNotEmpty) map[type] = list;
    }
    return map;
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text('Ovqat Tarixi', style: GoogleFonts.inter(
                  fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textColor))
                    .animate().fadeIn(),
              )),

              const SliverToBoxAdapter(child: Gap(16)),

              // Date selector
              SliverToBoxAdapter(child: SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 14,
                  itemBuilder: (_, i) {
                    final date = DateTime.now().subtract(Duration(days: 13 - i));
                    final isSelected = date.day == _selectedDate.day &&
                        date.month == _selectedDate.month;
                    final dayKey = DateFormat('yyyy-MM-dd').format(date);
                    final hasData = _heatmapData.containsKey(dayKey);

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedDate = date);
                        _loadEntries();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        width: 52,
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppTheme.primaryGradient : null,
                          color: isSelected ? null : AppTheme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                            width: isSelected ? 0 : 1,
                          ),
                          boxShadow: isSelected ? [BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 10, offset: const Offset(0, 4),
                          )] : null,
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(DateFormat('E').format(date).substring(0, 2),
                            style: GoogleFonts.inter(fontSize: 11,
                              color: isSelected ? Colors.white : AppTheme.muted,
                              fontWeight: FontWeight.w600)),
                          const Gap(2),
                          Text('${date.day}', style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : AppTheme.textColor)),
                          if (hasData && !isSelected)
                            Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 2),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary)),
                        ]),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 100.ms),
              )),

              const SliverToBoxAdapter(child: Gap(16)),

              // Daily summary
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Row(children: [
                    Expanded(child: _SumTile('🔥', 'Kaloriya', '$_totalCalories kcal', AppTheme.neon)),
                    _divider(),
                    Expanded(child: _SumTile('🥩', 'Protein', '${_totalProtein.toStringAsFixed(0)}g', const Color(0xFF3B82F6))),
                    _divider(),
                    Expanded(child: _SumTile('🍞', 'Uglevodlar', '${_totalCarbs.toStringAsFixed(0)}g', AppTheme.accent)),
                    _divider(),
                    Expanded(child: _SumTile('🧈', 'Yog\'', '${_totalFat.toStringAsFixed(0)}g', const Color(0xFFEF4444))),
                  ]),
                ).animate().fadeIn(delay: 200.ms),
              )),

              const SliverToBoxAdapter(child: Gap(16)),

              // Entries
              if (_loading)
                SliverToBoxAdapter(child: _ShimmerList())
              else if (_entries.isEmpty)
                SliverToBoxAdapter(child: _EmptyDay(isToday: _isToday,
                  onScan: () => Navigator.pushNamed(context, '/scan')))
              else
                SliverList(delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final groups = _grouped.entries.toList();
                    if (i >= groups.length) return null;
                    final group = groups[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: _MealGroup(
                        mealType: group.key,
                        entries: group.value,
                        onDelete: _deleteEntry,
                      ).animate().slideX(begin: 0.2, delay: Duration(milliseconds: i * 80), duration: 350.ms, curve: Curves.easeOut),
                    );
                  },
                  childCount: _grouped.length,
                )),

              const SliverToBoxAdapter(child: Gap(20)),

              // 28-day heatmap
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _Heatmap(data: _heatmapData).animate().fadeIn(delay: 400.ms),
              )),

              const SliverToBoxAdapter(child: Gap(100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: AppTheme.cardBorder,
    margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _SumTile extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _SumTile(this.emoji, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 18)),
    const Gap(2),
    Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.muted)),
  ]);
}

class _MealGroup extends StatelessWidget {
  final String mealType;
  final List<FoodEntry> entries;
  final Function(FoodEntry) onDelete;
  const _MealGroup({required this.mealType, required this.entries, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final sample = entries.first;
    final total = entries.fold(0, (s, e) => s + e.calories);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${sample.mealEmoji} ${sample.mealLabel}',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.mutedLight)),
            Text('$total kcal', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ]),
        ),
        const Divider(color: AppTheme.cardBorder, height: 1),
        ...entries.map((e) => Dismissible(
          key: Key(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: AppTheme.danger.withValues(alpha: 0.2),
            child: const Icon(Icons.delete_outline, color: AppTheme.danger),
          ),
          onDismissed: (_) => onDelete(e),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(e.emoji, style: const TextStyle(fontSize: 20)))),
              const Gap(12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.name, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                Text('${e.protein.toStringAsFixed(0)}g protein · ${e.carbs.toStringAsFixed(0)}g ugl · ${e.fat.toStringAsFixed(0)}g yog\'',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted)),
              ])),
              Text('${e.calories} kcal', style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
            ]),
          ),
        )),
      ]),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final Map<String, double> data;
  const _Heatmap({required this.data});

  @override
  Widget build(BuildContext context) {
    final days = List.generate(28, (i) =>
        DateTime.now().subtract(Duration(days: 27 - i)));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📅 So\'ngi 28 kun', style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
        const Gap(16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'].map((d) =>
            SizedBox(width: 34, child: Text(d, textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted)))).toList()),
        const Gap(8),
        ...List.generate(4, (row) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (col) {
              final idx = row * 7 + col;
              if (idx >= days.length) return const SizedBox(width: 34, height: 34);
              final key = DateFormat('yyyy-MM-dd').format(days[idx]);
              final val = data[key] ?? 0.0;
              return Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: val == 0 ? AppTheme.surface : AppTheme.neon.withValues(alpha: val * 0.9),
                ),
                child: val >= 0.9 ? const Center(child: Text('✓',
                  style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w900))) : null,
              );
            }),
          ),
        )),
        const Gap(8),
        Row(children: [
          _legend(AppTheme.surface, '0%'),
          const Gap(12),
          _legend(AppTheme.neon.withValues(alpha: 0.4), '50%'),
          const Gap(12),
          _legend(AppTheme.neon, '100%'),
        ]),
      ]),
    );
  }

  Widget _legend(Color color, String label) => Row(children: [
    Container(width: 14, height: 14, decoration: BoxDecoration(
      color: color, borderRadius: BorderRadius.circular(4))),
    const Gap(4),
    Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted)),
  ]);
}

class _EmptyDay extends StatelessWidget {
  final bool isToday;
  final VoidCallback onScan;
  const _EmptyDay({required this.isToday, required this.onScan});

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(isToday ? '📸' : '📭', style: const TextStyle(fontSize: 56))
          .animate().scale(curve: Curves.elasticOut),
      const Gap(16),
      Text(isToday ? 'Bugun hali ovqat yo\'q' : 'Bu kunda ovqat yo\'q',
        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
      const Gap(8),
      Text(isToday ? 'Kamera tugmasini bosib skanerlang!' : 'O\'sha kuni ovqat qo\'shilmagan.',
        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.muted), textAlign: TextAlign.center),
      if (isToday) ...[
        const Gap(20),
        GestureDetector(
          onTap: onScan,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
            child: Text('📸 Skanerlash', style: GoogleFonts.inter(
              fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      ],
    ]),
  ));
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Shimmer.fromColors(
      baseColor: AppTheme.card, highlightColor: AppTheme.surface,
      child: Column(children: List.generate(3, (_) => Container(
        margin: const EdgeInsets.only(bottom: 10), height: 80,
        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(18)),
      ))),
    ),
  );
}
