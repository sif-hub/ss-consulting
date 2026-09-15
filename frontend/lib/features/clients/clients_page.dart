import 'package:flutter/material.dart';

import '../../models/client.dart';
import 'client_service.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final ClientService _clientService = ClientService();
  final TextEditingController _searchController = TextEditingController();

  List<Client> _clients = [];
  bool _loading = true;
  String? _error;
  String _filter = 'Tous';

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();

    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final clients = await _clientService.getClients();

      if (!mounted) return;

      setState(() {
        _clients = clients;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger les clients.';
      });
    }
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  List<Client> get _filteredClients {
    final query = _searchController.text.trim().toLowerCase();

    return _clients.where((client) {
      final matchesFilter =
          _filter == 'Tous' || client.typeClient == _filter;

      if (!matchesFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final searchable = [
        client.nomComplet,
        client.email ?? '',
        client.telephone,
        client.ville ?? '',
        client.numeroContribuable ?? '',
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  Future<void> _showCreateClient() async {
    final result = await Navigator.of(context).pushNamed(
      '/clients/create',
    );

    if (result == true) {
      _loadClients();
    }
  }

  Future<void> _showClient(Client client) async {
    await Navigator.of(context).pushNamed(
      '/clients/detail',
      arguments: client.id,
    );

    _loadClients();
  }

  Future<void> _deleteClient(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le client ?'),
          content: Text(
            'Le client « ${client.nomComplet} » sera désactivé.',
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

    if (confirmed != true) {
      return;
    }

    try {
      await _clientService.deleteClient(client.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client supprimé avec succès.'),
        ),
      );

      _loadClients();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de supprimer le client.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = _filteredClients;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3155D9),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.people_alt_rounded),
            SizedBox(width: 10),
            Text(
              'Clients',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateClient,
        backgroundColor: const Color(0xFF3155D9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau client'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadClients,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSearch(),
            const SizedBox(height: 14),
            _buildFilters(),
            const SizedBox(height: 20),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _buildError()
            else if (clients.isEmpty)
              _buildEmpty()
            else
              ...clients.map(_buildClientCard),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3155D9),
            Color(0xFF6C42D9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestion des clients',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_clients.length} client(s) enregistré(s)',
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Rechercher un client...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: _searchController.clear,
                icon: const Icon(Icons.clear_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('Tous'),
          const SizedBox(width: 8),
          _filterChip('Entreprise'),
          const SizedBox(width: 8),
          _filterChip('Particulier'),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _filter == label;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _filter = label;
        });
      },
      selectedColor: const Color(0xFFDDE5FF),
      checkmarkColor: const Color(0xFF3155D9),
    );
  }

  Widget _buildClientCard(Client client) {
    final isEntreprise = client.typeClient == 'Entreprise';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showClient(client),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: isEntreprise
                    ? const Color(0xFFE5E9FF)
                    : const Color(0xFFE5F8F1),
                child: Text(
                  client.initiales,
                  style: TextStyle(
                    color: isEntreprise
                        ? const Color(0xFF3155D9)
                        : const Color(0xFF059669),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.nomComplet,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      client.telephone,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (client.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        client.email!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'detail') {
                    _showClient(client);
                  } else if (value == 'delete') {
                    _deleteClient(client);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'detail',
                    child: Text('Voir les détails'),
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

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 60,
            color: Colors.grey,
          ),
          SizedBox(height: 15),
          Text(
            'Aucun client trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ajoutez votre premier client pour commencer.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 50,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loadClients,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
