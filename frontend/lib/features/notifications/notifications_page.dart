import 'package:flutter/material.dart';

import '../../models/notification.dart';
import 'notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];

  bool _loading = true;
  bool _markingAll = false;

  String _filter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
    });

    try {
      final notifications = await _service.getNotifications(
        nonLues: _filter == 'Non lues',
        type: _typeForFilter(_filter),
      );

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Impossible de charger les notifications : $e',
        isError: true,
      );
    }
  }

  String? _typeForFilter(String filter) {
    switch (filter) {
      case 'Factures':
        return 'FACTURE_ECHEANCE';
      case 'Paiements':
        return 'PAIEMENT_RECU';
      case 'Tâches':
        return 'TACHE_ECHEANCE';
      default:
        return null;
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.lu) return;

    try {
      final updated = await _service.markAsRead(notification.id);

      if (!mounted) return;

      setState(() {
        final index = _notifications.indexWhere(
          (item) => item.id == notification.id,
        );

        if (index != -1) {
          _notifications[index] = updated;
        }
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Impossible de marquer la notification comme lue.',
        isError: true,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    if (_markingAll) return;

    final unread = _notifications.where((item) => !item.lu).length;

    if (unread == 0) {
      _showMessage('Toutes les notifications sont déjà lues.');
      return;
    }

    setState(() {
      _markingAll = true;
    });

    try {
      await _service.markAllAsRead();

      if (!mounted) return;

      setState(() {
        _notifications = _notifications
            .map(
              (notification) => NotificationModel(
                id: notification.id,
                utilisateurId: notification.utilisateurId,
                type: notification.type,
                titre: notification.titre,
                message: notification.message,
                referenceType: notification.referenceType,
                referenceId: notification.referenceId,
                dateEcheance: notification.dateEcheance,
                lu: true,
                dateLecture: DateTime.now(),
                actif: notification.actif,
                createdAt: notification.createdAt,
              ),
            )
            .toList();

        _markingAll = false;
      });

      _showMessage('$unread notification(s) marquée(s) comme lue(s).');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _markingAll = false;
      });

      _showMessage(
        'Impossible de marquer toutes les notifications comme lues.',
        isError: true,
      );
    }
  }

  Future<void> _deleteNotification(
    NotificationModel notification,
  ) async {
    try {
      await _service.deleteNotification(notification.id);

      if (!mounted) return;

      setState(() {
        _notifications.removeWhere(
          (item) => item.id == notification.id,
        );
      });

      _showMessage('Notification supprimée.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Impossible de supprimer la notification.',
        isError: true,
      );
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  int get _unreadCount {
    return _notifications.where((notification) => !notification.lu).length;
  }

  IconData _iconForNotification(String type) {
    switch (type) {
      case 'FACTURE_ECHEANCE':
      case 'FACTURE_ECHUE':
        return Icons.receipt_long_rounded;

      case 'PAIEMENT_RECU':
      case 'PAIEMENT_COMPLET':
        return Icons.payments_rounded;

      case 'TACHE_ECHEANCE':
      case 'TACHE_ECHUE':
        return Icons.task_alt_rounded;

      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForNotification(String type) {
    switch (type) {
      case 'FACTURE_ECHUE':
      case 'TACHE_ECHUE':
        return Colors.red;

      case 'FACTURE_ECHEANCE':
      case 'TACHE_ECHEANCE':
        return Colors.orange;

      case 'PAIEMENT_RECU':
      case 'PAIEMENT_COMPLET':
        return Colors.green;

      default:
        return Colors.teal;
    }
  }

  String _labelForNotification(String type) {
    switch (type) {
      case 'FACTURE_ECHEANCE':
        return 'Échéance facture';

      case 'FACTURE_ECHUE':
        return 'Facture échue';

      case 'PAIEMENT_RECU':
        return 'Paiement reçu';

      case 'PAIEMENT_COMPLET':
        return 'Paiement complet';

      case 'TACHE_ECHEANCE':
        return 'Échéance tâche';

      case 'TACHE_ECHUE':
        return 'Tâche échue';

      default:
        return 'Notification';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l’instant';
    }

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    }

    if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    }

    if (difference.inDays == 1) {
      return 'Hier';
    }

    if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (_unreadCount > 0)
            IconButton(
              tooltip: 'Tout marquer comme lu',
              onPressed: _markingAll ? null : _markAllAsRead,
              icon: _markingAll
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.done_all_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    const filters = [
      'Toutes',
      'Non lues',
      'Factures',
      'Paiements',
      'Tâches',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final selected = _filter == filter;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: selected,
                label: Text(filter),
                onSelected: (_) {
                  if (_filter == filter) return;

                  setState(() {
                    _filter = filter;
                  });

                  _loadNotifications();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Aucune notification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Vous êtes à jour.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _buildNotificationCard(
            _notifications[index],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationModel notification,
  ) {
    final color = _colorForNotification(notification.type);
    final icon = _iconForNotification(notification.type);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _deleteNotification(notification);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
        ),
      ),
      child: Material(
        color: notification.lu
            ? Colors.white
            : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _markAsRead(notification),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notification.lu
                    ? Colors.grey.shade200
                    : color.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIconContainer(
                  icon,
                  color,
                  notification.lu,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.titre,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notification.lu
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!notification.lu)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _labelForNotification(
                                notification.type,
                              ),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _formatDate(notification.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  tooltip: 'Actions',
                  onSelected: (value) {
                    if (value == 'read') {
                      _markAsRead(notification);
                    } else if (value == 'delete') {
                      _deleteNotification(notification);
                    }
                  },
                  itemBuilder: (_) => [
                    if (!notification.lu)
                      const PopupMenuItem(
                        value: 'read',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.mark_email_read_rounded,
                          ),
                          title: Text('Marquer comme lue'),
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                        title: Text('Supprimer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(
    IconData icon,
    Color color,
    bool read,
  ) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: read ? 0.08 : 0.14,
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: color,
        size: 23,
      ),
    );
  }
}
