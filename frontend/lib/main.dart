import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/auth/splash_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/clients/clients_page.dart';
import 'features/clients/client_form_page.dart';
import 'features/clients/client_detail_page.dart';
import 'features/dossiers/dossiers_page.dart';
import 'features/dossiers/dossier_form_page.dart';
import 'features/factures/factures_page.dart';
import 'features/factures/facture_form_page.dart';
import 'features/paiements/paiements_page.dart';
import 'features/paiements/paiement_form_page.dart';
import 'features/notifications/notifications_page.dart';
import 'features/declarations/declarations_page.dart';
import 'features/declarations/admin_declarations_page.dart';
import 'features/users/users_page.dart';
import 'features/comptabilite/comptabilite_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load();
  runApp(const SSConsultingApp());
}

class SSConsultingApp extends StatelessWidget {
  const SSConsultingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SS Consulting',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        initialRoute: '/',
        routes: {
          // ============================================================
          // AUTHENTIFICATION
          // ============================================================
          '/': (context) => const SplashPage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),

          // Dashboard administrateur
          '/dashboard': (context) => const DashboardPage(),
          // Gestion des utilisateurs — administrateur
          '/users': (context) => const UsersPage(),
          '/comptabilite': (context) => const ComptabilitePage(),

          // ============================================================
          // NOTIFICATIONS
          // ============================================================
          '/notifications': (context) => const NotificationsPage(),

          // ============================================================
          // DECLARATIONS FISCALES
          // ============================================================
          '/declarations': (context) => const DeclarationsPage(),

          '/admin-declarations': (context) => const AdminDeclarationsPage(),

          // ============================================================
          // CLIENTS
          // ============================================================
          '/clients': (context) => const ClientsPage(),

          '/clients/create': (context) => const ClientFormPage(),

          '/clients/detail': (context) => ClientDetailPage(
            clientId: ModalRoute.of(context)!.settings.arguments as int,
          ),

          // ============================================================
          // DOSSIERS
          // ============================================================
          '/dossiers': (context) => const DossiersPage(),

          '/dossiers/create': (context) => DossierFormPage(
            clientId: ModalRoute.of(context)?.settings.arguments as int?,
          ),

          // ============================================================
          // FACTURES
          // ============================================================
          '/factures': (context) => const FacturesPage(),

          '/factures/create': (context) {
            final arguments = ModalRoute.of(context)?.settings.arguments;

            int? clientId;
            int? dossierId;

            if (arguments is int) {
              clientId = arguments;
            } else if (arguments is Map) {
              clientId = arguments['clientId'] as int?;
              dossierId = arguments['dossierId'] as int?;
            }

            return FactureFormPage(clientId: clientId, dossierId: dossierId);
          },

          // ============================================================
          // PAIEMENTS
          // ============================================================
          '/paiements': (context) => const PaiementsPage(),

          '/paiements/create': (context) {
            final arguments = ModalRoute.of(context)?.settings.arguments;

            int? factureId;

            if (arguments is int) {
              factureId = arguments;
            } else if (arguments is Map) {
              factureId = arguments['factureId'] as int?;
            }

            return PaiementFormPage(factureId: factureId);
          },
        },
      ),
    );
  }
}
