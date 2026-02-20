# CalSnap — AI Calorie Counter with Camera Scan

Build a complete, production-ready Flutter app called **CalSnap**.

## Core Concept
Users open the app, tap the camera button, take a photo of food, and Gemini AI instantly returns:
- Food name
- Calories
- Protein / Carbs / Fat / Fiber

Users track daily intake against a personal calorie goal.

## Design System (MUST USE)

```dart
// lib/theme/app_theme.dart
background:  Color(0xFF0A0F0A)
surface:     Color(0xFF111A11)
card:        Color(0xFF182018)
primary:     Color(0xFF10B981)   // Emerald green
neon:        Color(0xFF00FF88)
accent:      Color(0xFFF59E0B)
textColor:   Color(0xFFF0FDF4)
muted:       Color(0xFF4B7055)
cardBorder:  Color(0xFF1F3024)
glassBorder: Color(0x3310B981)
danger:      Color(0xFFEF4444)
```

Gradients:
- primaryGradient: [Color(0xFF10B981), Color(0xFF065F46)]
- bgGradient: [Color(0xFF0A0F0A), Color(0xFF111A11), Color(0xFF0A0F0A)] topCenter→bottomCenter

## Package Config

Write this exact pubspec.yaml:

```yaml
name: calsnap
description: AI Calorie Counter with Camera Scan
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  google_generative_ai: ^0.4.3
  image_picker: ^1.1.2
  flutter_animate: ^4.5.0
  google_fonts: ^6.2.1
  gap: ^3.0.1
  percent_indicator: ^4.2.3
  fl_chart: ^0.69.0
  confetti: ^0.7.0
  shimmer: ^3.0.0
  smooth_page_indicator: ^1.2.0
  shared_preferences: ^2.3.2
  uuid: ^4.5.1
  intl: ^0.19.0
  google_mobile_ads: ^5.1.0
  purchases_flutter: ^8.0.0
  flutter_local_notifications: ^18.0.1
  timezone: ^0.9.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
```

## Files to Create (in order)

### 1. lib/theme/app_theme.dart
Full AppTheme class with all colors, gradients, and ThemeData.

### 2. lib/models/food_entry.dart
```dart
class FoodEntry {
  final String id;
  final String name;
  final String emoji;        // auto-assigned based on food type
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String mealType;     // breakfast/lunch/dinner/snack
  final DateTime loggedAt;
  final double confidence;   // AI confidence 0.0-1.0

  // toMap(), fromMap(), copyWith()
}
```

### 3. lib/models/user_profile.dart
```dart
class UserProfile {
  final String uid;
  final String name;
  final int age;
  final double weight;       // kg
  final double height;       // cm
  final String goal;         // lose/maintain/gain
  final int dailyCalorieGoal;
}
```

### 4. lib/services/gemini_vision_service.dart

KEY SERVICE — This is the core of the app.

```dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'dart:convert';

class GeminiVisionService {
  static const _apiKey = 'AIzaSyAsYa0tVqaoLqjHDgpuWoRJQjGm6Psp6To';

  static Future<FoodAnalysis> analyzeFood(File imageFile) async {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
    );

    final imageBytes = await imageFile.readAsBytes();
    final prompt = '''Analyze this food image. Return ONLY a JSON object with no markdown:
{
  "recognized": true,
  "name": "food name",
  "emoji": "food emoji",
  "calories_per_serving": 350,
  "protein_g": 12.5,
  "carbs_g": 45.0,
  "fat_g": 8.0,
  "fiber_g": 3.0,
  "serving_size": "1 portion (~250g)",
  "confidence": 0.92
}
If no food detected: {"recognized": false}''';

    final response = await model.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ])
    ]);

    final text = response.text ?? '{"recognized": false}';
    // Clean JSON (remove markdown if present)
    final clean = text.replaceAll(RegExp(r'```(?:json)?\n?'), '').trim();
    final json = jsonDecode(clean) as Map<String, dynamic>;

    if (json['recognized'] == false) {
      return FoodAnalysis.notRecognized();
    }

    return FoodAnalysis(
      recognized: true,
      name: json['name'] ?? 'Unknown food',
      emoji: json['emoji'] ?? '🍽️',
      calories: (json['calories_per_serving'] as num).toInt(),
      protein: (json['protein_g'] as num).toDouble(),
      carbs: (json['carbs_g'] as num).toDouble(),
      fat: (json['fat_g'] as num).toDouble(),
      fiber: (json['fiber_g'] as num).toDouble(),
      servingSize: json['serving_size'] ?? '1 portion',
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  static Future<String> askDietitian(String message, int dailyGoal, int consumed) async {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.text(
        'You are CalSnap AI dietitian. Daily goal: $dailyGoal kcal. '
        'Consumed today: $consumed kcal. Reply in same language as user. '
        'Be concise (2-3 sentences), motivating, use emojis.',
      ),
    );
    final response = await model.generateContent([Content.text(message)]);
    return response.text ?? 'Sog\'lom ovqatlanishda davom eting! 💪';
  }
}

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
```

### 5. lib/services/revenue_cat_service.dart
Same pattern as CoachMe — isPro getter, initialize(), purchasePro(), restorePurchases().
Use placeholder keys: 'goog_xxx' for Android, 'appl_xxx' for iOS.
Entitlement: 'pro'

### 6. lib/screens/onboarding_screen.dart
3-page PageView:
- Page 1: Big 📸 emoji (animated), "CalSnap'ga xush kelibsiz", subtitle
- Page 2: Name/Age/Weight/Height inputs + Goal chips (Ozish🔥/Saqlash⚖️/Olish💪) + auto BMR calc
- Page 3: Checkmark animation + "Kunlik maqsad: XXX kcal" + "Boshlash" button
Saves to SharedPreferences. Routes to /auth when done.

### 7. lib/screens/login_screen.dart
Email+password login + Google Sign In. Firebase Auth. Dark themed.

### 8. lib/screens/home_screen.dart

Layout:
1. Header: greeting + date
2. HERO: Large CircularPercentIndicator (radius 90)
   - consumed / daily_goal kcal
   - progressColor: neon green
   - Center: calories consumed + "kcal" + remaining text
3. Macro Row: 3 cards (Protein🥩 / Carbs🍞 / Fat🧈) with mini progress bars
4. "Bugungi ovqatlar" section with grouped meal entries
5. Empty state if no entries: show camera FAB hint

Main FAB: large camera button (gradient green, pulsing), navigates to /scan.

Load data from Firestore for current user, today's date.

### 9. lib/screens/scan_screen.dart ← MOST IMPORTANT

States:
1. **READY**: image_picker button (gallery + camera), instruction text, animated scan frame
2. **ANALYZING**: captured image + shimmer loading + "AI tahlil qilmoqda..." + bouncing dots
3. **RESULT**: 
   - Food image (rounded top, full width)
   - Food name (large) + emoji
   - Calorie badge (neon glow, animated scale in)
   - Macro grid: Protein / Carbs / Fat / Fiber
   - Confidence bar
   - Meal type chips (Nonushta/Tushlik/Kechki/Snack)
   - "Qo'shish ✓" button (full width, green gradient)
   - "Qayta surating" ghost button
4. **NOT_RECOGNIZED**: sad emoji, error message, retry button

On "Qo'shish": save FoodEntry to Firestore, show success snackbar, pop back to home.

### 10. lib/screens/log_screen.dart
- Date selector (horizontal scroll, last 7 days)
- Grouped food list by meal type
- Swipe to delete
- Daily total footer
- 28-day heatmap (GitHub style, green shades)

### 11. lib/screens/coach_screen.dart
- Pulsing green AI avatar
- Chat messages
- Typing indicator
- Quick reply chips
- Free limit: 5 msg/day → pro gate

### 12. lib/screens/pro_paywall_screen.dart
- Crown 👑 (amber/orange gradient glow)
- Feature list with ✓ icons
- $3.99/mo price badge
- "7 kunlik bepul sinov" note
- Amber gradient CTA button

### 13. lib/main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try { await RevenueCatService.initialize(); } catch(_) {}
  runApp(const CalSnapApp());
}
```

Routes: /onboarding, /auth, /home, /scan, /log, /coach, /pro
Bottom nav: 🏠 Bosh / 📋 Log / 🤖 Coach / 👤 Profil
FAB: camera button in center of bottom nav

## Android Config
Edit android/app/build.gradle.kts:
- minSdk = 21
- Add: isCoreLibraryDesugaringEnabled = true in compileOptions
- Add dependency: coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

## Rules
1. Write COMPLETE files — every screen fully implemented
2. All screens beautiful with green glassmorphism theme
3. Handle loading states, errors, empty states everywhere
4. Use flutter_animate for entrances
5. Use AppTheme constants, never hardcode colors
6. Run `flutter pub get` after pubspec.yaml
7. Run `flutter analyze --no-fatal-infos` at the end

## When Done
Run: openclaw system event --text "Done: CalSnap built — camera scan + AI calories + all screens complete" --mode now
