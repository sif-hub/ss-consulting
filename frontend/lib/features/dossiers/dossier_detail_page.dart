import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

import '../../models/dossier.dart';
import '../../models/utilisateur.dart';
import '../../models/client.dart';
import '../clients/client_service.dart';
import 'dossier_form_page.dart';
import 'dossier_service.dart';
import '../users/user_service.dart';
import '../documents/documents_page.dart';
import '../taches/taches_page.dart';
import '../factures/factures_page.dart';

class DossierDetailPage extends StatefulWidget {
  final int dossierId;

  const DossierDetailPage({super.key, required this.dossierId});

  @override
  State<DossierDetailPage> createState() => _DossierDetailPageState();
}

class _DossierDetailPageState extends State<DossierDetailPage> {
  final DossierService _dossierService = DossierService();
  final UserService _userService = UserService();
  final ClientService _clientService = ClientService();

  Dossier? _dossier;
  Client? _client;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final dossier = await _dossierService.getDossier(widget.dossierId);

      Client? client;

      try {
        client = await _clientService.getClient(dossier.clientId);
      } catch (_) {
        client = null;
      }

      if (!mounted) return;

      setState(() {
        _dossier = dossier;
        _client = client;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editDossier() async {
    final dossier = _dossier;

    if (dossier == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DossierFormPage(dossier: dossier)),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _affecterCollaborateur() async {
    final dossier = _dossier;

    if (dossier == null) return;

    try {
      final utilisateurs = await _userService.getUsers(actif: true);

      final collaborateurs = utilisateurs
          .where((user) => [2, 3, 4, 5].contains(user.roleId))
          .toList();

      if (!mounted) return;

      final selectedId = await showDialog<int>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Affecter un collaborateur',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 500,
              child: collaborateurs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Aucun collaborateur actif disponible.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: collaborateurs.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = collaborateurs[index];

                        final selected = user.id == dossier.collaborateurId;

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              '${user.prenom.isNotEmpty ? user.prenom[0] : ''}'
                                      '${user.nom.isNotEmpty ? user.nom[0] : ''}'
                                  .toUpperCase(),
                            ),
                          ),
                          title: Text(
                            user.nomComplet,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(user.roleLabel),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(context, user.id);
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      );

      if (selectedId == null) return;

      await _dossierService.affecterDossier(dossier.id, selectedId);

      if (!mounted) return;

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collaborateur affecté avec succès.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l’affectation : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _desaffecterCollaborateur() async {
    final dossier = _dossier;

    if (dossier == null || dossier.collaborateurId == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Désaffecter le collaborateur'),
          content: const Text(
            'Voulez-vous retirer le collaborateur affecté à ce dossier ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Désaffecter'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _dossierService.desaffecterDossier(dossier.id);

      if (!mounted) return;

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collaborateur désaffecté avec succès.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la désaffectation : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteDossier() async {
    final dossier = _dossier;

    if (dossier == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le dossier'),
          content: Text(
            'Voulez-vous vraiment supprimer '
            '« ${dossier.titre} » ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _dossierService.deleteDossier(dossier.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dossier supprimé avec succès')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Terminé':
        return AppColors.success;
      case 'En attente':
        return AppColors.warning;
      case 'Annulé':
        return AppColors.danger;
      default:
        return AppColors.info;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Urgente':
        return AppColors.priorityUrgent;
      case 'Haute':
        return AppColors.priorityHigh;
      case 'Basse':
        return AppColors.priorityLow;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Non définie';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Détail du dossier',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_loading && _dossier != null)
            IconButton(
              tooltip: 'Modifier',
              onPressed: _editDossier,
              icon: const Icon(Icons.edit_rounded),
            ),
          if (!_loading && _dossier != null)
            IconButton(
              tooltip: 'Supprimer',
              onPressed: _deleteDossier,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _dossier == null
          ? _buildError()
          : RefreshIndicator(onRefresh: _loadData, child: _buildContent()),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Impossible de charger le dossier',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Utilisateur?> _getCollaborateur(int? collaborateurId) async {
    if (collaborateurId == null) return null;

    try {
      final utilisateurs = await _userService.getUsers(actif: true);

      for (final utilisateur in utilisateurs) {
        if (utilisateur.id == collaborateurId) {
          return utilisateur;
        }
      }
    } catch (_) {}

    return null;
  }

  Widget _buildContent() {
    final dossier = _dossier!;
    final statusColor = _statusColor(dossier.statut);
    final priorityColor = _priorityColor(dossier.priorite);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(dossier, statusColor, priorityColor),
        const SizedBox(height: 18),

        _buildSection(
          title: 'Informations générales',
          icon: Icons.info_outline_rounded,
          children: [
            _buildInfoRow(
              Icons.category_outlined,
              'Type de dossier',
              dossier.typeDossier,
            ),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Date d’ouverture',
              _formatDate(dossier.dateOuverture),
            ),
            _buildInfoRow(
              Icons.event_available_outlined,
              'Date de clôture',
              _formatDate(dossier.dateCloture),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildSection(
          title: 'Client',
          icon: Icons.person_outline_rounded,
          children: [
            if (_client != null) ...[
              _buildInfoRow(
                Icons.business_outlined,
                'Client',
                _client!.nomComplet,
              ),
              if (_client!.telephone.isNotEmpty)
                _buildInfoRow(
                  Icons.phone_outlined,
                  'Téléphone',
                  _client!.telephone,
                ),
              if (_client!.email != null && _client!.email!.isNotEmpty)
                _buildInfoRow(Icons.email_outlined, 'Email', _client!.email!),
            ] else
              _buildInfoRow(
                Icons.person_off_outlined,
                'Client',
                'Client #${dossier.clientId}',
              ),
          ],
        ),

        const SizedBox(height: 16),

        FutureBuilder<Utilisateur?>(
          future: _getCollaborateur(dossier.collaborateurId),
          builder: (context, snapshot) {
            final collaborateur = snapshot.data;

            return _buildSection(
              title: 'Collaborateur',
              icon: Icons.badge_outlined,
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (dossier.collaborateurId == null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.person_off_outlined,
                        'Collaborateur',
                        'Aucun collaborateur affecté',
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _affecterCollaborateur,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Affecter un collaborateur'),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (collaborateur != null) ...[
                        _buildInfoRow(
                          Icons.person_outline_rounded,
                          'Nom',
                          collaborateur.nomComplet,
                        ),
                        _buildInfoRow(
                          Icons.work_outline_rounded,
                          'Fonction',
                          collaborateur.roleLabel,
                        ),
                        if (collaborateur.email.isNotEmpty)
                          _buildInfoRow(
                            Icons.email_outlined,
                            'Email',
                            collaborateur.email,
                          ),
                        if (collaborateur.telephone != null &&
                            collaborateur.telephone!.isNotEmpty)
                          _buildInfoRow(
                            Icons.phone_outlined,
                            'Téléphone',
                            collaborateur.telephone!,
                          ),
                      ] else
                        _buildInfoRow(
                          Icons.person_outline_rounded,
                          'Collaborateur',
                          'Collaborateur #${dossier.collaborateurId}',
                        ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _affecterCollaborateur,
                            icon: const Icon(Icons.swap_horiz_rounded),
                            label: const Text('Changer'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _desaffecterCollaborateur,
                            icon: const Icon(
                              Icons.person_remove_outlined,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Désaffecter',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        if (dossier.description != null &&
            dossier.description!.trim().isNotEmpty)
          _buildSection(
            title: 'Description',
            icon: Icons.notes_rounded,
            children: [
              Text(
                dossier.description!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),

        _buildModulesSection(),

        const SizedBox(height: 20),

        FilledButton.icon(
          onPressed: _editDossier,
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Modifier le dossier'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: _deleteDossier,
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          label: const Text(
            'Supprimer le dossier',
            style: TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildHeader(Dossier dossier, Color statusColor, Color priorityColor) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3155D9), Color(0xFF5B7CFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.folder_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            dossier.titre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dossier.typeDossier,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _headerBadge(dossier.statut, statusColor),
              _headerBadge(dossier.priorite, priorityColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesSection() {
    return _buildSection(
      title: 'Espace de travail',
      icon: Icons.work_outline_rounded,
      children: [
        _buildModuleTile(
          icon: Icons.description_rounded,
          title: 'Documents',
          subtitle: 'Documents liés à ce dossier',
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DocumentsPage(dossierId: _dossier!.id),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildModuleTile(
          icon: Icons.task_alt_rounded,
          title: 'Tâches',
          subtitle: 'Tâches et suivi du dossier',
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TachesPage(dossierId: widget.dossierId),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildModuleTile(
          icon: Icons.receipt_long_rounded,
          title: 'Factures',
          subtitle: 'Factures associées',
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FacturesPage(dossierId: widget.dossierId),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildModuleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
