import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../services/gemini_vision_service.dart';
import '../models/food_entry.dart';

enum _ScanState { ready, analyzing, result, notRecognized }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  final _picker = ImagePicker();
  File? _image;
  _ScanState _state = _ScanState.ready;
  FoodAnalysis? _analysis;
  String _mealType = 'snack';
  bool _saving = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  final _mealTypes = [
    ('breakfast', '🌅', 'Nonushta'),
    ('lunch', '☀️', 'Tushlik'),
    ('dinner', '🌙', 'Kechki'),
    ('snack', '🍎', 'Snack'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xfile == null) return;
    final file = File(xfile.path);
    setState(() { _image = file; _state = _ScanState.analyzing; });
    await _analyze(file);
  }

  Future<void> _analyze(File file) async {
    final result = await GeminiVisionService.analyzeFood(file);
    setState(() {
      _analysis = result;
      _state = result.recognized ? _ScanState.result : _ScanState.notRecognized;
    });
  }

  Future<void> _saveEntry() async {
    if (_analysis == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final entry = FoodEntry(
        id: const Uuid().v4(),
        name: _analysis!.name,
        emoji: _analysis!.emoji,
        calories: _analysis!.calories,
        protein: _analysis!.protein,
        carbs: _analysis!.carbs,
        fat: _analysis!.fat,
        fiber: _analysis!.fiber,
        mealType: _mealType,
        loggedAt: DateTime.now(),
        confidence: _analysis!.confidence,
        userId: user.uid,
      );

      await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .collection('food_entries').doc(entry.id)
          .set(entry.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ ${_analysis!.name} qo\'shildi — ${_analysis!.calories} kcal'),
          backgroundColor: AppTheme.success,
        ));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Xatolik: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textColor),
                    ),
                    Text('Skanerlash', style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textColor,
                    )),
                  ],
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScanState.ready:       return _ReadyView(onPick: _pick, pulseAnim: _pulseAnim);
      case _ScanState.analyzing:   return _AnalyzingView(image: _image!);
      case _ScanState.result:      return _ResultView(
        image: _image!,
        analysis: _analysis!,
        mealType: _mealType,
        mealTypes: _mealTypes,
        saving: _saving,
        onMealChange: (m) => setState(() => _mealType = m),
        onSave: _saveEntry,
        onRetry: () => setState(() { _state = _ScanState.ready; _image = null; }),
      );
      case _ScanState.notRecognized: return _NotRecognizedView(
        onRetry: () => setState(() { _state = _ScanState.ready; _image = null; }),
      );
    }
  }
}

// ── Ready View ───────────────────────────────────────────────────
class _ReadyView extends StatelessWidget {
  final Function(ImageSource) onPick;
  final Animation<double> pulseAnim;
  const _ReadyView({required this.onPick, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated scan frame
          ScaleTransition(
            scale: pulseAnim,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primary, width: 2),
                color: AppTheme.primary.withValues(alpha: 0.05),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  ...[ [0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [1.0, 1.0] ].map((pos) =>
                    Positioned(
                      left: pos[0] == 0 ? 0 : null,
                      right: pos[0] == 1 ? 0 : null,
                      top: pos[1] == 0 ? 0 : null,
                      bottom: pos[1] == 1 ? 0 : null,
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            left: pos[0] == 0 ? const BorderSide(color: AppTheme.neon, width: 3) : BorderSide.none,
                            right: pos[0] == 1 ? const BorderSide(color: AppTheme.neon, width: 3) : BorderSide.none,
                            top: pos[1] == 0 ? const BorderSide(color: AppTheme.neon, width: 3) : BorderSide.none,
                            bottom: pos[1] == 1 ? const BorderSide(color: AppTheme.neon, width: 3) : BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Center(child: Text('🍽️', style: TextStyle(fontSize: 64))),
                ],
              ),
            ),
          ).animate().fadeIn(),
          const Gap(32),
          Text('Ovqatni suratsiz', style: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textColor,
          )).animate().fadeIn(delay: 200.ms),
          const Gap(8),
          Text('AI bir zumda kaloriyani aniqlaydi',
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.muted))
              .animate().fadeIn(delay: 300.ms),
          const Gap(48),
          // Camera button
          GestureDetector(
            onTap: () => onPick(ImageSource.camera),
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  blurRadius: 24, spreadRadius: 4,
                )],
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 36),
            ),
          ).animate().scale(delay: 400.ms, curve: Curves.elasticOut),
          const Gap(16),
          Text('Kamera', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.muted))
              .animate().fadeIn(delay: 500.ms),
          const Gap(24),
          GestureDetector(
            onTap: () => onPick(ImageSource.gallery),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.photo_library_rounded, color: AppTheme.primary, size: 20),
                const Gap(8),
                Text('Galereyadan tanlash', style: GoogleFonts.inter(
                  color: AppTheme.textColor, fontWeight: FontWeight.w600,
                )),
              ]),
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }
}

// ── Analyzing View ───────────────────────────────────────────────
class _AnalyzingView extends StatelessWidget {
  final File image;
  const _AnalyzingView({required this.image});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(image, fit: BoxFit.cover, width: double.infinity,
                color: Colors.black.withValues(alpha: 0.3),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Shimmer.fromColors(
                baseColor: AppTheme.primary,
                highlightColor: AppTheme.neon,
                child: Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary),
                  child: const Icon(Icons.restaurant, color: Colors.white, size: 36),
                ),
              ),
              const Gap(20),
              Text('AI tahlil qilmoqda...', style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor,
              )).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms, color: AppTheme.neon),
              const Gap(8),
              Text('Gemini Vision ishlamoqda ✨', style: GoogleFonts.inter(
                fontSize: 13, color: AppTheme.muted,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Result View ──────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final File image;
  final FoodAnalysis analysis;
  final String mealType;
  final List<(String, String, String)> mealTypes;
  final bool saving;
  final ValueChanged<String> onMealChange;
  final VoidCallback onSave;
  final VoidCallback onRetry;

  const _ResultView({
    required this.image, required this.analysis, required this.mealType,
    required this.mealTypes, required this.saving,
    required this.onMealChange, required this.onSave, required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Food image
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(image, height: 200, width: double.infinity, fit: BoxFit.cover),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
          const Gap(20),

          // Food name & calorie badge
          Row(
            children: [
              Text(analysis.emoji, style: const TextStyle(fontSize: 36)),
              const Gap(12),
              Expanded(child: Text(analysis.name, style: GoogleFonts.inter(
                fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textColor,
              ))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 16)],
                ),
                child: Text('${analysis.calories}\nkcal', textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
          const Gap(16),

          // Macro grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.cardBorder)),
            child: Column(
              children: [
                Text('Ozuqa tarkibi', style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.muted)),
                const Gap(12),
                Row(children: [
                  _MacroTile('🥩', 'Protein', '${analysis.protein.toStringAsFixed(1)}g', const Color(0xFF3B82F6)),
                  _MacroTile('🍞', 'Uglevodlar', '${analysis.carbs.toStringAsFixed(1)}g', AppTheme.accent),
                  _MacroTile('🧈', 'Yog\'', '${analysis.fat.toStringAsFixed(1)}g', const Color(0xFFEF4444)),
                  _MacroTile('🌿', 'Tola', '${analysis.fiber.toStringAsFixed(1)}g', AppTheme.primary),
                ]),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const Gap(12),

          // Confidence
          Row(children: [
            Text('AI ishonchliligi: ', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.muted)),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: analysis.confidence,
                backgroundColor: AppTheme.cardBorder,
                valueColor: AlwaysStoppedAnimation(
                  analysis.confidence > 0.8 ? AppTheme.success : AppTheme.warning,
                ),
                minHeight: 6,
              ),
            )),
            const Gap(8),
            Text('${(analysis.confidence * 100).toInt()}%',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w700)),
          ]).animate().fadeIn(delay: 300.ms),
          const Gap(16),

          // Meal type
          Text('Qaysi ovqat?', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.muted, fontWeight: FontWeight.w600)),
          const Gap(10),
          Row(children: mealTypes.map((m) {
            final selected = m.$1 == mealType;
            return Expanded(child: GestureDetector(
              onTap: () => onMealChange(m.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppTheme.primary : AppTheme.cardBorder),
                ),
                child: Column(children: [
                  Text(m.$2, style: const TextStyle(fontSize: 18)),
                  Text(m.$3, style: GoogleFonts.inter(
                    fontSize: 10, color: selected ? AppTheme.primary : AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  )),
                ]),
              ),
            ));
          }).toList()).animate().fadeIn(delay: 350.ms),
          const Gap(24),

          // Save button
          GestureDetector(
            onTap: saving ? null : onSave,
            child: Container(
              width: double.infinity, height: 58,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Center(child: saving
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text('✅  Qo\'shish', style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ).animate().slideY(begin: 0.3, delay: 400.ms),
          const Gap(12),
          GestureDetector(
            onTap: onRetry,
            child: Text('🔄 Qayta surating', style: GoogleFonts.inter(color: AppTheme.muted, fontWeight: FontWeight.w600)),
          ),
          const Gap(20),
        ],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _MacroTile(this.emoji, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 20)),
    const Gap(4),
    Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.muted)),
  ]));
}

// ── Not Recognized View ──────────────────────────────────────────
class _NotRecognizedView extends StatelessWidget {
  final VoidCallback onRetry;
  const _NotRecognizedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 72))
              .animate().scale(curve: Curves.elasticOut),
          const Gap(20),
          Text('Ovqat aniqlanmadi', style: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textColor,
          )),
          const Gap(8),
          Text('Rasmda ovqat ko\'rinmayapti.\nAniqroq suring yoki galereyadan tanlang.',
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.muted), textAlign: TextAlign.center),
          const Gap(32),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('🔄 Qayta urinish', style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
              )),
            ),
          ),
        ],
      ),
    );
  }
}
