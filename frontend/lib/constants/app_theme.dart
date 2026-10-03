import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF0EA5E9); // Electric Cyan/Sky
  static const Color primaryDark = Color(0xFF0284C7);
  static const Color accent = Color(0xFF38BDF8);

  // Backgrounds & Surfaces
  static const Color bgDark = Color(0xFF0B0F19); // Midnight deep
  static const Color bgCard = Color(0xFF1E293B); // Slate 800
  static const Color bgCardHover = Color(0xFF334155); // Slate 700
  static const Color bgInput = Color(0xFF111827); // Dark gray
  static const Color border = Color(0xFF334155);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Status & Priority Colors
  static const Color statusSubmitted = Color(0xFF94A3B8); // Slate
  static const Color statusAssigned = Color(0xFF38BDF8); // Cyan
  static const Color statusInProgress = Color(0xFFF59E0B); // Amber
  static const Color statusResolved = Color(0xFF10B981); // Emerald

  static const Color priorityLow = Color(0xFF10B981); // Emerald
  static const Color priorityMedium = Color(0xFFF59E0B); // Amber
  static const Color priorityHigh = Color(0xFFEF4444); // Crimson/Red

  // Category Colors & Icons
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Pothole':
        return const Color(0xFFF97316); // Orange
      case 'Streetlight':
        return const Color(0xFFFBBF24); // Amber/Yellow
      case 'Garbage':
        return const Color(0xFF10B981); // Green
      case 'Water Leakage':
        return const Color(0xFF06B6D4); // Cyan
      case 'Traffic':
        return const Color(0xFF8B5CF6); // Violet
      default:
        return primary;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Pothole':
        return Icons.warning_amber_rounded;
      case 'Streetlight':
        return Icons.lightbulb_outline_rounded;
      case 'Garbage':
        return Icons.delete_outline_rounded;
      case 'Water Leakage':
        return Icons.water_drop_outlined;
      case 'Traffic':
        return Icons.traffic_rounded;
      default:
        return Icons.report_problem_outlined;
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'SUBMITTED':
        return statusSubmitted;
      case 'ASSIGNED':
        return statusAssigned;
      case 'IN_PROGRESS':
        return statusInProgress;
      case 'RESOLVED':
        return statusResolved;
      default:
        return textSecondary;
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return priorityHigh;
      case 'MEDIUM':
        return priorityMedium;
      case 'LOW':
      default:
        return priorityLow;
    }
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: bgCard,
        background: bgDark,
        error: priorityHigh,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: priorityHigh),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
      ),
    );
  }
}
