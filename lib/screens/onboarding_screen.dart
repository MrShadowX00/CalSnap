import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // Page 2 inputs
  final _nameCtrl   = TextEditingController();
  final _ageCtrl    = TextEditingController(text: '25');
  final _weightCtrl = TextEditingController(text: '70');
  final _heightCtrl = TextEditingController(text: '170');
  String _goal = 'maintain';
  int _dailyGoal = 2000;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _recalcGoal() {
    final w = double.tryParse(_weightCtrl.text) ?? 70;
    final h = double.tryParse(_heightCtrl.text) ?? 170;
    final a = int.tryParse(_ageCtrl.text) ?? 25;
    setState(() {
      _dailyGoal = UserProfile.calculateBMR(weight: w, height: h, age: a, goal: _goal);
    });
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await prefs.setString('user_name', _nameCtrl.text.trim());
    await prefs.setInt('daily_goal', _dailyGoal);
    await prefs.setString('user_goal', _goal);
    await prefs.setDouble('weight', double.tryParse(_weightCtrl.text) ?? 70);
    await prefs.setDouble('height', double.tryParse(_heightCtrl.text) ?? 170);
    if (mounted) Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [_Page1(), _Page2(), _Page3()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageCtrl,
                      count: 3,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppTheme.primary,
                        dotColor: AppTheme.cardBorder,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                      ),
                    ),
                    const Gap(24),
                    GestureDetector(
                      onTap: () {
                        if (_page < 2) {
                          if (_page == 1) _recalcGoal();
                          _pageCtrl.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finish();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _page < 2 ? 'Davom etish →' : '🚀  Boshlash',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _Page1() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('📸', style: const TextStyle(fontSize: 80))
            .animate().scale(duration: 700.ms, curve: Curves.elasticOut),
        const Gap(32),
        Text('CalSnap\'ga xush kelibsiz',
          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textColor),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
        const Gap(16),
        Text('Ovqatingizni surating — kaloriyani AI hisoblab beradi.\nSon-sanoqsiz ma\'lumotlar bazasisiz.',
          style: GoogleFonts.inter(fontSize: 16, color: AppTheme.muted, height: 1.6),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 500.ms),
        const Gap(40),
        ...[
          ['📸', 'Rasmga oling', 'Istalgan ovqatni surating'],
          ['🤖', 'AI tahlil qiladi', 'Gemini Vision bir zumda aniqlaydi'],
          ['📊', 'Kuzating', 'Kunlik maqsadingizga erishis'],
        ].asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(e.value[0], style: const TextStyle(fontSize: 28)),
              const Gap(16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.value[1], style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                Text(e.value[2], style: GoogleFonts.inter(fontSize: 13, color: AppTheme.muted)),
              ]),
            ],
          ).animate().fadeIn(delay: Duration(milliseconds: 600 + e.key * 150)).slideX(begin: 0.2),
        )),
      ],
    ),
  );

  Widget _Page2() => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(20),
        Text('Profilingiz', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textColor))
            .animate().fadeIn(),
        const Gap(8),
        Text('Shaxsiy kaloriya maqsadingizni hisoblaymiz',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.muted))
            .animate().fadeIn(delay: 100.ms),
        const Gap(28),
        _label('Ismingiz'),
        const Gap(8),
        TextField(
          controller: _nameCtrl,
          style: GoogleFonts.inter(color: AppTheme.textColor),
          decoration: const InputDecoration(hintText: 'Isming nima?'),
        ),
        const Gap(16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Yosh'),
            const Gap(8),
            TextField(controller: _ageCtrl, keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: AppTheme.textColor),
              decoration: const InputDecoration(hintText: '25'),
              onChanged: (_) => _recalcGoal(),
            ),
          ])),
          const Gap(12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Vazn (kg)'),
            const Gap(8),
            TextField(controller: _weightCtrl, keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: AppTheme.textColor),
              decoration: const InputDecoration(hintText: '70'),
              onChanged: (_) => _recalcGoal(),
            ),
          ])),
        ]),
        const Gap(16),
        _label('Bo\'y (cm)'),
        const Gap(8),
        TextField(controller: _heightCtrl, keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: AppTheme.textColor),
          decoration: const InputDecoration(hintText: '170'),
          onChanged: (_) => _recalcGoal(),
        ),
        const Gap(20),
        _label('Maqsadingiz'),
        const Gap(12),
        Row(children: [
          _goalChip('lose', '🔥 Ozish'),
          const Gap(8),
          _goalChip('maintain', '⚖️ Saqlash'),
          const Gap(8),
          _goalChip('gain', '💪 Olish'),
        ]),
        const Gap(20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🎯 Kunlik maqsad: ', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              Text('$_dailyGoal kcal', style: GoogleFonts.inter(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
              )),
            ],
          ),
        ),
        const Gap(20),
      ],
    ),
  );

  Widget _Page3() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
            boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5)],
          ),
          child: const Center(child: Text('✅', style: TextStyle(fontSize: 50))),
        ).animate().scale(duration: 700.ms, curve: Curves.elasticOut),
        const Gap(32),
        Text('Tayyor!', style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.textColor))
            .animate().fadeIn(delay: 300.ms),
        const Gap(12),
        Text('Kunlik maqsadingiz', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.muted))
            .animate().fadeIn(delay: 400.ms),
        const Gap(8),
        Text('$_dailyGoal kcal', style: GoogleFonts.inter(
          fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.primary,
        )).animate().fadeIn(delay: 500.ms).scale(delay: 500.ms, curve: Curves.elasticOut),
        const Gap(32),
        Text('Hoziroq birinchi ovqatingizni skanerlang 📸',
          style: GoogleFonts.inter(fontSize: 15, color: AppTheme.muted),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 600.ms),
      ],
    ),
  );

  Widget _label(String text) => Text(text,
    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.muted, fontWeight: FontWeight.w600));

  Widget _goalChip(String value, String label) => Expanded(
    child: GestureDetector(
      onTap: () { setState(() => _goal = value); _recalcGoal(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _goal == value ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _goal == value ? AppTheme.primary : AppTheme.cardBorder),
        ),
        child: Center(child: Text(label,
          style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: _goal == value ? AppTheme.primary : AppTheme.muted,
          ))),
      ),
    ),
  );
}
