import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../theme/app_theme.dart';
import '../services/revenue_cat_service.dart';

class ProPaywallScreen extends StatefulWidget {
  const ProPaywallScreen({super.key});
  @override
  State<ProPaywallScreen> createState() => _ProPaywallScreenState();
}

class _ProPaywallScreenState extends State<ProPaywallScreen> {
  bool _loading = false;
  bool _restoring = false;

  final _features = [
    ('♾️', 'Cheksiz skanerlash', 'Kuniga istalgancha ovqat skaner qiling'),
    ('🔬', 'Batafsil ozuqa', 'Vitaminlar, minerallar, glikemik indeks'),
    ('🤖', 'Cheksiz AI chat', 'AI dietolog bilan istalgancha gaplashing'),
    ('📊', 'Haftalik hisobotlar', 'Chuqur tahlil va ovqatlanish tendentsiyasi'),
    ('📅', 'Cheksiz tarix', 'Barcha vaqt ovqatlanish tarixi'),
    ('🚫', 'Reklamasiz', 'Diqqatsizlantiradigan narsa yo\'q'),
  ];

  Future<void> _purchase() async {
    setState(() => _loading = true);
    try {
      final pkgs = await RevenueCatService.getPackages();
      if (pkgs.isNotEmpty && mounted) {
        final ok = await RevenueCatService.purchasePro(pkgs.first);
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('🎉 Pro ga xush kelibsiz!'), backgroundColor: AppTheme.success));
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Xatolik: $e'), backgroundColor: AppTheme.danger));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    try {
      final ok = await RevenueCatService.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? '✅ Xarid tiklandi!' : 'Tiklash topilmadi'),
          backgroundColor: ok ? AppTheme.success : AppTheme.muted));
        if (ok) Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: AppTheme.muted)),
            TextButton(onPressed: _restoring ? null : _restore,
              child: _restoring
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Tiklash', style: TextStyle(color: AppTheme.muted))),
          ]),
        ),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            // Crown
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.accentGradient,
                boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5)]),
              child: const Center(child: Text('👑', style: TextStyle(fontSize: 44))),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const Gap(20),
            Text('CalSnap Pro', style: GoogleFonts.inter(
              fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textColor))
                .animate().fadeIn(delay: 200.ms),
            const Gap(8),
            Text('Sog\'lom hayot uchun to\'liq imkoniyat', style: GoogleFonts.inter(
              fontSize: 15, color: AppTheme.muted), textAlign: TextAlign.center)
                .animate().fadeIn(delay: 300.ms),
            const Gap(28),
            ...List.generate(_features.length, (i) {
              final f = _features[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder)),
                  child: Row(children: [
                    Text(f.$1, style: const TextStyle(fontSize: 24)),
                    const Gap(16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f.$2, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                      Text(f.$3, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted)),
                    ])),
                    const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                  ]),
                ).animate().slideX(begin: 0.3, delay: Duration(milliseconds: 400 + i * 80), duration: 400.ms, curve: Curves.easeOut)
                  .fadeIn(delay: Duration(milliseconds: 400 + i * 80)),
              );
            }),
            const Gap(24),
            // Price
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(gradient: AppTheme.neonGradient, borderRadius: BorderRadius.circular(50)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('\$3.99', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black)),
                Text(' / oy', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black.withValues(alpha: 0.7))),
              ]),
            ).animate().fadeIn(delay: 900.ms).scale(delay: 900.ms),
            const Gap(8),
            Text('7 kunlik bepul sinov · Istalgan vaqt bekor qilish',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted), textAlign: TextAlign.center)
                .animate().fadeIn(delay: 1000.ms),
            const Gap(32),
          ]),
        )),
        Padding(
          padding: const EdgeInsets.all(24),
          child: GestureDetector(
            onTap: _loading ? null : _purchase,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 60,
              decoration: BoxDecoration(
                gradient: _loading ? null : AppTheme.accentGradient,
                color: _loading ? AppTheme.card : null,
                borderRadius: BorderRadius.circular(18),
                boxShadow: _loading ? null : [BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Center(child: _loading
                ? const CircularProgressIndicator(color: AppTheme.textColor)
                : Text('🚀  Pro ni Boshlash', style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
          ).animate().slideY(begin: 0.5, delay: 1100.ms, duration: 500.ms, curve: Curves.easeOut),
        ),
      ])),
    ),
  );
}
