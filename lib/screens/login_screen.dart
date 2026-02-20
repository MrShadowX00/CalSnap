import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  bool _loading       = false;
  bool _isLogin       = true;
  String? _error;

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(), password: _passCtrl.text);
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(), password: _passCtrl.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':    return 'Foydalanuvchi topilmadi';
      case 'wrong-password':    return 'Noto\'g\'ri parol';
      case 'email-already-in-use': return 'Bu email allaqachon ishlatilgan';
      case 'weak-password':     return 'Parol kamida 6 ta belgi bo\'lsin';
      case 'invalid-email':     return 'Email noto\'g\'ri';
      default:                  return 'Xatolik: $code';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          const Gap(40),
          Text('📸', style: const TextStyle(fontSize: 64))
              .animate().scale(curve: Curves.elasticOut),
          const Gap(16),
          Text('CalSnap', style: GoogleFonts.inter(
            fontSize: 34, fontWeight: FontWeight.w900, color: AppTheme.textColor))
              .animate().fadeIn(delay: 200.ms),
          const Gap(6),
          Text('AI Kaloriya Hisoblagich', style: GoogleFonts.inter(fontSize: 15, color: AppTheme.muted))
              .animate().fadeIn(delay: 300.ms),
          const Gap(48),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.cardBorder)),
            child: Column(children: [
              // Toggle
              Container(
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  _tab('Kirish', _isLogin, () => setState(() { _isLogin = true; _error = null; })),
                  _tab('Ro\'yxat', !_isLogin, () => setState(() { _isLogin = false; _error = null; })),
                ]),
              ),
              const Gap(24),
              TextField(
                controller: _emailCtrl,
                style: GoogleFonts.inter(color: AppTheme.textColor),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              const Gap(12),
              TextField(
                controller: _passCtrl,
                style: GoogleFonts.inter(color: AppTheme.textColor),
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Parol'),
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const Gap(10),
                Text(_error!, style: GoogleFonts.inter(color: AppTheme.danger, fontSize: 13)),
              ],
              const Gap(24),
              GestureDetector(
                onTap: _loading ? null : _submit,
                child: Container(
                  width: double.infinity, height: 56,
                  decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))]),
                  child: Center(child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(_isLogin ? 'Kirish' : 'Ro\'yxatdan o\'tish',
                        style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
              ),
            ]).animate().fadeIn(delay: 400.ms),
          ),
        ]),
      )),
    ),
  );

  Widget _tab(String label, bool active, VoidCallback onTap) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: Text(label, style: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        color: active ? Colors.white : AppTheme.muted,
      ))),
    ),
  ));
}
