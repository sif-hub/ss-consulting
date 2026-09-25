import 'package:flutter/material.dart';

/// Palette centralisée de l'application.
///
/// Avant ce fichier, chaque page définissait sa propre fonction
/// `_statusColor`/`_priorityColor` avec les mêmes couleurs Material
/// codées en dur (Colors.green, Colors.red...), dupliquées dans une
/// dizaine de fichiers. Les widgets doivent utiliser ces constantes
/// plutôt que `Colors.xxx` directement pour tout ce qui a une
/// signification (statut, priorité, marque).
class AppColors {
  AppColors._();

  // ------------------------------------------------------------
  // Marque
  // ------------------------------------------------------------

  static const Color primary = Colors.blue;

  // ------------------------------------------------------------
  // Statuts génériques (déclarations, factures, paiements,
  // dossiers, tâches...)
  // ------------------------------------------------------------

  /// Validé / terminé / payé / succès.
  static const Color success = Colors.green;

  /// Rejeté / échoué / impayé / erreur.
  static const Color danger = Colors.red;

  /// En attente / à corriger / avertissement.
  static const Color warning = Colors.orange;

  /// En cours de traitement / information.
  static const Color info = Colors.blue;

  /// Soumis / en file d'attente.
  static const Color pending = Colors.indigo;

  /// Annulé / brouillon / neutre.
  static const Color neutral = Colors.grey;

  // ------------------------------------------------------------
  // Priorités
  // ------------------------------------------------------------

  static const Color priorityUrgent = Colors.red;
  static const Color priorityHigh = Colors.orange;
  static const Color priorityHighAlt = Colors.deepOrange;
  static const Color priorityLow = Colors.green;
}

/// Couleurs de surface qui suivent le thème clair/sombre. À utiliser à la
/// place de `Colors.white`, `Color(0xFFF5F7FB)`, etc. pour tout fond,
/// texte principal ou bordure.
extension AppThemeContext on BuildContext {
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get pageBackground => Theme.of(this).scaffoldBackgroundColor;
  Color get textPrimary => Theme.of(this).colorScheme.onSurface;
  Color get textMuted => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get borderColor => Theme.of(this).colorScheme.outlineVariant;
}
