import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class RapportsPage extends StatefulWidget {
  const RapportsPage({super.key});

  @override
  State<RapportsPage> createState() => _RapportsPageState();
}

class _RapportsPageState extends State<RapportsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ApiClient _apiClient = ApiClient();

  int _annee = DateTime.now().year;

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _rapportAnnuel;
  Map<String, dynamic>? _rapportTva;
  Map<String, dynamic>? _rapportTresorerie;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        _apiClient.dio.get(
          ApiEndpoints.rapportAnnuel,
          queryParameters: {'annee': _annee},
        ),
        _apiClient.dio.get(
          ApiEndpoints.rapportTva,
          queryParameters: {'annee': _annee},
        ),
        _apiClient.dio.get(
          ApiEndpoints.rapportTresorerie,
          queryParameters: {'annee': _annee},
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _rapportAnnuel = Map<String, dynamic>.from(responses[0].data as Map);
        _rapportTva = Map<String, dynamic>.from(responses[1].data as Map);
        _rapportTresorerie = Map<String, dynamic>.from(
          responses[2].data as Map,
        );
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            e.response?.data?['detail']?.toString() ??
            'Impossible de charger les rapports comptables.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Une erreur inattendue est survenue.';
      });
    }
  }

  double _number(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(dynamic value) {
    final amount = _number(value);

    return '${amount.toStringAsFixed(0)} FCFA'.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ' ',
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Rapports comptables',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [_buildYearSelector(), const SizedBox(width: 12)],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3155D9),
          indicatorColor: const Color(0xFF3155D9),
          tabs: const [
            Tab(text: 'Rapport annuel'),
            Tab(text: 'TVA'),
            Tab(text: 'Trésorerie'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildRapportAnnuel(),
                  _buildRapportTva(),
                  _buildRapportTresorerie(),
                ],
              ),
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _annee,
          items: List.generate(5, (index) {
            final year = DateTime.now().year - index;
            return DropdownMenuItem(value: year, child: Text('$year'));
          }),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _annee = value);
            _charger();
          },
        ),
      ),
    );
  }

  Widget _buildRapportAnnuel() {
    final synthese = Map<String, dynamic>.from(
      _rapportAnnuel?['synthese'] ?? {},
    );
    final statistiques = Map<String, dynamic>.from(
      _rapportAnnuel?['statistiques'] ?? {},
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatGrid([
          (
            'Chiffre d\'affaires HT',
            synthese['chiffre_affaires_ht'],
            const Color(0xFF3155D9),
          ),
          (
            'Total facturé TTC',
            synthese['total_factures_ttc'],
            const Color(0xFF3155D9),
          ),
          (
            'Total encaissé',
            synthese['total_encaisse'],
            const Color(0xFF0F9D58),
          ),
          (
            'Créances clients',
            synthese['creances_clients'],
            const Color(0xFFF59E0B),
          ),
          (
            'Dépenses HT',
            synthese['total_depenses_ht'],
            const Color(0xFFEF4444),
          ),
          (
            'Dépenses TTC',
            synthese['total_depenses_ttc'],
            const Color(0xFFEF4444),
          ),
          ('Bénéfice', synthese['benefice'], const Color(0xFF0F9D58)),
          ('Trésorerie', synthese['solde_tresorerie'], const Color(0xFF6C42D9)),
        ]),
        const SizedBox(height: 20),
        _buildInfoCard('Activité de l\'année', [
          ('Factures émises', '${statistiques['nombre_factures'] ?? 0}'),
          ('Paiements reçus', '${statistiques['nombre_paiements'] ?? 0}'),
          ('Dépenses enregistrées', '${statistiques['nombre_depenses'] ?? 0}'),
        ]),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildRapportTva() {
    final totaux = Map<String, dynamic>.from(_rapportTva?['totaux'] ?? {});
    final mensuel = List<dynamic>.from(_rapportTva?['mensuel'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatGrid([
          ('TVA collectée', totaux['tva_collectee'], const Color(0xFF0F9D58)),
          ('TVA déductible', totaux['tva_deductible'], const Color(0xFFEF4444)),
          ('TVA à payer', totaux['tva_a_payer'], const Color(0xFF3155D9)),
        ]),
        const SizedBox(height: 20),
        _buildMonthlyTable(
          mensuel,
          columns: const ['Mois', 'Collectée', 'Déductible', 'À payer'],
          rowBuilder: (item) => [
            _monthName((item['mois'] as num).toInt()),
            _money(item['tva_collectee']),
            _money(item['tva_deductible']),
            _money(item['tva_a_payer']),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildRapportTresorerie() {
    final totaux = Map<String, dynamic>.from(
      _rapportTresorerie?['totaux'] ?? {},
    );
    final mensuel = List<dynamic>.from(_rapportTresorerie?['mensuel'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatGrid([
          ('Encaissements', totaux['encaissements'], const Color(0xFF0F9D58)),
          ('Décaissements', totaux['decaissements'], const Color(0xFFEF4444)),
          ('Solde', totaux['solde'], const Color(0xFF3155D9)),
        ]),
        const SizedBox(height: 20),
        _buildMonthlyTable(
          mensuel,
          columns: const [
            'Mois',
            'Encaiss.',
            'Décaiss.',
            'Variation',
            'Cumulé',
          ],
          rowBuilder: (item) => [
            _monthName((item['mois'] as num).toInt()),
            _money(item['encaissements']),
            _money(item['decaissements']),
            _money(item['variation']),
            _money(item['solde_cumule']),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStatGrid(List<(String, dynamic, Color)> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 700
            ? 4
            : constraints.maxWidth > 450
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.1,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.$1,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _money(item.$2),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: item.$3,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInfoCard(String titre, List<(String, String)> lignes) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final ligne in lignes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ligne.$1, style: TextStyle(color: Colors.grey.shade700)),
                  Text(
                    ligne.$2,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTable(
    List<dynamic> mensuel, {
    required List<String> columns,
    required List<String> Function(Map<String, dynamic>) rowBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F7FB)),
          columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
          rows: mensuel.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            final cells = rowBuilder(map);

            return DataRow(cells: cells.map((c) => DataCell(Text(c))).toList());
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.error_outline_rounded, size: 60, color: Colors.red.shade300),
        const SizedBox(height: 15),
        Center(
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: _charger,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ),
      ],
    );
  }
}
