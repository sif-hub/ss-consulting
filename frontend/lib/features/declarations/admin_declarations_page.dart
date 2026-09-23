import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

import '../../models/declaration.dart';
import '../../models/client.dart';
import '../clients/client_service.dart';
import 'declaration_service.dart';
import 'admin_declaration_detail_page.dart';
import 'declaration_form_page.dart';
import '../../core/auth/auth_service.dart';

class AdminDeclarationsPage extends StatefulWidget {
  const AdminDeclarationsPage({super.key});

  @override
  State<AdminDeclarationsPage> createState() =>
      _AdminDeclarationsPageState();
}

class _AdminDeclarationsPageState
    extends State<AdminDeclarationsPage> {
  final DeclarationService _service = DeclarationService();
  final ClientService _clientService = ClientService();
  final AuthService _authService = AuthService();

  List<Declaration> _declarations = [];
  Map<int, Client> _clients = {};

  bool _loading = true;
  String? _error;
  bool _canCreate = false;

  String _selectedStatus = 'TOUS';

  final List<Map<String, String>> _statuses = const [
    {'value': 'TOUS', 'label': 'Toutes'},
    {'value': 'SOUMISE', 'label': 'Soumises'},
    {'value': 'EN_VERIFICATION', 'label': 'En vérification'},
    {'value': 'VALIDEE', 'label': 'Validées'},
    {'value': 'A_CORRIGER', 'label': 'À corriger'},
    {'value': 'REJETEE', 'label': 'Rejetées'},
    {'value': 'BROUILLON', 'label': 'Brouillons'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDeclarations();
    _checkCreatePermission();
  }

  Future<void> _checkCreatePermission() async {
    try {
      final user = await _authService.getCurrentUser();

      if (!mounted) return;

      setState(() {
        _canCreate = user.roleId == 1;
      });
    } catch (_) {
      // Silencieux : le bouton reste simplement caché.
    }
  }

  Future<void> _loadDeclarations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final declarations = await _service.getDeclarations(
        statut: _selectedStatus == 'TOUS'
            ? null
            : _selectedStatus,
      );

      final clients = await _clientService.getClients();

      final clientsMap = <int, Client>{
        for (final client in clients) client.id: client,
      };

      if (!mounted) return;

      setState(() {
        _declarations = declarations;
        _clients = clientsMap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger les déclarations.';
      });
    }
  }

  Client? _getClient(Declaration declaration) {
    return _clients[declaration.clientId];
  }

  String _clientName(Declaration declaration) {
    final client = _getClient(declaration);

    if (client == null) {
      return _clientName(declaration);
    }

    return client.nomComplet;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'VALIDEE':
        return AppColors.success;

      case 'REJETEE':
        return AppColors.danger;

      case 'A_CORRIGER':
        return AppColors.warning;

      case 'EN_VERIFICATION':
        return AppColors.info;

      case 'SOUMISE':
        return AppColors.pending;

      default:
        return AppColors.neutral;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'VALIDEE':
        return Icons.check_circle;

      case 'REJETEE':
        return Icons.cancel;

      case 'A_CORRIGER':
        return Icons.edit_note;

      case 'EN_VERIFICATION':
        return Icons.search;

      case 'SOUMISE':
        return Icons.send;

      default:
        return Icons.drafts;
    }
  }

  String _formatNumber(double value) {
    return value
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ' ',
        );
  }

  Widget _statusChip(Declaration declaration) {
    final color = _statusColor(declaration.statut);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _statusIcon(declaration.statut),
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            declaration.statutLabel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclarationCard(Declaration declaration) {
    final client = _getClient(declaration);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminDeclarationDetailPage(
                declarationId: declaration.id,
              ),
            ),
          );

          _loadDeclarations();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          declaration.periode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _clientName(declaration),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          client?.telephone ?? 'Téléphone non renseigné',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _statusChip(declaration),
                ],
              ),

              const Divider(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _infoItem(
                      'Chiffre d’affaires',
                      '${_formatNumber(declaration.chiffreAffaires)} FCFA',
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      'Ventes',
                      '${_formatNumber(declaration.totalVentes)} FCFA',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _infoItem(
                      'Achats',
                      '${_formatNumber(declaration.totalAchats)} FCFA',
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      'Employés',
                      '${declaration.nombreEmployes}',
                    ),
                  ),
                ],
              ),

              if (declaration.dateSoumission != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Soumise le ${_formatDate(declaration.dateSoumission!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminDeclarationDetailPage(
                          declarationId: declaration.id,
                        ),
                      ),
                    );

                    _loadDeclarations();
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Consulter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadDeclarations,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_declarations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadDeclarations,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Aucune déclaration trouvée.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeclarations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _declarations.length,
        itemBuilder: (context, index) {
          return _buildDeclarationCard(
            _declarations[index],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Déclarations clients'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadDeclarations,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: !_canCreate
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeclarationFormPage(),
                  ),
                );

                if (created == true) {
                  _loadDeclarations();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouvelle déclaration'),
            ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((status) {
                  final selected =
                      _selectedStatus == status['value'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status['label']!),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedStatus = status['value']!;
                        });
                        _loadDeclarations();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}
