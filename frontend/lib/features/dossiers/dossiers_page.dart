import 'package:flutter/material.dart';

import '../../models/dossier.dart';
import '../../models/utilisateur.dart';
import '../../core/auth/auth_service.dart';
import 'dossier_form_page.dart';
import 'dossier_detail_page.dart';
import 'dossier_service.dart';

class DossiersPage extends StatefulWidget {
  final int? clientId;

  const DossiersPage({super.key, this.clientId});

  @override
  State<DossiersPage> createState() => _DossiersPageState();
}

class _DossiersPageState extends State<DossiersPage> {
  final DossierService _service = DossierService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<Dossier> _dossiers = [];
  bool _loading = true;
  String _filter = 'Tous';
  String _search = '';

  final List<String> _filters = [
    'Tous',
    'En cours',
    'En attente',
    'Terminé',
    'Annulé',
  ];

  @override
  void initState() {
    super.initState();
    _loadDossiers();

    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDossiers() async {
    setState(() {
      _loading = true;
    });

    try {
      final utilisateur = await _authService.getCurrentUser();

      late final List<Dossier> dossiers;

      if ([
        UserRole.managerSecretariat,
        UserRole.secretaire,
        UserRole.fiscaliste,
        UserRole.comptable,
      ].contains(utilisateur.userRole)) {
        // Collaborateur : uniquement les dossiers qui lui sont affectés.
        dossiers = await _service.getMesDossiers();
      } else {
        // Administrateur / Client.
        dossiers = await _service.getDossiers(clientId: widget.clientId);
      }

      if (!mounted) return;

      setState(() {
        _dossiers = dossiers;
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

  List<Dossier> get _filteredDossiers {
    return _dossiers.where((dossier) {
      final matchesStatus = _filter == 'Tous' || dossier.statut == _filter;

      final matchesSearch =
          dossier.titre.toLowerCase().contains(_search) ||
          dossier.typeDossier.toLowerCase().contains(_search) ||
          (dossier.description?.toLowerCase().contains(_search) ?? false);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  Future<void> _createDossier() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DossierFormPage(clientId: widget.clientId),
      ),
    );

    if (result == true) {
      _loadDossiers();
    }
  }

  Future<void> _deleteDossier(Dossier dossier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le dossier'),
          content: Text(
            'Voulez-vous vraiment supprimer « ${dossier.titre} » ?',
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
      await _service.deleteDossier(dossier.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dossier supprimé avec succès')),
      );

      _loadDossiers();
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
        return Colors.green;
      case 'En attente':
        return Colors.orange;
      case 'Annulé':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Urgente':
        return Colors.red;
      case 'Haute':
        return Colors.orange;
      case 'Basse':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final dossiers = _filteredDossiers;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Dossiers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadDossiers,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createDossier,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau dossier'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDossiers,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un dossier...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.clear_rounded),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];

                  return ChoiceChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (_) {
                      setState(() {
                        _filter = filter;
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (dossiers.isEmpty)
              _buildEmptyState()
            else
              ...dossiers.map(_buildDossierCard),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 90),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              size: 45,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucun dossier',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre premier dossier pour commencer.',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDossierCard(Dossier dossier) {
    final statusColor = _statusColor(dossier.statut);
    final priorityColor = _priorityColor(dossier.priorite);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DossierDetailPage(dossierId: dossier.id),
            ),
          );

          if (result == true) {
            _loadDossiers();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dossier.titre,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          dossier.typeDossier,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteDossier(dossier);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (dossier.description != null &&
                  dossier.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  dossier.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
              ],

              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBadge(dossier.statut, statusColor),
                  _buildBadge(dossier.priorite, priorityColor),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ouvert le ${_formatDate(dossier.dateOuverture)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
