import 'package:flutter/material.dart';

import '../../core/auth/token_storage.dart';
import '../../models/dashboard_stats.dart';
import 'dashboard_service.dart';
import '../factures/factures_page.dart';
import '../paiements/paiements_page.dart';
import '../depenses/depenses_page.dart';
import '../documents/documents_admin_page.dart';
import '../comptabilite/comptabilite_page.dart';
import '../comptabilite/rapports_page.dart';
import '../notifications/notification_service.dart';
import '../../widgets/notification_badge.dart';
import '../ia/assistant_chat_page.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_mode_button.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardService _dashboardService = DashboardService();
  final NotificationService _notificationService = NotificationService();

  DashboardStats? _stats;
  bool _loading = true;
  int _unreadNotificationCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadNotificationCount();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stats = await _dashboardService.getStats();

      if (!mounted) return;

      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger les statistiques';
      });
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();

      if (!mounted) return;

      setState(() {
        _unreadNotificationCount = count;
      });
    } catch (_) {
      // Le dashboard reste fonctionnel même si le compteur
      // de notifications n'est momentanément pas disponible.
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).pushNamed('/notifications');

    if (!mounted) return;

    await _loadNotificationCount();
  }

  Future<void> _logout() async {
    await TokenStorage().deleteToken();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBackground,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3155D9),
        foregroundColor: Colors.white,

        title: const Row(
          children: [
            Icon(Icons.business_center_rounded),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'SS Consulting',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),

        actions: [
          const ThemeModeButton(),
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

          NotificationBadge(
            count: _unreadNotificationCount,
            onTap: _openNotifications,
          ),

          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _loadStats,
            icon: const Icon(Icons.refresh_rounded),
          ),

          IconButton(
            tooltip: 'Déconnexion',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadStats,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _buildWelcome(),

              const SizedBox(height: 28),

              const Text(
                'Vue d’ensemble',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              if (_loading) const LinearProgressIndicator(),

              if (_error != null) ...[
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3F3),
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                      TextButton(
                        onPressed: _loadStats,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              _buildStatistics(),

              const SizedBox(height: 32),

              const Text(
                'Modules',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              _buildModules(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3155D9), Color(0xFF6C42D9)],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3155D9).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'Bienvenue 👋',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),

          SizedBox(height: 6),

          Text(
            'Tableau de bord',
            style: TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 10),

          Text(
            'Pilotez votre activité, vos clients, '
            'vos dossiers et votre comptabilité.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final stats = _stats;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,

      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),

      childAspectRatio: 1.65,

      children: [
        _StatCard(
          title: 'Clients',
          value: stats?.clients.toString() ?? '0',
          icon: Icons.people_alt_rounded,
          color: const Color(0xFF3155D9),
        ),

        _StatCard(
          title: 'Dossiers',
          value: stats?.dossiers.toString() ?? '0',
          icon: Icons.folder_rounded,
          color: const Color(0xFF8B5CF6),
        ),

        _StatCard(
          title: 'Factures',
          value: stats?.factures.toString() ?? '0',
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFF10B981),
        ),

        _StatCard(
          title: 'Impayés',
          value: stats?.impayes.toString() ?? '0',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildModules() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      children: [
        _DashboardCard(
          icon: Icons.people_alt_rounded,
          title: 'Clients',
          subtitle: 'Gestion des clients',
          color: const Color(0xFF3155D9),
          onTap: () {
            Navigator.pushNamed(context, '/clients');
          },
        ),

        _DashboardCard(
          icon: Icons.folder_rounded,
          title: 'Dossiers',
          subtitle: 'Suivi des dossiers',
          color: const Color(0xFF8B5CF6),
          onTap: () {
            Navigator.pushNamed(context, '/dossiers');
          },
        ),

        _DashboardCard(
          icon: Icons.description_rounded,
          title: 'Documents',
          subtitle: 'Documents administratifs',
          color: const Color(0xFF0EA5E9),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DocumentsAdminPage()),
            );
          },
        ),

        _DashboardCard(
          icon: Icons.assignment_rounded,
          title: 'Déclarations',
          subtitle: 'Déclarations fiscales des clients',
          color: const Color(0xFF2563EB),
          onTap: () {
            Navigator.pushNamed(context, '/admin-declarations');
          },
        ),

        _DashboardCard(
          icon: Icons.receipt_long_rounded,
          title: 'Factures',
          subtitle: 'Gestion de la facturation',
          color: const Color(0xFF10B981),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FacturesPage()),
            );
          },
        ),

        _DashboardCard(
          icon: Icons.payments_rounded,
          title: 'Paiements',
          subtitle: 'Suivi des règlements',
          color: const Color(0xFF14B8A6),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaiementsPage()),
            );
          },
        ),

        _DashboardCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Dépenses',
          subtitle: 'Gestion des dépenses',
          color: const Color(0xFFF59E0B),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DepensesPage()),
            );
          },
        ),

        _DashboardCard(
          icon: Icons.calculate_rounded,
          title: 'Comptabilité',
          subtitle: 'Gestion comptable',
          color: const Color(0xFFEF4444),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComptabilitePage()),
            );
          },
        ),

        _DashboardCard(
          icon: Icons.bar_chart_rounded,
          title: 'Rapports',
          subtitle: 'Rapports et statistiques',
          color: const Color(0xFF6366F1),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RapportsPage()),
            );
          },
        ),

        _DashboardCard(
          icon: Icons.manage_accounts_rounded,
          title: 'Utilisateurs',
          subtitle: 'Gestion des comptes',
          color: const Color(0xFF7C3AED),
          onTap: () {
            Navigator.pushNamed(context, '/users');
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(17),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(icon, color: color, size: 25),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 25),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Ouvrir',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
