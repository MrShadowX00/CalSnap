class UserProfile {
  final String uid;
  final String name;
  final int age;
  final double weight;   // kg
  final double height;   // cm
  final String goal;     // lose / maintain / gain
  final int dailyCalorieGoal;

  const UserProfile({
    required this.uid,
    required this.name,
    this.age = 25,
    this.weight = 70,
    this.height = 170,
    this.goal = 'maintain',
    this.dailyCalorieGoal = 2000,
  });

  /// Harris-Benedict BMR formula
  static int calculateBMR({
    required double weight,
    required double height,
    required int age,
    required String goal,
  }) {
    // Assuming male formula (simplified)
    final bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    final tdee = bmr * 1.375; // Lightly active
    switch (goal) {
      case 'lose':     return (tdee - 500).round();
      case 'gain':     return (tdee + 300).round();
      default:         return tdee.round();
    }
  }

  Map<String, dynamic> toMap() => {
    'uid': uid, 'name': name, 'age': age,
    'weight': weight, 'height': height,
    'goal': goal, 'dailyCalorieGoal': dailyCalorieGoal,
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    uid: m['uid'] ?? '',
    name: m['name'] ?? '',
    age: (m['age'] as num?)?.toInt() ?? 25,
    weight: (m['weight'] as num?)?.toDouble() ?? 70,
    height: (m['height'] as num?)?.toDouble() ?? 170,
    goal: m['goal'] ?? 'maintain',
    dailyCalorieGoal: (m['dailyCalorieGoal'] as num?)?.toInt() ?? 2000,
  );

  double get bmi => weight / ((height / 100) * (height / 100));

  String get bmiLabel {
    if (bmi < 18.5) return 'Kam vazn';
    if (bmi < 25)   return 'Normal';
    if (bmi < 30)   return 'Ortiqcha';
    return 'Semizlik';
  }

  String get goalEmoji {
    switch (goal) {
      case 'lose':  return '🔥';
      case 'gain':  return '💪';
      default:      return '⚖️';
    }
  }

  String get goalLabel {
    switch (goal) {
      case 'lose':  return 'Ozish';
      case 'gain':  return 'Olish';
      default:      return 'Saqlash';
    }
  }
}
