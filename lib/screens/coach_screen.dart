import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/gemini_vision_service.dart';
import '../services/revenue_cat_service.dart';

class _Msg { final String text; final bool isUser; _Msg(this.text, this.isUser); }

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});
  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> with TickerProviderStateMixin {
  final _msgs = <_Msg>[];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;
  bool _isPro = false;
  int _freeUsed = 0;
  static const _freeLimit = 5;
  int _dailyGoal = 2000;
  int _consumed = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  final _quickReplies = [
    '💪 Motivatsiya ber',
    '🍽️ Kechki ovqat tavsiyasi',
    '📊 Bugungi tahlil',
    '💧 Suv ichish eslatmasi',
    '🔥 Kaloriya tejash usullari',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulse = Tween(begin: 0.94, end: 1.06).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _init();
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _init() async {
    final pro = RevenueCatService.isPro;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPro = pro;
      _dailyGoal = prefs.getInt('daily_goal') ?? 2000;
      _msgs.add(_Msg('Salom! 👋 Men CalSnap AI dietologingizman.\n\nOvqatlanish, kaloriya yoki sog\'lom hayot haqida istalgan savolni bering! 🥗', false));
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    if (!_isPro && _freeUsed >= _freeLimit) { _showProModal(); return; }
    setState(() { _msgs.add(_Msg(text, true)); _typing = true; _freeUsed++; });
    _ctrl.clear();
    _scrollBottom();
    try {
      final reply = await GeminiVisionService.askDietitian(text, _dailyGoal, _consumed);
      if (mounted) { setState(() { _typing = false; _msgs.add(_Msg(reply, false)); }); _scrollBottom(); }
    } catch (_) {
      if (mounted) { setState(() { _typing = false; _msgs.add(_Msg('Xatolik yuz berdi 😔', false)); }); }
    }
  }

  void _scrollBottom() => Future.delayed(const Duration(milliseconds: 100), () {
    if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  void _showProModal() => showModalBottomSheet(
    context: context, backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🤖', style: TextStyle(fontSize: 48)),
        const Gap(12),
        Text('Bepul limit tugadi', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textColor)),
        const Gap(8),
        Text('Cheksiz AI chat uchun Pro ga o\'ting', style: GoogleFonts.inter(fontSize: 15, color: AppTheme.muted)),
        const Gap(24),
        GestureDetector(
          onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/pro'); },
          child: Container(
            width: double.infinity, height: 56,
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text('👑 Pro ni Boshlash', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
        ),
        const Gap(12),
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Keyinroq', style: GoogleFonts.inter(color: AppTheme.muted))),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.8),
              border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: Row(children: [
              ScaleTransition(scale: _pulse, child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.primaryGradient,
                  boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 2)]),
                child: const Center(child: Text('🥗', style: TextStyle(fontSize: 26))),
              )).animate().scale(curve: Curves.elasticOut),
              const Gap(14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI Dietolog', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textColor)),
                Text('Gemini AI • Online', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted)),
              ])),
              if (!_isPro) GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/pro'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(gradient: AppTheme.neonGradient, borderRadius: BorderRadius.circular(20)),
                  child: Text('${_freeLimit - _freeUsed} ta qoldi',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black)),
                ),
              ),
            ]),
          ),

          // Messages
          Expanded(child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: _msgs.length + (_typing ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _msgs.length && _typing) return _TypingBubble().animate().fadeIn();
              final m = _msgs[i];
              return _Bubble(msg: m).animate()
                .slideX(begin: m.isUser ? 0.3 : -0.3, duration: 300.ms)
                .fadeIn(duration: 200.ms);
            },
          )),

          // Quick replies
          if (_msgs.length <= 2) SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _quickReplies.map((q) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _send(q),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.glassBorder)),
                    child: Text(q, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textColor, fontWeight: FontWeight.w500)),
                  ),
                ),
              )).toList(),
            ).animate().slideY(begin: 0.5, duration: 400.ms),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(color: AppTheme.surface, border: Border(top: BorderSide(color: AppTheme.cardBorder))),
            child: Row(children: [
              Expanded(child: Container(
                decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.cardBorder)),
                child: TextField(
                  controller: _ctrl,
                  style: GoogleFonts.inter(color: AppTheme.textColor, fontSize: 15),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: InputDecoration(
                    hintText: 'Xabar yozing...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.muted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              )),
              const Gap(10),
              GestureDetector(
                onTap: () => _send(_ctrl.text),
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.primaryGradient,
                    boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ]),
          ),
        ])),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  const _Bubble({required this.msg});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!msg.isUser) ...[
          Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.primaryGradient),
            child: const Center(child: Text('🥗', style: TextStyle(fontSize: 16)))),
          const Gap(8),
        ],
        Flexible(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: msg.isUser ? AppTheme.primaryGradient : null,
            color: msg.isUser ? null : AppTheme.card,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
              bottomRight: Radius.circular(msg.isUser ? 4 : 18),
            ),
            border: msg.isUser ? null : Border.all(color: AppTheme.cardBorder),
            boxShadow: msg.isUser ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Text(msg.text, style: GoogleFonts.inter(fontSize: 14, color: msg.isUser ? Colors.white : AppTheme.textColor, height: 1.5)),
        )),
        if (msg.isUser) ...[
          const Gap(8),
          Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withValues(alpha: 0.2)),
            child: const Center(child: Icon(Icons.person, color: AppTheme.primary, size: 18))),
        ],
      ],
    ),
  );
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.primaryGradient),
        child: const Center(child: Text('🥗', style: TextStyle(fontSize: 16)))),
      const Gap(8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(color: AppTheme.card,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
          border: Border.all(color: AppTheme.cardBorder)),
        child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) =>
          Container(
            width: 8, height: 8, margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary),
          ).animate(onPlay: (c) => c.repeat())
            .moveY(begin: 0, end: -6, delay: Duration(milliseconds: i * 150), duration: 400.ms, curve: Curves.easeInOut)
            .then().moveY(begin: -6, end: 0, duration: 400.ms),
        )),
      ),
    ]),
  );
}
