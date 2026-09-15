import 'package:flutter/material.dart';

import '../../models/dossier.dart';
import 'dossier_service.dart';
import 'dossier_form_page.dart';

class DossiersPage extends StatefulWidget {
  final int? clientId;

  const DossiersPage({
    super.key,
    this.clientId,
  });

  @override
  State<DossiersPage> createState() => _DossiersPageState();
}

class _DossiersPageState extends State<DossiersPage> {
  final DossierService _service = DossierService();

  List<Dossier> _dossiers = [];
  bool _loading = true;
  String? _error;

  String _search = '';
  String _filter = 'Tous';

  @override
  void initState() {
    super.initState();
    _loadDossiers();
  }

  Future<void> _loadDossiers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dossiers = await _service.getDossiers(
        clientId: widget.clientId,
      );

      if (!mounted) return;

      setState(() {
        _dossiers = dossiers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger les dossiers.';
      });
    }
  }

  List<Dossier> get _filteredDossiers {
    return _dossiers.where((dossier) {
      final query = _search.trim().toLowerCase();

      final matchesSearch = query.isEmpty ||
          dossier.titre.toLowerCase().contains(query) ||
          dossier.typeDossier.toLowerCase().contains(query);

      final matchesFilter =
          _filter == 'Tous' || dossier.statut == _filter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _deleteDossier(Dossier dossier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le dossier ?'),
          content: Text(
            'Voulez-vous supprimer « ${dossier.titre} » ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
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

      await _loadDossiers();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dossier supprimé avec succès.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la suppression.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createDossier() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DossierFormPage(
          clientId: widget.clientId,
        ),
      ),
    );

    if (result == true) {
      _loadDossiers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dossiers = _filteredDossiers;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Dossiers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createDossier,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau dossier'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDossiers,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un dossier...',
                prefixIcon: const Icon(Icons.search),
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
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip('Tous'),
                  _filterChip('En cours'),
                  _filterChip('Terminé'),
                  _filterChip('En attente'),
                  _filterChip('Annulé'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(50),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _buildError()
            else if (dossiers.isEmpty)
              _buildEmpty()
            else
              ...dossiers.map(_buildDossierCard),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value) {
    final selected = _filter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(value),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _filter = value;
          });
        },
      ),
    );
  }

  Widget _buildDossierCard(Dossier dossier) {
    final color = _statusColor(dossier.statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.folder_rounded,
                color: color,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dossier.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    dossier.typeDossier,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _badge(
                        dossier.statut,
                        color,
                      ),
                      _badge(
                        dossier.priorite,
                        _priorityColor(dossier.priorite),
                      ),
                    ],
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
                      Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      SizedBox(width: 10),
                      Text('Supprimer'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.all(50),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 60,
            color: Colors.grey,
          ),
          SizedBox(height: 15),
          Text(
            'Aucun dossier',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Créez votre premier dossier.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 55,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: _loadDossiers,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
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
        return Colors.blueGrey;
    }
  }
}
