import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../theme/app_theme.dart';
import '../services/water_service.dart';

class WaterTrackerWidget extends StatefulWidget {
  const WaterTrackerWidget({super.key});

  @override
  State<WaterTrackerWidget> createState() => _WaterTrackerWidgetState();
}

class _WaterTrackerWidgetState extends State<WaterTrackerWidget>
    with SingleTickerProviderStateMixin {
  int _amount = 0;
  int _goal   = WaterService.defaultGoal;
  bool _loading = true;

  late AnimationController _waveCtrl;

  final _quickAmounts = [
    (150,  '☕', '150ml'),
    (250,  '🥤', '250ml'),
    (500,  '💧', '500ml'),
    (1000, '🍶', '1L'),
  ];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _load();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final amount = await WaterService.getTodayAmount();
    final goal   = await WaterService.getGoal();
    if (mounted) setState(() { _amount = amount; _goal = goal; _loading = false; });
  }

  Future<void> _add(int ml) async {
    final newAmount = await WaterService.add(ml);
    setState(() => _amount = newAmount);
    if (_amount >= _goal) _showGoalReached();
  }

  Future<void> _undo() async {
    if (_amount <= 0) return;
    final newAmount = await WaterService.remove(250);
    setState(() => _amount = newAmount);
  }

  void _showGoalReached() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🎉 Suv maqsadiga erishdingiz!'),
      backgroundColor: Color(0xFF0EA5E9),
      duration: Duration(seconds: 2),
    ));
  }

  Future<void> _showCustomInput() async {
    final ctrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Miqdorni kiriting', style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
            const Gap(16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: AppTheme.textColor, fontSize: 20),
              decoration: const InputDecoration(
                hintText: '300',
                suffixText: 'ml',
              ),
            ),
            const Gap(16),
            GestureDetector(
              onTap: () {
                final ml = int.tryParse(ctrl.text);
                if (ml != null && ml > 0) { _add(ml); Navigator.pop(context); }
              },
              child: Container(
                width: double.infinity, height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text('Qo\'shish', style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
            ),
            const Gap(8),
          ]),
        ),
      ),
    );
  }

  double get _progress => (_goal > 0 ? _amount / _goal : 0.0).clamp(0.0, 1.0);
  int    get _glasses  => (_amount / 250).floor();
  int    get _remaining => (_goal - _amount).clamp(0, _goal);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x330EA5E9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Text('💧', style: TextStyle(fontSize: 22)),
            const Gap(8),
            Text('Suv Tracker', style: GoogleFonts.inter(
              fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
          ]),
          GestureDetector(
            onTap: _undo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Text('↩ Bekor', style: GoogleFonts.inter(
                fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),

        const Gap(16),

        // Progress row
        Row(children: [
          // Water circle
          Stack(alignment: Alignment.center, children: [
            CircularPercentIndicator(
              radius: 55,
              lineWidth: 9,
              percent: _progress,
              progressColor: const Color(0xFF0EA5E9),
              backgroundColor: AppTheme.surface,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 600,
              center: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('💧', style: const TextStyle(fontSize: 22)),
                Text(
                  WaterService.formatMl(_amount),
                  style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w900,
                    color: const Color(0xFF0EA5E9),
                  ),
                ),
              ]),
            ),
          ]),

          const Gap(20),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _progress >= 1.0
                  ? '🎉 Maqsadga erishdingiz!'
                  : '${WaterService.formatMl(_remaining)} qoldi',
              style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textColor),
            ),
            const Gap(4),
            Text(
              'Maqsad: ${WaterService.formatMl(_goal)} · $_glasses ta stakan',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted),
            ),
            const Gap(10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppTheme.surface,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF0EA5E9)),
                minHeight: 8,
              ),
            ),
            const Gap(4),
            Text(
              '${(_progress * 100).toInt()}% bajarildi',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.muted),
            ),
          ])),
        ]),

        const Gap(16),

        // Quick add buttons
        Row(children: [
          ..._quickAmounts.map((q) => Expanded(
            child: GestureDetector(
              onTap: () => _add(q.$1),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
                ),
                child: Column(children: [
                  Text(q.$2, style: const TextStyle(fontSize: 18)),
                  const Gap(2),
                  Text(q.$3, style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: const Color(0xFF0EA5E9))),
                ]),
              ),
            ),
          )),
          // Custom button
          GestureDetector(
            onTap: _showCustomInput,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(children: [
                const Icon(Icons.add, color: AppTheme.muted, size: 18),
                const Gap(2),
                Text('Boshqa', style: GoogleFonts.inter(
                  fontSize: 10, color: AppTheme.muted, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),

        // Glasses visual
        if (_glasses > 0) ...[
          const Gap(14),
          Wrap(
            spacing: 6, runSpacing: 4,
            children: List.generate(
              (_goal / 250).ceil(),
              (i) => Text(
                i < _glasses ? '💧' : '🫙',
                style: TextStyle(
                  fontSize: 18,
                  color: i < _glasses ? null : Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
        ],
      ]),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15);
  }
}
