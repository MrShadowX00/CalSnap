import 'package:cloud_firestore/cloud_firestore.dart';

class FoodEntry {
  final String id;
  final String name;
  final String emoji;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String mealType;   // breakfast / lunch / dinner / snack
  final DateTime loggedAt;
  final double confidence;
  final String userId;

  const FoodEntry({
    required this.id,
    required this.name,
    this.emoji = '🍽️',
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.mealType = 'snack',
    required this.loggedAt,
    this.confidence = 1.0,
    this.userId = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'mealType': mealType,
    'loggedAt': Timestamp.fromDate(loggedAt),
    'confidence': confidence,
    'userId': userId,
  };

  factory FoodEntry.fromMap(Map<String, dynamic> m, String docId) {
    DateTime dt;
    if (m['loggedAt'] is Timestamp) {
      dt = (m['loggedAt'] as Timestamp).toDate();
    } else {
      dt = DateTime.tryParse(m['loggedAt']?.toString() ?? '') ?? DateTime.now();
    }
    return FoodEntry(
      id: docId,
      name: m['name'] ?? '',
      emoji: m['emoji'] ?? '🍽️',
      calories: (m['calories'] as num?)?.toInt() ?? 0,
      protein: (m['protein'] as num?)?.toDouble() ?? 0,
      carbs: (m['carbs'] as num?)?.toDouble() ?? 0,
      fat: (m['fat'] as num?)?.toDouble() ?? 0,
      fiber: (m['fiber'] as num?)?.toDouble() ?? 0,
      mealType: m['mealType'] ?? 'snack',
      loggedAt: dt,
      confidence: (m['confidence'] as num?)?.toDouble() ?? 1.0,
      userId: m['userId'] ?? '',
    );
  }

  FoodEntry copyWith({String? mealType}) => FoodEntry(
    id: id, name: name, emoji: emoji, calories: calories,
    protein: protein, carbs: carbs, fat: fat, fiber: fiber,
    mealType: mealType ?? this.mealType,
    loggedAt: loggedAt, confidence: confidence, userId: userId,
  );

  String get mealLabel {
    switch (mealType) {
      case 'breakfast': return 'Nonushta';
      case 'lunch':     return 'Tushlik';
      case 'dinner':    return 'Kechki ovqat';
      default:          return 'Snack';
    }
  }

  String get mealEmoji {
    switch (mealType) {
      case 'breakfast': return '🌅';
      case 'lunch':     return '☀️';
      case 'dinner':    return '🌙';
      default:          return '🍎';
    }
  }
}
