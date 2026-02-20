import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class FoodAnalysis {
  final bool recognized;
  final String name;
  final String emoji;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String servingSize;
  final double confidence;

  const FoodAnalysis({
    required this.recognized,
    this.name = '',
    this.emoji = '🍽️',
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.servingSize = '',
    this.confidence = 0,
  });

  factory FoodAnalysis.notRecognized() => const FoodAnalysis(recognized: false);
}

class GeminiVisionService {
  static const _apiKey = 'AIzaSyAsYa0tVqaoLqjHDgpuWoRJQjGm6Psp6To';

  static Future<FoodAnalysis> analyzeFood(File imageFile) async {
    try {
      final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
      final imageBytes = await imageFile.readAsBytes();

      const prompt = '''Analyze this food image and return ONLY a JSON object (no markdown, no explanation):
{
  "recognized": true,
  "name": "food name in Uzbek if possible, otherwise English",
  "emoji": "single food emoji",
  "calories_per_serving": 350,
  "protein_g": 12.5,
  "carbs_g": 45.0,
  "fat_g": 8.0,
  "fiber_g": 3.0,
  "serving_size": "1 porsiya (~250g)",
  "confidence": 0.92
}
If no food is visible: {"recognized": false}
All numeric values must be realistic estimates for a typical serving.''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ]);

      final text = response.text ?? '{"recognized": false}';
      final clean = text
          .replaceAll(RegExp(r'```(?:json)?\n?'), '')
          .replaceAll('```', '')
          .trim();

      final json = jsonDecode(clean) as Map<String, dynamic>;

      if (json['recognized'] == false) return FoodAnalysis.notRecognized();

      return FoodAnalysis(
        recognized: true,
        name: json['name']?.toString() ?? 'Noma\'lum ovqat',
        emoji: json['emoji']?.toString() ?? '🍽️',
        calories: (json['calories_per_serving'] as num?)?.toInt() ?? 0,
        protein: (json['protein_g'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs_g'] as num?)?.toDouble() ?? 0,
        fat: (json['fat_g'] as num?)?.toDouble() ?? 0,
        fiber: (json['fiber_g'] as num?)?.toDouble() ?? 0,
        servingSize: json['serving_size']?.toString() ?? '1 porsiya',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      );
    } catch (e) {
      return FoodAnalysis.notRecognized();
    }
  }

  static Future<String> askDietitian(
      String message, int dailyGoal, int consumed) async {
    try {
      final remaining = dailyGoal - consumed;
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
        systemInstruction: Content.text(
          'Sen CalSnap AI dietologisan. '
          'Foydalanuvchining kunlik maqsadi: $dailyGoal kcal. '
          'Bugun iste\'mol qilingan: $consumed kcal. '
          'Qolgan: $remaining kcal. '
          'Foydalanuvchi tilida (o\'zbek/rus/ingliz) javob ber. '
          'Qisqa (2-3 gap), rag\'batlantiruvchi, emoji ishlat.',
        ),
      );
      final response = await model.generateContent([Content.text(message)]);
      return response.text ?? 'Sog\'lom ovqatlanishda davom eting! 💪';
    } catch (_) {
      return 'Hozir ulanishda muammo. Qayta urinib ko\'ring! 🙏';
    }
  }
}
