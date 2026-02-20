import 'package:shared_preferences/shared_preferences.dart';

class WaterService {
  static const _keyAmount = 'water_amount';
  static const _keyDate   = 'water_date';
  static const _keyGoal   = 'water_goal';
  static const defaultGoal = 2000; // ml

  /// Returns today's consumed water in ml
  static Future<int> getTodayAmount() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyDate) ?? '';
    final today = _today();
    if (saved != today) {
      await prefs.setInt(_keyAmount, 0);
      await prefs.setString(_keyDate, today);
      return 0;
    }
    return prefs.getInt(_keyAmount) ?? 0;
  }

  static Future<int> getGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyGoal) ?? defaultGoal;
  }

  static Future<void> setGoal(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGoal, ml);
  }

  static Future<int> add(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today();
    final saved = prefs.getString(_keyDate) ?? '';
    if (saved != today) await prefs.setString(_keyDate, today);
    final current = saved == today ? (prefs.getInt(_keyAmount) ?? 0) : 0;
    final newAmount = current + ml;
    await prefs.setInt(_keyAmount, newAmount);
    return newAmount;
  }

  static Future<int> remove(int ml) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getTodayAmount();
    final newAmount = (current - ml).clamp(0, 99999);
    await prefs.setInt(_keyAmount, newAmount);
    return newAmount;
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAmount, 0);
    await prefs.setString(_keyDate, _today());
  }

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Convert ml to glasses (1 glass = 250ml)
  static double toGlasses(int ml) => ml / 250;

  static String formatMl(int ml) {
    if (ml >= 1000) return '${(ml / 1000).toStringAsFixed(1)}L';
    return '${ml}ml';
  }
}
