import 'package:flutter/material.dart';

import '../../models/tache.dart';
import 'tache_form_page.dart';
import 'tache_service.dart';

class TachesPage extends StatefulWidget {
  final int dossierId;

  const TachesPage({
    super.key,
    required this.dossierId,
  });

  @override
  State<TachesPage> createState() => _TachesPageState();
}

class _TachesPageState extends State<TachesPage> {
  final TacheService _service = TacheService();
  final TextEditingController _searchController = TextEditingController();

  List<Tache> _taches = [];
  bool _loading = true;
  String? _error;
  String _filter = 'Toutes';

  final List<String> _filters = [
    'Toutes',
    'À faire',
    'En cours',
    'Terminée',
    'Annulée',
  ];

  @override
  void initState() {
    super.initState();
    _loadTaches();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTaches() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final taches = await _service.getTaches(
        dossierId: widget.dossierId,
      );

      if (!mounted) return;

      setState(() {
        _taches = taches;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<Tache> get _filteredTaches {
    final search = _searchController.text.trim().toLowerCase();

    return _taches.where((tache) {
      final matchesFilter =
          _filter == 'Toutes' || tache.statut == _filter;

      final matchesSearch =
          search.isEmpty ||
          tache.titre.toLowerCase().contains(search) ||
          (tache.description?.toLowerCase().contains(search) ?? false);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _createTache() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TacheFormPage(
          dossierId: widget.dossierId,
        ),
      ),
    );

    if (result == true) {
      _loadTaches();
    }
  }

  Future<void> _editTache(Tache tache) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TacheFormPage(
          dossierId: widget.dossierId,
          tache: tache,
        ),
      ),
    );

    if (result == true) {
      _loadTaches();
    }
  }

  Future<void> _deleteTache(Tache tache) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la tâche ?'),
        content: Text(
          'La tâche "${tache.titre}" sera définitivement supprimée.',
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
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteTache(tache.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tâche supprimée'),
        ),
      );

      _loadTaches();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
        ),
      );
    }
  }

  Color _statusColor(String statut) {
    switch (statut) {
      case 'Terminée':
        return Colors.green;
      case 'En cours':
        return Colors.blue;
      case 'Annulée':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color _priorityColor(String priorite) {
    switch (priorite) {
      case 'Urgente':
        return Colors.red;
      case 'Haute':
        return Colors.deepOrange;
      case 'Basse':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTaches;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Tâches',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTache,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Nouvelle tâche'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTaches,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 140),
                      Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 55,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Impossible de charger les tâches',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 30),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _loadTaches,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStats(),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher une tâche...',
                          prefixIcon:
                              const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: _searchController.clear,
                                  icon: const Icon(Icons.clear),
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
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((filter) {
                            final selected = _filter == filter;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(filter),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    _filter = filter;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (filtered.isEmpty)
                        _buildEmptyState()
                      else
                        ...filtered.map(_buildTacheCard),
                      const SizedBox(height: 80),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStats() {
    final enCours =
        _taches.where((t) => t.statut == 'En cours').length;
    final urgentes =
        _taches.where((t) => t.priorite == 'Urgente').length;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Total',
            _taches.length.toString(),
            Icons.task_alt_rounded,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'En cours',
            enCours.toString(),
            Icons.timelapse_rounded,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Urgentes',
            urgentes.toString(),
            Icons.priority_high_rounded,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacheCard(Tache tache) {
    final statusColor = _statusColor(tache.statut);
    final priorityColor = _priorityColor(tache.priorite);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _editTache(tache),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tache.titre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (tache.description != null &&
                        tache.description!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        tache.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _badge(
                          tache.statut,
                          statusColor,
                        ),
                        _badge(
                          tache.priorite,
                          priorityColor,
                        ),
                      ],
                    ),
                    if (tache.dateEcheance != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Échéance : ${_formatDate(tache.dateEcheance!)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editTache(tache);
                  } else if (value == 'delete') {
                    _deleteTache(tache);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Modifier'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer'),
                  ),
                ],
              ),
            ],
          ),
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
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 15),
          const Text(
            'Aucune tâche',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez une tâche pour suivre ce dossier.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
