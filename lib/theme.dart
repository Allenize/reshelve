import 'package:flutter/material.dart';

class AppColors {
  // ── Reshelve Brand Colors ────────────────────────────────────────────────────
  static const primary = Color(0xFF1B8A3A);
  static const accent = Color(0xFF22A045);
  static const accent2 = Color(0xFF2ECC5E);

  // ── Dark Theme Base ──────────────────────────────────────────────────────────
  static const dark = Color(0xFF080E0F);
  static const dark2 = Color(0xFF0C1510);
  static const card = Color(0xFF111C14);
  static const card2 = Color(0xFF172019);
  static const glass = Color(0x0A22A045);
  static const glassBorder = Color(0x1A22A045);
  static const textColor = Color(0xFFE8F5EC);
  static const muted = Color(0xFF5A7060);
  static const muted2 = Color(0xFF8DAB94);

  // ── Status Colors ─────────────────────────────────────────────────────────────
  static const danger = Color(0xFFEF4444);
  static const warn = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.primary,
          surface: AppColors.card,
          background: AppColors.dark,
          error: AppColors.danger,
        ),
        fontFamily: 'DM Sans',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textColor,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xEB080E0F),
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.muted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.glassBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          labelStyle: const TextStyle(
              color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
          hintStyle: const TextStyle(color: AppColors.muted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.textColor),
          bodySmall: TextStyle(color: AppColors.muted2),
        ),
      );
}

const kRadius = Radius.circular(20);
const kRadiusSm = Radius.circular(14);
const kRadiusXs = Radius.circular(10);

// ── Expanded Category System ────────────────────────────────────────────────
const kCategories = [
  // Food Categories
  'Fresh Produce',
  'Meat & Seafood',
  'Dairy & Eggs',
  'Bakery',
  'Frozen Foods',
  'Pantry & Dry Goods',
  'Snacks & Beverages',
  'Deli & Prepared',
  // Non-Food Categories
  'Personal Care',
  'Household & Cleaning',
  'Pet Care',
  // General
  'Others',
];

const Map<String, String> kCategoryEmoji = {
  'Fresh Produce': '🥦',
  'Meat & Seafood': '🥩',
  'Dairy & Eggs': '🥛',
  'Bakery': '🍞',
  'Frozen Foods': '🧊',
  'Pantry & Dry Goods': '🥫',
  'Snacks & Beverages': '🧃',
  'Deli & Prepared': '🥗',
  'Personal Care': '🧴',
  'Household & Cleaning': '🧹',
  'Pet Care': '🐾',
  'Others': '📦',
  // Legacy categories (backwards compat)
  'Beverages': '🥤',
  'Snacks': '🍿',
  'Canned': '🥫',
  'Hygiene': '🧴',
};

const Map<String, IconData> kCategoryIconData = {
  'Fresh Produce': Icons.eco_outlined,
  'Meat & Seafood': Icons.set_meal_outlined,
  'Dairy & Eggs': Icons.egg_outlined,
  'Bakery': Icons.bakery_dining_outlined,
  'Frozen Foods': Icons.ac_unit_outlined,
  'Pantry & Dry Goods': Icons.inventory_2_outlined,
  'Snacks & Beverages': Icons.local_drink_outlined,
  'Deli & Prepared': Icons.restaurant_outlined,
  'Personal Care': Icons.spa_outlined,
  'Household & Cleaning': Icons.cleaning_services_outlined,
  'Pet Care': Icons.pets_outlined,
  'Others': Icons.category_outlined,
  'Beverages': Icons.local_drink_outlined,
  'Snacks': Icons.fastfood_outlined,
  'Canned': Icons.inventory_2_outlined,
  'Hygiene': Icons.spa_outlined,
};

String categoryEmoji(String cat) => kCategoryEmoji[cat] ?? '📦';
IconData categoryIconFor(String cat) => kCategoryIconData[cat] ?? Icons.category_outlined;
