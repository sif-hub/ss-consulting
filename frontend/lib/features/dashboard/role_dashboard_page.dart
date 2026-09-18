import 'package:flutter/material.dart';

import '../../models/utilisateur.dart';
import '../../core/auth/token_storage.dart';
import '../ia/assistant_chat_page.dart';

class RoleDashboardPage extends StatelessWidget {
  final Utilisateur user;
  final UserRole role;

  const RoleDashboardPage({super.key, required this.user, required this.role});

  String get title {
    switch (role) {
      case UserRole.managerSecretariat:
        return 'Tableau de bord — Manager';
      case UserRole.secretaire:
        return 'Tableau de bord — Secrétariat';
      case UserRole.fiscaliste:
        return 'Tableau de bord — Fiscalité';
      case UserRole.comptable:
        return 'Tableau de bord — Comptabilité';
      case UserRole.client:
        return 'Mon espace client';
      default:
        return 'Tableau de bord';
    }
  }

  String get roleDescription {
    switch (role) {
      case UserRole.managerSecretariat:
        return 'Supervision du secrétariat, des clients et du suivi administratif.';
      case UserRole.secretaire:
        return 'Gestion quotidienne des clients, dossiers, factures et paiements.';
      case UserRole.fiscaliste:
        return 'Suivi des dossiers clients et des échéances fiscales.';
      case UserRole.comptable:
        return 'Suivi financier, facturation et règlements des clients.';
      case UserRole.client:
        return 'Accédez à vos dossiers, factures, paiements et notifications.';
      default:
        return 'Bienvenue dans votre espace professionnel SS Consulting.';
    }
  }

  String get sectionTitle {
    switch (role) {
      case UserRole.managerSecretariat:
        return 'Supervision du secrétariat';
      case UserRole.secretaire:
        return 'Gestion administrative';
      case UserRole.fiscaliste:
        return 'Suivi fiscal';
      case UserRole.comptable:
        return 'Suivi financier';
      case UserRole.client:
        return 'Mes services';
      default:
        return 'Votre espace';
    }
  }

  Color get roleColor {
    switch (role) {
      case UserRole.managerSecretariat:
        return const Color(0xFF3155D9);
      case UserRole.secretaire:
        return const Color(0xFF0EA5E9);
      case UserRole.fiscaliste:
        return const Color(0xFF8B5CF6);
      case UserRole.comptable:
        return const Color(0xFF10B981);
      case UserRole.client:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3155D9);
    }
  }

  List<_DashboardAction> get _actions {
    switch (role) {
      case UserRole.managerSecretariat:
        return [
          _DashboardAction(
            title: 'Clients',
            subtitle: 'Gérer les clients',
            icon: Icons.people_alt_rounded,
            route: '/clients',
          ),
          _DashboardAction(
            title: 'Dossiers',
            subtitle: 'Superviser les dossiers',
            icon: Icons.folder_rounded,
            route: '/dossiers',
          ),
          _DashboardAction(
            title: 'Factures',
            subtitle: 'Suivre la facturation',
            icon: Icons.receipt_long_rounded,
            route: '/factures',
          ),
          _DashboardAction(
            title: 'Comptabilité',
            subtitle: 'Suivre la situation financière',
            icon: Icons.account_balance_rounded,
            route: '/comptabilite',
          ),
          _DashboardAction(
            title: 'Paiements',
            subtitle: 'Suivre les règlements',
            icon: Icons.payments_rounded,
            route: '/paiements',
          ),
          _DashboardAction(
            title: 'Notifications',
            subtitle: 'Voir les alertes',
            icon: Icons.notifications_rounded,
            route: '/notifications',
          ),
        ];

      case UserRole.secretaire:
        return [
          _DashboardAction(
            title: 'Clients',
            subtitle: 'Créer et gérer les clients',
            icon: Icons.people_alt_rounded,
            route: '/clients',
          ),
          _DashboardAction(
            title: 'Dossiers',
            subtitle: 'Gérer les dossiers',
            icon: Icons.folder_rounded,
            route: '/dossiers',
          ),
          _DashboardAction(
            title: 'Factures',
            subtitle: 'Gérer les factures',
            icon: Icons.receipt_long_rounded,
            route: '/factures',
          ),
          _DashboardAction(
            title: 'Paiements',
            subtitle: 'Enregistrer les paiements',
            icon: Icons.payments_rounded,
            route: '/paiements',
          ),
          _DashboardAction(
            title: 'Notifications',
            subtitle: 'Voir les alertes',
            icon: Icons.notifications_rounded,
            route: '/notifications',
          ),
        ];

      case UserRole.fiscaliste:
        return [
          _DashboardAction(
            title: 'Clients',
            subtitle: 'Consulter les clients',
            icon: Icons.people_alt_rounded,
            route: '/clients',
          ),
          _DashboardAction(
            title: 'Dossiers',
            subtitle: 'Suivre les dossiers fiscaux',
            icon: Icons.folder_rounded,
            route: '/dossiers',
          ),
          _DashboardAction(
            title: 'Déclarations fiscales',
            subtitle: 'Suivre et traiter les déclarations',
            icon: Icons.assignment_rounded,
            route: '/admin-declarations',
          ),
          _DashboardAction(
            title: 'Notifications',
            subtitle: 'Échéances et alertes fiscales',
            icon: Icons.notifications_active_rounded,
            route: '/notifications',
          ),
        ];

      case UserRole.comptable:
        return [
          _DashboardAction(
            title: 'Mes dossiers',
            subtitle: 'Consulter et modifier mes dossiers affectés',
            icon: Icons.folder_rounded,
            route: '/dossiers',
          ),
          _DashboardAction(
            title: 'Factures',
            subtitle: 'Suivre les factures',
            icon: Icons.receipt_long_rounded,
            route: '/factures',
          ),
          _DashboardAction(
            title: 'Comptabilité',
            subtitle: 'Suivre la situation financière',
            icon: Icons.account_balance_rounded,
            route: '/comptabilite',
          ),
          _DashboardAction(
            title: 'Paiements',
            subtitle: 'Suivre les règlements',
            icon: Icons.payments_rounded,
            route: '/paiements',
          ),
          _DashboardAction(
            title: 'Déclarations',
            subtitle: 'Consulter les déclarations et générer les DSF',
            icon: Icons.assignment_rounded,
            route: '/admin-declarations',
          ),
          _DashboardAction(
            title: 'Clients',
            subtitle: 'Consulter les clients',
            icon: Icons.people_alt_rounded,
            route: '/clients',
          ),
          _DashboardAction(
            title: 'Notifications',
            subtitle: 'Voir les alertes',
            icon: Icons.notifications_rounded,
            route: '/notifications',
          ),
        ];

      case UserRole.client:
        return [
          _DashboardAction(
            title: 'Mes dossiers',
            subtitle: 'Consulter mes dossiers',
            icon: Icons.folder_rounded,
            route: '/dossiers',
          ),
          _DashboardAction(
            title: 'Mes factures',
            subtitle: 'Consulter mes factures',
            icon: Icons.receipt_long_rounded,
            route: '/factures',
          ),
          _DashboardAction(
            title: 'Mes paiements',
            subtitle: 'Consulter mes paiements',
            icon: Icons.payments_rounded,
            route: '/paiements',
          ),
          _DashboardAction(
            title: 'Mes déclarations',
            subtitle: 'Déposer et suivre mes déclarations fiscales',
            icon: Icons.assignment_rounded,
            route: '/declarations',
          ),
          _DashboardAction(
            title: 'Notifications',
            subtitle: 'Voir mes notifications',
            icon: Icons.notifications_rounded,
            route: '/notifications',
          ),
        ];

      default:
        return [];
    }
  }

  Future<void> _logout(BuildContext context) async {
    await TokenStorage().deleteToken();

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3155D9),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.business_center_rounded),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Tooltip(
              message: 'Assistant IA',
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AssistantChatPage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'SS IA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.of(context).pushNamed('/notifications');
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            Text(
              sectionTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              roleDescription,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ..._actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActionCard(context, action),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [roleColor, roleColor.withValues(alpha: 0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              user.prenom.isNotEmpty ? user.prenom[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour ${user.prenom} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  user.roleLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  roleDescription,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, _DashboardAction action) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF3155D9).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(action.icon, color: const Color(0xFF3155D9)),
        ),
        title: Text(
          action.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(action.subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          Navigator.of(context).pushNamed(action.route);
        },
      ),
    );
  }
}

class _DashboardAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const _DashboardAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}
