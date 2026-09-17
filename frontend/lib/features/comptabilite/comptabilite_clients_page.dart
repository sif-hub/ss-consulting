import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/client.dart';
import '../clients/client_service.dart';
import 'balance_page.dart';
import 'comptes_page.dart';

/// Point d'entrée de la comptabilité tenue par le cabinet pour le
/// compte de ses clients — séparée de la comptabilité propre du
/// cabinet (accessible depuis les modules "Comptes"/"Balance" du
/// tableau de bord Comptabilité).
class ComptabiliteClientsPage extends StatefulWidget {
  const ComptabiliteClientsPage({super.key});

  @override
  State<ComptabiliteClientsPage> createState() =>
      _ComptabiliteClientsPageState();
}

class _ComptabiliteClientsPageState extends State<ComptabiliteClientsPage> {
  final ApiClient _apiClient = ApiClient();
  final ClientService _clientService = ClientService();

  bool _loading = true;
  String? _error;
  List<Client> _clients = [];
  Set<int> _clientsInitialises = {};
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final clients = await _clientService.getClients();

      final response = await _apiClient.dio.get(
        ApiEndpoints.comptabiliteClients,
      );

      final initialises = List<dynamic>.from(response.data as List)
          .map((e) => (e as Map)['id'] as int)
          .toSet();

      if (!mounted) return;

      setState(() {
        _clients = clients;
        _clientsInitialises = initialises;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Erreur lors du chargement : $e';
      });
    }
  }

  List<Client> get _clientsFiltres {
    if (_recherche.isEmpty) return _clients;

    final query = _recherche.toLowerCase();

    return _clients.where((client) {
      return client.nomComplet.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _initialiser(Client client) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Initialiser la comptabilité'),
          content: Text(
            'Créer le plan comptable SYSCOHADA complet (126 comptes) '
            'pour ${client.nomComplet} ? Cette comptabilité sera '
            'entièrement séparée de celle du cabinet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Initialiser'),
            ),
          ],
        );
      },
    );

    if (confirme != true) return;

    try {
      await _apiClient.dio.post(
        ApiEndpoints.initialiserComptabiliteClient(client.id),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Comptabilité initialisée pour ${client.nomComplet}.',
          ),
        ),
      );

      await _charger();

      if (!mounted) return;

      _ouvrirMenu(client);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  void _ouvrirMenu(Client client) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  client.nomComplet,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF0F9D58),
                ),
                title: const Text('Comptes (journal & grand livre)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComptesPage(
                        clientId: client.id,
                        clientLabel: client.nomComplet,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.balance_rounded,
                  color: Color(0xFF3155D9),
                ),
                title: const Text('Balance comptable'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BalancePage(
                        clientId: client.id,
                        clientLabel: client.nomComplet,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Comptabilité des clients',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _charger, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF3155D9)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Comptabilité SYSCOHADA tenue par le cabinet pour le '
                    'compte de chaque client, entièrement séparée de celle '
                    'du cabinet.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF1F2937)),
                  ),
                ),
              ],
            ),
          ),
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un client...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => setState(() => _recherche = value.trim()),
          ),
          const SizedBox(height: 14),
          if (_clientsFiltres.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: Text('Aucun client trouvé.')),
            )
          else
            ..._clientsFiltres.map(_buildClientCard),
        ],
      ),
    );
  }

  Widget _buildClientCard(Client client) {
    final initialise = _clientsInitialises.contains(client.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: CircleAvatar(
          backgroundColor: (initialise ? Colors.green : Colors.grey)
              .withValues(alpha: 0.12),
          child: Icon(
            Icons.account_balance_rounded,
            color: initialise ? Colors.green : Colors.grey.shade600,
          ),
        ),
        title: Text(
          client.nomComplet,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          initialise
              ? 'Comptabilité initialisée'
              : 'Comptabilité non initialisée',
          style: TextStyle(
            color: initialise ? Colors.green.shade700 : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: initialise
            ? const Icon(Icons.chevron_right_rounded)
            : TextButton(
                onPressed: () => _initialiser(client),
                child: const Text('Initialiser'),
              ),
        onTap: initialise ? () => _ouvrirMenu(client) : null,
      ),
    );
  }
}
