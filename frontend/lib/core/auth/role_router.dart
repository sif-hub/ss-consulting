import 'package:flutter/material.dart';

import '../../models/utilisateur.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/dashboard/role_dashboard_page.dart';

class RoleRouter {
  const RoleRouter._();

  static Widget dashboardFor(Utilisateur user) {
    switch (user.userRole) {
      case UserRole.administrateur:
        return const DashboardPage();

      case UserRole.managerSecretariat:
        return RoleDashboardPage(
          user: user,
          role: UserRole.managerSecretariat,
        );

      case UserRole.secretaire:
        return RoleDashboardPage(
          user: user,
          role: UserRole.secretaire,
        );

      case UserRole.fiscaliste:
        return RoleDashboardPage(
          user: user,
          role: UserRole.fiscaliste,
        );

      case UserRole.comptable:
        return RoleDashboardPage(
          user: user,
          role: UserRole.comptable,
        );

      case UserRole.client:
        return RoleDashboardPage(
          user: user,
          role: UserRole.client,
        );

      case UserRole.inconnu:
        return const Scaffold(
          body: Center(
            child: Text(
              'Rôle utilisateur non reconnu.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
    }
  }
}
