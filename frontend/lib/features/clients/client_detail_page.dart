import 'package:flutter/material.dart';
import '../../models/client.dart';
import 'client_form_page.dart';
import 'client_service.dart';
import '../../core/pdf/client_pdf_service.dart';
import '../dossiers/dossiers_page.dart';

class ClientDetailPage extends StatefulWidget {
  final int clientId;

  const ClientDetailPage({super.key, required this.clientId});

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  final ClientService _clientService = ClientService();
  Future<void> _generateClientPdf() async {
    if (_client == null) return;

    try {
      await ClientPdfService.printClientSheet(
        client: _client!,
        situation: _situation,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de générer la fiche client : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Client? _client;
  Map<String, dynamic>? _situation;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClient();
  }

  Future<void> _loadClient() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = await _clientService.getClient(widget.clientId);

      Map<String, dynamic>? situation;

      try {
        situation = await _clientService.getSituation(widget.clientId);
      } catch (_) {
        // Les détails du client restent disponibles
        // même si la situation n'est pas encore accessible.
      }

      if (!mounted) return;

      setState(() {
        _client = client;
        _situation = situation;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger les informations du client.';
      });
    }
  }

  Future<void> _editClient() async {
    final client = _client;

    if (client == null) return;

    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ClientFormPage(client: client)));

    if (result == true) {
      _loadClient();
    }
  }

  Future<void> _deleteClient() async {
    final client = _client;

    if (client == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le client ?'),
        content: Text('Le client « ${client.nomComplet} » sera désactivé.'),
        actions: [
          if (_client != null)
            IconButton(
              tooltip: 'Générer la fiche PDF',
              onPressed: _generateClientPdf,
              icon: const Icon(Icons.picture_as_pdf_rounded),
            ),
          if (_client != null)
            IconButton(
              tooltip: 'Modifier',
              onPressed: _editClient,
              icon: const Icon(Icons.edit_rounded),
            ),
          if (_client != null)
            IconButton(
              tooltip: 'Supprimer',
              onPressed: _deleteClient,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _clientService.deleteClient(client.id);

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de supprimer le client.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3155D9),
        foregroundColor: Colors.white,
        title: const Text(
          'Détails du client',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_client != null)
            IconButton(
              tooltip: 'Générer la fiche PDF',
              onPressed: _generateClientPdf,
              icon: const Icon(Icons.picture_as_pdf_rounded),
            ),
          if (_client != null)
            IconButton(
              tooltip: 'Modifier',
              onPressed: _editClient,
              icon: const Icon(Icons.edit_rounded),
            ),
          if (_client != null)
            IconButton(
              tooltip: 'Supprimer',
              onPressed: _deleteClient,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
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
              const Icon(
                Icons.error_outline_rounded,
                size: 55,
                color: Colors.red,
              ),
              const SizedBox(height: 15),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 15),
              FilledButton(
                onPressed: _loadClient,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final client = _client;

    if (client == null) {
      return const Center(child: Text('Client introuvable.'));
    }

    return RefreshIndicator(
      onRefresh: _loadClient,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfile(client),
          const SizedBox(height: 18),
          _buildStatistics(),
          const SizedBox(height: 18),
          _buildContact(client),
          const SizedBox(height: 18),
          _buildAdministrative(client),
          const SizedBox(height: 18),
          _buildFiscalInformation(client),
          const SizedBox(height: 18),
          _buildFinancialSummary(),
          const SizedBox(height: 18),
          _buildModules(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProfile(Client client) {
    final isEntreprise = client.typeClient == 'Entreprise';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3155D9), Color(0xFF6C42D9)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white24,
            child: Text(
              client.initiales,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
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
                  client.nomComplet,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      isEntreprise
                          ? Icons.business_rounded
                          : Icons.person_rounded,
                      color: Colors.white70,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      client.typeClient,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final stats = _situation?['statistiques'];

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: Icons.folder_rounded,
            label: 'Dossiers',
            value: '${stats?['nombre_dossiers'] ?? 0}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            icon: Icons.receipt_long_rounded,
            label: 'Factures',
            value: '${stats?['nombre_factures'] ?? 0}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            icon: Icons.payments_rounded,
            label: 'Paiements',
            value: '${stats?['nombre_paiements'] ?? 0}',
          ),
        ),
      ],
    );
  }

  Widget _buildContact(Client client) {
    return _Section(
      title: 'Coordonnées',
      icon: Icons.contact_phone_rounded,
      children: [
        _InfoRow(
          icon: Icons.phone_rounded,
          label: 'Téléphone',
          value: client.telephone,
        ),
        _InfoRow(
          icon: Icons.email_rounded,
          label: 'Email',
          value: client.email ?? 'Non renseigné',
        ),
        _InfoRow(
          icon: Icons.location_on_rounded,
          label: 'Adresse',
          value: client.adresse ?? 'Non renseignée',
        ),
        _InfoRow(
          icon: Icons.location_city_rounded,
          label: 'Ville',
          value: client.ville ?? 'Non renseignée',
        ),
      ],
    );
  }

  Widget _buildAdministrative(Client client) {
    return _Section(
      title: 'Informations administratives',
      icon: Icons.assignment_rounded,
      children: [
        _InfoRow(
          icon: Icons.badge_rounded,
          label: 'N° contribuable',
          value: client.numeroContribuable ?? 'Non renseigné',
        ),
        _InfoRow(
          icon: Icons.menu_book_rounded,
          label: 'RCCM',
          value: client.registreCommerce ?? 'Non renseigné',
        ),
      ],
    );
  }

  Widget _buildFiscalInformation(Client client) {
    return _Section(
      title: 'Informations fiscales',
      icon: Icons.account_balance_rounded,
      children: [
        _InfoRow(
          icon: Icons.business_center_rounded,
          label: "Secteur d'activité",
          value: client.secteurActivite ?? 'Non renseigné',
        ),
        _InfoRow(
          icon: Icons.account_balance_rounded,
          label: 'Régime fiscal',
          value: client.regimeFiscal ?? 'Non renseigné',
        ),
        _InfoRow(
          icon: Icons.receipt_long_rounded,
          label: 'Assujetti à la TVA',
          value: client.assujettiTva ? 'Oui' : 'Non',
        ),
        _InfoRow(
          icon: Icons.percent_rounded,
          label: 'Marge administrée',
          value: client.margeAdministree ? 'Oui' : 'Non',
        ),
        _InfoRow(
          icon: Icons.location_city_rounded,
          label: 'Commune',
          value: client.commune ?? 'Non renseignée',
        ),
        _InfoRow(
          icon: Icons.location_on_rounded,
          label: 'Quartier',
          value: client.quartier ?? 'Non renseigné',
        ),
        _InfoRow(
          icon: Icons.place_rounded,
          label: 'Lieu-dit',
          value: client.lieuDit ?? 'Non renseigné',
        ),
        _InfoRow(
          icon: Icons.home_work_rounded,
          label: "Statut d'occupation",
          value: client.statutOccupation ?? 'Non renseigné',
        ),
      ],
    );
  }

  Widget _buildFinancialSummary() {
    final factures = _situation?['factures'];

    final total = factures?['total_ttc'] ?? 0;
    final paye = factures?['total_paye'] ?? 0;
    final creance = factures?['creance'] ?? 0;

    return _Section(
      title: 'Situation financière',
      icon: Icons.account_balance_wallet_rounded,
      children: [
        _MoneyRow(label: 'Total facturé', value: total),
        _MoneyRow(label: 'Total payé', value: paye),
        _MoneyRow(label: 'Créance', value: creance, important: true),
      ],
    );
  }

  Widget _buildModules() {
    return _Section(
      title: 'Activité du client',
      icon: Icons.dashboard_customize_rounded,
      children: [
        _ModuleButton(
          icon: Icons.folder_rounded,
          title: 'Dossiers',
          subtitle: 'Voir les dossiers du client',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DossiersPage(clientId: _client!.id),
              ),
            );
          },
        ),
        _ModuleButton(
          icon: Icons.receipt_long_rounded,
          title: 'Factures',
          subtitle: 'Consulter les factures',
          onTap: () {},
        ),
        _ModuleButton(
          icon: Icons.payments_rounded,
          title: 'Paiements',
          subtitle: 'Historique des paiements',
          onTap: () {},
        ),
        _ModuleButton(
          icon: Icons.description_rounded,
          title: 'Documents',
          subtitle: 'Documents associés',
          onTap: () {},
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF3155D9)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 125,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool important;

  const _MoneyRow({
    required this.label,
    required this.value,
    this.important = false,
  });

  @override
  Widget build(BuildContext context) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse('$value') ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${number.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: important ? const Color(0xFFDC2626) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF3155D9)),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ModuleButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModuleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8ECFF),
        child: Icon(icon, color: const Color(0xFF3155D9)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }
}
