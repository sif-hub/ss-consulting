import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      surface: Colors.white,
      onSurface: const Color(0xFF111827),
      onSurfaceVariant: const Color(0xFF6B7280),
      outlineVariant: const Color(0xFFE5E7EB),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF1B2130),
      onSurface: const Color(0xFFE5E7EB),
      onSurfaceVariant: const Color(0xFF9CA3AF),
      outlineVariant: const Color(0xFF2E3648),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF111623),
    );
  }
}

/// Choix du thème : suit l'appareil par défaut, ou clair / sombre forcé.
/// Le choix est mémorisé sur l'appareil.
class ThemeController {
  ThemeController._();

  static const _key = 'theme_mode';

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);

      mode.value = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      mode.value = ThemeMode.system;
    }
  }

  static Future<void> set(ThemeMode newMode) async {
    mode.value = newMode;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, newMode.name);
    } catch (_) {
      // Le choix reste actif pour la session même s'il n'est pas mémorisé.
    }
  }
}
