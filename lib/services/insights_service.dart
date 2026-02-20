import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'water_service.dart';

enum InsightType { success, warning, danger, info }

class Insight {
  final InsightType type;
  final String emoji;
  final String title;
  final String body;
  final String? action;

  const Insight({
    required this.type,
    required this.emoji,
    required this.title,
    required this.body,
    this.action,
  });

  String get color {
    switch (type) {
      case InsightType.success: return 'green';
      case InsightType.warning: return 'amber';
      case InsightType.danger:  return 'red';
      case InsightType.info:    return 'blue';
    }
  }
}

class DailyStats {
  final String date;
  final int calories;
  final int goal;
  final double protein;
  final double carbs;
  final double fat;
  final int waterMl;
  final int waterGoal;

  const DailyStats({
    required this.date,
    required this.calories,
    required this.goal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.waterMl,
    required this.waterGoal,
  });

  double get calProgress => goal > 0 ? calories / goal : 0;
  double get waterProgress => waterGoal > 0 ? waterMl / waterGoal : 0;
  bool get isCalOver   => calories > goal * 1.15;
  bool get isCalUnder  => calories < goal * 0.6;
  bool get isWaterLow  => waterMl < waterGoal * 0.5;
  bool get isBalanced  => !isCalOver && !isCalUnder && !isWaterLow;
}

class MonthlyStats {
  final int avgCalories;
  final int goalCalories;
  final int avgWater;
  final int goalWater;
  final int daysLogged;
  final int daysOverGoal;
  final int daysUnderGoal;
  final int daysOnTarget;
  final double avgProtein;
  final double avgCarbs;
  final double avgFat;
  final List<int> dailyCalories; // last 30 days

  const MonthlyStats({
    required this.avgCalories,
    required this.goalCalories,
    required this.avgWater,
    required this.goalWater,
    required this.daysLogged,
    required this.daysOverGoal,
    required this.daysUnderGoal,
    required this.daysOnTarget,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.dailyCalories,
  });

  double get calAccuracy => daysLogged > 0 ? daysOnTarget / daysLogged : 0;
}

class InsightsService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ── Load today's stats ──────────────────────────────────────────
  static Future<DailyStats> getTodayStats() async {
    final user = _auth.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final goal = prefs.getInt('daily_goal') ?? 2000;
    final waterGoal = await WaterService.getGoal();
    final waterMl = await WaterService.getTodayAmount();
    final today = _todayStr();

    if (user == null) {
      return DailyStats(date: today, calories: 0, goal: goal,
        protein: 0, carbs: 0, fat: 0, waterMl: waterMl, waterGoal: waterGoal);
    }

    try {
      final start = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
      final snap = await _db
          .collection('users').doc(user.uid)
          .collection('food_entries')
          .where('loggedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get();

      int cal = 0; double prot = 0, carb = 0, fat = 0;
      for (final d in snap.docs) {
        final data = d.data();
        cal  += (data['calories'] as num?)?.toInt() ?? 0;
        prot += (data['protein']  as num?)?.toDouble() ?? 0;
        carb += (data['carbs']    as num?)?.toDouble() ?? 0;
        fat  += (data['fat']      as num?)?.toDouble() ?? 0;
      }

      return DailyStats(date: today, calories: cal, goal: goal,
        protein: prot, carbs: carb, fat: fat,
        waterMl: waterMl, waterGoal: waterGoal);
    } catch (_) {
      return DailyStats(date: today, calories: 0, goal: goal,
        protein: 0, carbs: 0, fat: 0, waterMl: waterMl, waterGoal: waterGoal);
    }
  }

  // ── Load monthly stats ──────────────────────────────────────────
  static Future<MonthlyStats> getMonthlyStats() async {
    final user = _auth.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final goal = prefs.getInt('daily_goal') ?? 2000;
    final waterGoal = await WaterService.getGoal();

    if (user == null) {
      return MonthlyStats(avgCalories: 0, goalCalories: goal, avgWater: 0,
        goalWater: waterGoal, daysLogged: 0, daysOverGoal: 0,
        daysUnderGoal: 0, daysOnTarget: 0, avgProtein: 0,
        avgCarbs: 0, avgFat: 0, dailyCalories: []);
    }

    try {
      final since = DateTime.now().subtract(const Duration(days: 30));
      final snap = await _db
          .collection('users').doc(user.uid)
          .collection('food_entries')
          .where('loggedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .get();

      // Group by day
      final dayMap = <String, Map<String, double>>{};
      for (final d in snap.docs) {
        final data = d.data();
        DateTime dt;
        if (data['loggedAt'] is Timestamp) {
          dt = (data['loggedAt'] as Timestamp).toDate();
        } else continue;
        final key = DateFormat('yyyy-MM-dd').format(dt);
        dayMap.putIfAbsent(key, () => {'cal': 0, 'prot': 0, 'carb': 0, 'fat': 0});
        dayMap[key]!['cal']  = (dayMap[key]!['cal']!  + ((data['calories'] as num?)?.toDouble() ?? 0));
        dayMap[key]!['prot'] = (dayMap[key]!['prot']! + ((data['protein']  as num?)?.toDouble() ?? 0));
        dayMap[key]!['carb'] = (dayMap[key]!['carb']! + ((data['carbs']    as num?)?.toDouble() ?? 0));
        dayMap[key]!['fat']  = (dayMap[key]!['fat']!  + ((data['fat']      as num?)?.toDouble() ?? 0));
      }

      final days = dayMap.values.toList();
      if (days.isEmpty) {
        return MonthlyStats(avgCalories: 0, goalCalories: goal, avgWater: 0,
          goalWater: waterGoal, daysLogged: 0, daysOverGoal: 0,
          daysUnderGoal: 0, daysOnTarget: 0, avgProtein: 0,
          avgCarbs: 0, avgFat: 0, dailyCalories: []);
      }

      final totalCal  = days.fold(0.0, (s, d) => s + d['cal']!);
      final totalProt = days.fold(0.0, (s, d) => s + d['prot']!);
      final totalCarb = days.fold(0.0, (s, d) => s + d['carb']!);
      final totalFat  = days.fold(0.0, (s, d) => s + d['fat']!);
      final n = days.length;

      int over = 0, under = 0, onTarget = 0;
      final calList = <int>[];
      // Fill 30 days
      for (int i = 29; i >= 0; i--) {
        final d = DateTime.now().subtract(Duration(days: i));
        final key = DateFormat('yyyy-MM-dd').format(d);
        final cal = dayMap[key]?['cal']?.toInt() ?? 0;
        calList.add(cal);
        if (dayMap.containsKey(key)) {
          if (cal > goal * 1.15)      over++;
          else if (cal < goal * 0.6)  under++;
          else                        onTarget++;
        }
      }

      return MonthlyStats(
        avgCalories: (totalCal / n).round(),
        goalCalories: goal,
        avgWater: waterGoal, // Simplified — water history not in Firestore
        goalWater: waterGoal,
        daysLogged: n,
        daysOverGoal: over,
        daysUnderGoal: under,
        daysOnTarget: onTarget,
        avgProtein: totalProt / n,
        avgCarbs: totalCarb / n,
        avgFat: totalFat / n,
        dailyCalories: calList,
      );
    } catch (_) {
      return MonthlyStats(avgCalories: 0, goalCalories: goal, avgWater: 0,
        goalWater: waterGoal, daysLogged: 0, daysOverGoal: 0,
        daysUnderGoal: 0, daysOnTarget: 0, avgProtein: 0,
        avgCarbs: 0, avgFat: 0, dailyCalories: []);
    }
  }

  // ── Smart suggestion algorithm ──────────────────────────────────
  static List<Insight> generateInsights(DailyStats today, MonthlyStats month) {
    final insights = <Insight>[];
    final hour = DateTime.now().hour;

    // 1. CALORIES — Over limit
    if (today.isCalOver) {
      final excess = today.calories - today.goal;
      insights.add(Insight(
        type: InsightType.danger,
        emoji: '⚠️',
        title: 'Kaloriya me\'yordan oshdi',
        body: 'Bugun ${today.calories} kcal iste\'mol qildingiz (+$excess kcal). '
              'Kechki ovqatni engil qiling yoki 15 daqiqa yuring.',
        action: 'Mashq qo\'shing',
      ));
    }

    // 2. CALORIES — Under limit (only after 18:00)
    else if (today.isCalUnder && hour >= 18) {
      final deficit = today.goal - today.calories;
      insights.add(Insight(
        type: InsightType.warning,
        emoji: '📉',
        title: 'Kam kaloriya iste\'mol qildingiz',
        body: 'Hali ${today.goal} kcal maqsadingizga $deficit kcal yetishmayapti. '
              'Sog\'lom snack qo\'shing — yong\'oq, yogurt yoki meva.',
        action: 'Snack qo\'shing',
      ));
    }

    // 3. CALORIES — On target 🎉
    else if (!today.isCalOver && !today.isCalUnder && today.calories > 0) {
      insights.add(Insight(
        type: InsightType.success,
        emoji: '✅',
        title: 'Kaloriya muvozanatda!',
        body: 'Ajoyib! Bugun ${today.calories} kcal — me\'yor doirasida. Shunday davom eting!',
      ));
    }

    // 4. WATER — Low (after 14:00)
    if (today.isWaterLow && hour >= 14) {
      insights.add(Insight(
        type: InsightType.warning,
        emoji: '💧',
        title: 'Suv ichish eslatmasi',
        body: 'Bugun atigi ${WaterService.formatMl(today.waterMl)} ichdingiz. '
              'Me\'yor ${WaterService.formatMl(today.waterGoal)}. '
              'Hozir bir stakan suv iching!',
        action: 'Suv qo\'shish',
      ));
    }

    // 5. WATER — Good
    else if (today.waterProgress >= 0.8 && today.waterMl > 0) {
      insights.add(Insight(
        type: InsightType.success,
        emoji: '💧',
        title: 'Suv muvozanati yaxshi!',
        body: '${WaterService.formatMl(today.waterMl)} ichdingiz — '
              "${(today.waterProgress * 100).toInt()}% maqsadda. Davom eting!",
      ));
    }

    // 6. MONTHLY — Consecutive over days
    if (month.daysOverGoal >= 5) {
      insights.add(Insight(
        type: InsightType.warning,
        emoji: '📊',
        title: 'Oylik trend: oshib ketmoqda',
        body: 'So\'ngi 30 kunda ${month.daysOverGoal} marta me\'yordan oshgansiz. '
              'O\'rtacha: ${month.avgCalories} kcal. Maqsad: ${month.goalCalories} kcal.',
        action: 'Dietologga so\'rang',
      ));
    }

    // 7. MONTHLY — Mostly under
    if (month.daysUnderGoal >= 7 && month.daysLogged > 0) {
      insights.add(Insight(
        type: InsightType.info,
        emoji: '🔋',
        title: 'Energiya yetishmasligi',
        body: 'Oyda ${month.daysUnderGoal} marta kam kaloriya iste\'mol qildingiz. '
              'Bu charchoqqa olib kelishi mumkin. '
              'Proteinli taomlarni ko\'paytiring.',
      ));
    }

    // 8. MONTHLY — Great accuracy
    if (month.calAccuracy >= 0.7 && month.daysLogged >= 7) {
      insights.add(Insight(
        type: InsightType.success,
        emoji: '🏆',
        title: 'Oylik natija: Ajoyib!',
        body: '${(month.calAccuracy * 100).toInt()}% kunlarda maqsad doirasida. '
              '${month.daysLogged} kun kuzatdingiz. Zo\'r natija!',
      ));
    }

    // 9. PROTEIN — Low
    if (today.protein < 40 && today.calories > 500) {
      insights.add(Insight(
        type: InsightType.info,
        emoji: '🥩',
        title: 'Protein yetishmasligi',
        body: 'Bugun faqat ${today.protein.toStringAsFixed(0)}g protein. '
              'Tavsiya: 50-150g/kun. Go\'sht, tuxum, yogurt qo\'shing.',
      ));
    }

    // 10. Morning motivation (before 10:00, no food yet)
    if (hour < 10 && today.calories == 0) {
      insights.add(Insight(
        type: InsightType.info,
        emoji: '☀️',
        title: 'Xayrli tong!',
        body: 'Nonushtani unutmang. Ertalabki ovqat metabolizmni yaxshilaydi '
              'va kunboyi energiyani saqlaydi.',
        action: 'Nonushta qo\'shing',
      ));
    }

    return insights.take(3).toList(); // Max 3 insights at a time
  }

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }
}
