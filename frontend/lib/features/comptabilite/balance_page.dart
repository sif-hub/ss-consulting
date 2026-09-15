import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  final ApiClient _apiClient = ApiClient();

  bool _loading = true;
  String? _error;
  int _exercice = DateTime.now().year;

  Map<String, dynamic>? _balance;

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
      final response = await _apiClient.dio.get(
        ApiEndpoints.comptabiliteBalance,
        queryParameters: {'exercice': _exercice},
      );

      if (!mounted) return;

      setState(() {
        _balance = Map<String, dynamic>.from(response.data as Map);
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            e.response?.data?['detail']?.toString() ??
            'Impossible de charger la balance comptable.';
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

  @override
  Widget build(BuildContext context) {
    final comptes = List<dynamic>.from(_balance?['comptes'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Balance comptable',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [_buildYearSelector(), const SizedBox(width: 12)],
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError()
            : comptes.isEmpty
            ? _buildEmpty()
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildTotaux(),
                  const SizedBox(height: 20),
                  _buildTable(comptes),
                  const SizedBox(height: 40),
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
          value: _exercice,
          items: List.generate(5, (index) {
            final year = DateTime.now().year - index;
            return DropdownMenuItem(value: year, child: Text('Exercice $year'));
          }),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _exercice = value);
            _charger();
          },
        ),
      ),
    );
  }

  Widget _buildTotaux() {
    final totalDebit = _number(_balance?['total_debit']);
    final totalCredit = _number(_balance?['total_credit']);
    final soldeDebiteur = _number(_balance?['total_solde_debiteur']);
    final soldeCrediteur = _number(_balance?['total_solde_crediteur']);

    final equilibree = (totalDebit - totalCredit).abs() < 0.01;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3155D9), Color(0xFF6C42D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.balance_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Exercice $_exercice',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  equilibree ? 'ÉQUILIBRÉE' : 'DÉSÉQUILIBRÉE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            runSpacing: 12,
            children: [
              _buildTotalItem('Total débit', totalDebit),
              _buildTotalItem('Total crédit', totalCredit),
              _buildTotalItem('Solde débiteur', soldeDebiteur),
              _buildTotalItem('Solde créditeur', soldeCrediteur),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String label, double value) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _money(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<dynamic> comptes) {
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
          columns: const [
            DataColumn(label: Text('N°')),
            DataColumn(label: Text('Compte')),
            DataColumn(label: Text('Débit'), numeric: true),
            DataColumn(label: Text('Crédit'), numeric: true),
            DataColumn(label: Text('Solde débiteur'), numeric: true),
            DataColumn(label: Text('Solde créditeur'), numeric: true),
          ],
          rows: comptes.map((item) {
            final compte = Map<String, dynamic>.from(item as Map);

            return DataRow(
              cells: [
                DataCell(Text(compte['numero']?.toString() ?? '')),
                DataCell(Text(compte['libelle']?.toString() ?? '')),
                DataCell(Text(_money(compte['total_debit']))),
                DataCell(Text(_money(compte['total_credit']))),
                DataCell(Text(_money(compte['solde_debiteur']))),
                DataCell(Text(_money(compte['solde_crediteur']))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.balance_rounded, size: 70, color: Colors.grey.shade400),
        const SizedBox(height: 15),
        const Center(
          child: Text(
            'Aucune écriture validée sur cet exercice',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
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
