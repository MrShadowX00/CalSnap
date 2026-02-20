import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:confetti/confetti.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/food_entry.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController _confetti;
  List<FoodEntry> _entries = [];
  bool _loading = true;
  int _dailyGoal = 2000;
  String _userName = '';
  bool _goalCelebrated = false;

  final _user = FirebaseAuth.instance.currentUser;
  final _today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _init();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyGoal = prefs.getInt('daily_goal') ?? 2000;
      _userName = prefs.getString('user_name') ?? '';
    });
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    if (_user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(_user!.uid)
          .collection('food_entries')
          .where('loggedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime.now().copyWith(hour: 0, minute: 0, second: 0)))
          .orderBy('loggedAt', descending: true)
          .get();
      final entries = snap.docs.map((d) => FoodEntry.fromMap(d.data(), d.id)).toList();
      setState(() { _entries = entries; _loading = false; });
      _checkGoal();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _checkGoal() {
    if (totalCalories >= _dailyGoal && !_goalCelebrated) {
      _goalCelebrated = true;
      _confetti.play();
    }
  }

  int get totalCalories => _entries.fold(0, (s, e) => s + e.calories);
  double get totalProtein => _entries.fold(0.0, (s, e) => s + e.protein);
  double get totalCarbs => _entries.fold(0.0, (s, e) => s + e.carbs);
  double get totalFat => _entries.fold(0.0, (s, e) => s + e.fat);
  double get progress => (_dailyGoal > 0 ? totalCalories / _dailyGoal : 0.0).clamp(0.0, 1.0);

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Xayrli tong ☀️';
    if (h < 17) return 'Xayrli kun 🌤️';
    return 'Xayrli kech 🌙';
  }

  Map<String, List<FoodEntry>> get _grouped {
    final map = <String, List<FoodEntry>>{};
    for (final e in _entries) {
      map.putIfAbsent(e.mealType, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.bgGradient)),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [AppTheme.neon, AppTheme.primary, AppTheme.accent, Colors.white],
              numberOfParticles: 25,
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.card,
              onRefresh: _loadEntries,
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_greeting, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.muted)),
                          Text(_userName.isNotEmpty ? _userName : 'Foydalanuvchi',
                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textColor)),
                        ]).animate().slideX(begin: -0.2, duration: 500.ms),
                        GestureDetector(
                          onTap: () => FirebaseAuth.instance.signOut(),
                          child: CircleAvatar(
                            radius: 22, backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                            child: Text(
                              _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.primary),
                            ),
                          ),
                        ).animate().slideX(begin: 0.2, duration: 500.ms),
                      ],
                    ),
                  )),

                  const SliverToBoxAdapter(child: Gap(20)),

                  // Calorie Ring
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.glassBorder),
                        boxShadow: [BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          blurRadius: 30, spreadRadius: 2,
                        )],
                      ),
                      child: Row(children: [
                        CircularPercentIndicator(
                          radius: 70,
                          lineWidth: 12,
                          percent: progress,
                          center: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('$totalCalories', style: GoogleFonts.inter(
                              fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textColor)),
                            Text('kcal', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted)),
                          ]),
                          progressColor: progress >= 1.0 ? AppTheme.accent : AppTheme.neon,
                          backgroundColor: AppTheme.surface,
                          circularStrokeCap: CircularStrokeCap.round,
                          animation: true,
                          animationDuration: 1000,
                        ),
                        const Gap(20),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(progress >= 1.0 ? '🎉 Maqsadga erishdingiz!' : '${_dailyGoal - totalCalories} kcal qoldi',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
                          const Gap(4),
                          Text('Maqsad: $_dailyGoal kcal', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted)),
                          const Gap(12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress, minHeight: 8,
                              backgroundColor: AppTheme.surface,
                              valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? AppTheme.accent : AppTheme.neon),
                            ),
                          ),
                          const Gap(8),
                          Text('${(progress * 100).toInt()}% bajarildi',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted)),
                        ])),
                      ]),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  )),

                  const SliverToBoxAdapter(child: Gap(16)),

                  // Macro Row
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(children: [
                      _MacroCard('🥩', 'Protein', '${totalProtein.toStringAsFixed(0)}g', const Color(0xFF3B82F6)),
                      const Gap(10),
                      _MacroCard('🍞', 'Uglevodlar', '${totalCarbs.toStringAsFixed(0)}g', AppTheme.accent),
                      const Gap(10),
                      _MacroCard('🧈', 'Yog\'', '${totalFat.toStringAsFixed(0)}g', const Color(0xFFEF4444)),
                    ]).animate().fadeIn(delay: 300.ms),
                  )),

                  const SliverToBoxAdapter(child: Gap(20)),

                  // Today's meals header
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Bugungi ovqatlar', style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/log'),
                        child: Text('Barchasi →', style: GoogleFonts.inter(
                          fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      ),
                    ]).animate().fadeIn(delay: 350.ms),
                  )),

                  const SliverToBoxAdapter(child: Gap(12)),

                  // Entries
                  if (_loading)
                    SliverToBoxAdapter(child: _ShimmerList())
                  else if (_entries.isEmpty)
                    SliverToBoxAdapter(child: _EmptyState(onScan: () => Navigator.pushNamed(context, '/scan')))
                  else
                    SliverList(delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
                        final type = mealTypes[i % mealTypes.length];
                        final group = _grouped[type];
                        if (group == null || group.isEmpty) return null;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: _MealGroup(mealType: type, entries: group),
                        );
                      },
                      childCount: 4,
                    )),

                  const SliverToBoxAdapter(child: Gap(100)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _MacroCard(this.emoji, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const Gap(4),
      Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.muted)),
    ]),
  ));
}

class _MealGroup extends StatelessWidget {
  final String mealType;
  final List<FoodEntry> entries;
  const _MealGroup({required this.mealType, required this.entries});

  @override
  Widget build(BuildContext context) {
    final sample = entries.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${sample.mealEmoji} ${sample.mealLabel}',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.mutedLight)),
          Text('${entries.fold(0, (s, e) => s + e.calories)} kcal',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        ]),
        const Gap(10),
        ...entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Text(e.emoji, style: const TextStyle(fontSize: 22)),
            const Gap(10),
            Expanded(child: Text(e.name, style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textColor))),
            Text('${e.calories} kcal', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.muted)),
          ]),
        )),
      ]),
    );
  }
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptyState({required this.onScan});

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(children: [
      const Text('📸', style: TextStyle(fontSize: 60)).animate().scale(curve: Curves.elasticOut),
      const Gap(16),
      Text('Hali ovqat qo\'shilmagan', style: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
      const Gap(8),
      Text('Kamera tugmasini bosib birinchi ovqatingizni skanerlang!',
        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.muted), textAlign: TextAlign.center),
      const Gap(24),
      GestureDetector(
        onTap: onScan,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Text('📸 Skanerlash', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ),
    ]),
  ));
}
