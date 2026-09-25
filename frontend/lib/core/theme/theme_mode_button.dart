import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Bouton d'apparence : Automatique (thème de l'appareil), Clair, Sombre.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  static IconData _icon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, current, _) {
        return PopupMenuButton<ThemeMode>(
          tooltip: 'Apparence',
          icon: Icon(_icon(current)),
          initialValue: current,
          onSelected: ThemeController.set,
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: ThemeMode.system,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.brightness_auto_rounded),
                title: Text('Automatique (appareil)'),
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.light,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.light_mode_rounded),
                title: Text('Clair'),
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.dark_mode_rounded),
                title: Text('Sombre'),
              ),
            ),
          ],
        );
      },
    );
  }
}
