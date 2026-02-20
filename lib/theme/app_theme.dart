import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background   = Color(0xFF0A0F0A);
  static const Color surface      = Color(0xFF111A11);
  static const Color card         = Color(0xFF182018);
  static const Color primary      = Color(0xFF10B981);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color secondary    = Color(0xFF6EE7B7);
  static const Color accent       = Color(0xFFF59E0B);
  static const Color neon         = Color(0xFF00FF88);
  static const Color textColor    = Color(0xFFF0FDF4);
  static const Color muted        = Color(0xFF4B7055);
  static const Color mutedLight   = Color(0xFF86EFAC);
  static const Color success      = Color(0xFF10B981);
  static const Color danger       = Color(0xFFEF4444);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color cardBorder   = Color(0xFF1F3024);
  static const Color glassBorder  = Color(0x3310B981);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF065F46)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFF00FF88), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0A0F0A), Color(0xFF111A11), Color(0xFF0A0F0A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: card,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
        .apply(bodyColor: textColor, displayColor: textColor),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        color: textColor, fontSize: 22, fontWeight: FontWeight.w800,
      ),
      iconTheme: const IconThemeData(color: textColor),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: muted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      hintStyle: const TextStyle(color: muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
  );
}
