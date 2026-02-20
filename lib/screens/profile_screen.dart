import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../services/revenue_cat_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  UserProfile? _profile;
  bool _loading = true;
  bool _isPro = false;
  int _totalFoods = 0;
  int _streak = 0;

  // Edit controllers
  final _nameCtrl   = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl    = TextEditingController();
  String _goal = 'maintain';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _weightCtrl.dispose();
    _heightCtrl.dispose(); _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isPro = RevenueCatService.isPro;
    final name   = prefs.getString('user_name') ?? '';
    final weight = prefs.getDouble('weight') ?? 70;
    final height = prefs.getDouble('height') ?? 170;
    final goal   = prefs.getString('user_goal') ?? 'maintain';
    final dailyGoal = prefs.getInt('daily_goal') ?? 2000;

    _nameCtrl.text   = name;
    _weightCtrl.text = weight.toStringAsFixed(0);
    _heightCtrl.text = height.toStringAsFixed(0);
    _ageCtrl.text    = '25';
    _goal = goal;

    final profile = UserProfile(
      uid: _user?.uid ?? '',
      name: name, weight: weight, height: height,
      goal: goal, dailyCalorieGoal: dailyGoal,
    );

    // Load stats
    int total = 0;
    if (_user != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users').doc(_user!.uid)
            .collection('food_entries').get();
        total = snap.docs.length;
      } catch (_) {}
    }

    setState(() {
      _profile = profile;
      _isPro = isPro;
      _totalFoods = total;
      _streak = 3; // Simplified — real streak tracking to be added
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final w = double.tryParse(_weightCtrl.text) ?? 70;
    final h = double.tryParse(_heightCtrl.text) ?? 170;
    final a = int.tryParse(_ageCtrl.text) ?? 25;
    final goal = UserProfile.calculateBMR(weight: w, height: h, age: a, goal: _goal);

    await prefs.setString('user_name', _nameCtrl.text.trim());
    await prefs.setDouble('weight', w);
    await prefs.setDouble('height', h);
    await prefs.setString('user_goal', _goal);
    await prefs.setInt('daily_goal', goal);

    setState(() {
      _profile = UserProfile(
        uid: _user?.uid ?? '',
        name: _nameCtrl.text.trim(),
        weight: w, height: h, age: a,
        goal: _goal, dailyCalorieGoal: goal,
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Saqlandi!'), backgroundColor: AppTheme.success));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _profile == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final p = _profile!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Text('Profil', style: GoogleFonts.inter(
                fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textColor))
                  .animate().fadeIn(),

              const Gap(24),

              // Avatar + info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Row(children: [
                  // Avatar
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: Center(child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
                    )),
                  ),
                  const Gap(16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(p.name.isNotEmpty ? p.name : 'Foydalanuvchi',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                      if (_isPro) ...[
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10)),
                          child: Text('PRO', style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ],
                    ]),
                    Text(_user?.email ?? '', style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                    const Gap(8),
                    Text('BMI: ${p.bmi.toStringAsFixed(1)} · ${p.bmiLabel}',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                  ])),
                ]),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

              const Gap(16),

              // Stats row
              Row(children: [
                _StatCard('🔥', '$_streak', 'Streak'),
                const Gap(10),
                _StatCard('🍽️', '$_totalFoods', 'Skanerlangan'),
                const Gap(10),
                _StatCard('🎯', '${p.dailyCalorieGoal}', 'Kcal maqsad'),
              ]).animate().fadeIn(delay: 200.ms),

              const Gap(20),

              // Pro banner (if not pro)
              if (!_isPro) GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/pro'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.4),
                      blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Row(children: [
                    const Text('👑', style: TextStyle(fontSize: 28)),
                    const Gap(14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('CalSnap Pro\'ga o\'ting', style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('Cheksiz scan · AI chat · Reklamasiz',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                    ])),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ]),
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),
              ),

              if (!_isPro) const Gap(20),

              // Edit profile section
              Text('Ma\'lumotlarni tahrirlash', style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textColor))
                  .animate().fadeIn(delay: 300.ms),
              const Gap(12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(children: [
                  _field('Ism', _nameCtrl, 'Ismingiz'),
                  const Gap(12),
                  Row(children: [
                    Expanded(child: _field('Vazn (kg)', _weightCtrl, '70', isNum: true)),
                    const Gap(12),
                    Expanded(child: _field('Bo\'y (cm)', _heightCtrl, '170', isNum: true)),
                  ]),
                  const Gap(12),
                  _field('Yosh', _ageCtrl, '25', isNum: true),
                  const Gap(16),
                  Text('Maqsad', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.muted, fontWeight: FontWeight.w600)),
                  const Gap(10),
                  Row(children: [
                    _goalChip('lose', '🔥 Ozish'),
                    const Gap(8),
                    _goalChip('maintain', '⚖️ Saqlash'),
                    const Gap(8),
                    _goalChip('gain', '💪 Olish'),
                  ]),
                  const Gap(20),
                  GestureDetector(
                    onTap: _save,
                    child: Container(
                      width: double.infinity, height: 52,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.4),
                          blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Center(child: Text('✅ Saqlash',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
                    ),
                  ),
                ]),
              ).animate().fadeIn(delay: 350.ms),

              const Gap(20),

              // Sign out
              GestureDetector(
                onTap: () => FirebaseAuth.instance.signOut(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                  ),
                  child: Center(child: Text('🚪 Chiqish',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.danger))),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const Gap(100),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {bool isNum = false}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w600)),
      const Gap(6),
      TextField(
        controller: ctrl,
        style: GoogleFonts.inter(color: AppTheme.textColor),
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(hintText: hint),
      ),
    ]);

  Widget _goalChip(String value, String label) => Expanded(child: GestureDetector(
    onTap: () => setState(() => _goal = value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _goal == value ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _goal == value ? AppTheme.primary : AppTheme.cardBorder),
      ),
      child: Center(child: Text(label, style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: _goal == value ? AppTheme.primary : AppTheme.muted))),
    ),
  ));
}

class _StatCard extends StatelessWidget {
  final String emoji, value, label;
  const _StatCard(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.cardBorder),
    ),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const Gap(4),
      Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary)),
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.muted)),
    ]),
  ));
}
