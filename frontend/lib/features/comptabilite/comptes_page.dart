import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class ComptesPage extends StatefulWidget {
  const ComptesPage({super.key});

  @override
  State<ComptesPage> createState() => _ComptesPageState();
}

class _ComptesPageState extends State<ComptesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ApiClient _apiClient = ApiClient();

  int _exercice = DateTime.now().year;
  List<Map<String, dynamic>> _comptes = [];

  bool _journalLoading = true;
  String? _journalError;
  List<dynamic> _journalLignes = [];

  bool _grandLivreLoading = true;
  String? _grandLivreError;
  List<dynamic> _grandLivreComptes = [];
  Map<String, dynamic>? _grandLivreFiltreCompte;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chargerComptes();
    _chargerJournal();
    _chargerGrandLivre();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerComptes() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.comptabiliteComptes,
      );

      if (!mounted) return;

      setState(() {
        _comptes = List<dynamic>.from(
          response.data as List,
        ).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (_) {
      // Le plan comptable n'est nécessaire que pour créer une écriture ;
      // les autres onglets restent fonctionnels sans lui.
    }
  }

  Future<void> _chargerJournal() async {
    setState(() {
      _journalLoading = true;
      _journalError = null;
    });

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.comptabiliteJournal,
        queryParameters: {'exercice': _exercice},
      );

      if (!mounted) return;

      setState(() {
        _journalLignes = List<dynamic>.from(response.data as List);
        _journalLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _journalLoading = false;
        _journalError =
            e.response?.data?['detail']?.toString() ??
            'Impossible de charger le journal.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _journalLoading = false;
        _journalError = 'Une erreur inattendue est survenue.';
      });
    }
  }

  Future<void> _chargerGrandLivre() async {
    setState(() {
      _grandLivreLoading = true;
      _grandLivreError = null;
    });

    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.comptabiliteGrandLivre,
        queryParameters: {
          'exercice': _exercice,
          if (_grandLivreFiltreCompte != null)
            'compte': _grandLivreFiltreCompte!['numero'],
        },
      );

      if (!mounted) return;

      setState(() {
        _grandLivreComptes = List<dynamic>.from(response.data as List);
        _grandLivreLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _grandLivreLoading = false;
        _grandLivreError =
            e.response?.data?['detail']?.toString() ??
            'Impossible de charger le grand livre.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _grandLivreLoading = false;
        _grandLivreError = 'Une erreur inattendue est survenue.';
      });
    }
  }

  void _rechargerTout() {
    _chargerJournal();
    _chargerGrandLivre();
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

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _ouvrirNouvelleEcriture() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EcritureFormPage(comptes: _comptes)),
    );

    if (created == true) {
      _rechargerTout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Comptes',
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
            Tab(text: 'Journal'),
            Tab(text: 'Grand livre'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _comptes.isEmpty ? null : _ouvrirNouvelleEcriture,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle écriture'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildJournalTab(), _buildGrandLivreTab()],
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
            return DropdownMenuItem(value: year, child: Text('$year'));
          }),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _exercice = value);
            _rechargerTout();
          },
        ),
      ),
    );
  }

  Widget _buildJournalTab() {
    if (_journalLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_journalError != null) {
      return _buildError(_journalError!, _chargerJournal);
    }

    if (_journalLignes.isEmpty) {
      return _buildEmpty('Aucune écriture validée pour l\'exercice $_exercice');
    }

    return RefreshIndicator(
      onRefresh: _chargerJournal,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF5F7FB),
                ),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Journal')),
                  DataColumn(label: Text('Réf.')),
                  DataColumn(label: Text('Compte')),
                  DataColumn(label: Text('Libellé')),
                  DataColumn(label: Text('Débit'), numeric: true),
                  DataColumn(label: Text('Crédit'), numeric: true),
                ],
                rows: _journalLignes.map((item) {
                  final ligne = Map<String, dynamic>.from(item as Map);

                  return DataRow(
                    cells: [
                      DataCell(Text(_formatDate(ligne['date_ecriture']))),
                      DataCell(Text(ligne['journal']?.toString() ?? '')),
                      DataCell(Text(ligne['reference']?.toString() ?? '')),
                      DataCell(
                        Text(
                          '${ligne['compte_numero']} - ${ligne['compte_libelle']}',
                        ),
                      ),
                      DataCell(
                        Text(
                          (ligne['libelle_ligne'] ?? ligne['libelle_ecriture'])
                                  ?.toString() ??
                              '',
                        ),
                      ),
                      DataCell(Text(_money(ligne['debit']))),
                      DataCell(Text(_money(ligne['credit']))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGrandLivreTab() {
    return RefreshIndicator(
      onRefresh: _chargerGrandLivre,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_comptes.isNotEmpty)
            Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (c) => '${c['numero']} - ${c['libelle']}',
              optionsBuilder: (value) {
                if (value.text.isEmpty) return _comptes;
                final search = value.text.toLowerCase();
                return _comptes.where((c) {
                  return c['numero'].toString().toLowerCase().contains(
                        search,
                      ) ||
                      c['libelle'].toString().toLowerCase().contains(search);
                });
              },
              onSelected: (compte) {
                setState(() => _grandLivreFiltreCompte = compte);
                _chargerGrandLivre();
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Filtrer par compte (numéro ou libellé)...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _grandLivreFiltreCompte != null
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              controller.clear();
                              setState(() => _grandLivreFiltreCompte = null);
                              _chargerGrandLivre();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          if (_grandLivreLoading)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_grandLivreError != null)
            _buildError(_grandLivreError!, _chargerGrandLivre)
          else if (_grandLivreComptes.isEmpty)
            _buildEmpty('Aucun mouvement pour l\'exercice $_exercice')
          else
            ..._grandLivreComptes.map((item) {
              final compte = Map<String, dynamic>.from(item as Map);
              return _buildCompteCard(compte);
            }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCompteCard(Map<String, dynamic> compte) {
    final lignes = List<dynamic>.from(compte['lignes'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(
          '${compte['numero']} — ${compte['libelle']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Débiteur ${_money(compte['solde_debiteur'])}  •  '
          'Créditeur ${_money(compte['solde_crediteur'])}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F7FB)),
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Journal')),
                DataColumn(label: Text('Libellé')),
                DataColumn(label: Text('Débit'), numeric: true),
                DataColumn(label: Text('Crédit'), numeric: true),
                DataColumn(label: Text('Solde'), numeric: true),
              ],
              rows: lignes.map((item) {
                final ligne = Map<String, dynamic>.from(item as Map);
                return DataRow(
                  cells: [
                    DataCell(Text(_formatDate(ligne['date_ecriture']))),
                    DataCell(Text(ligne['journal']?.toString() ?? '')),
                    DataCell(Text(ligne['libelle']?.toString() ?? '')),
                    DataCell(Text(_money(ligne['debit']))),
                    DataCell(Text(_money(ligne['credit']))),
                    DataCell(Text(_money(ligne['solde']))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.menu_book_rounded, size: 70, color: Colors.grey.shade400),
        const SizedBox(height: 15),
        Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message, VoidCallback onRetry) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.error_outline_rounded, size: 60, color: Colors.red.shade300),
        const SizedBox(height: 15),
        Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FORMULAIRE DE CRÉATION D'ÉCRITURE COMPTABLE
// ============================================================

class _LigneEcritureForm {
  Map<String, dynamic>? compte;
  final TextEditingController libelleController = TextEditingController();
  final TextEditingController debitController = TextEditingController();
  final TextEditingController creditController = TextEditingController();

  void dispose() {
    libelleController.dispose();
    debitController.dispose();
    creditController.dispose();
  }
}

class EcritureFormPage extends StatefulWidget {
  final List<Map<String, dynamic>> comptes;

  const EcritureFormPage({super.key, required this.comptes});

  @override
  State<EcritureFormPage> createState() => _EcritureFormPageState();
}

class _EcritureFormPageState extends State<EcritureFormPage> {
  final ApiClient _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();

  final _journalController = TextEditingController(text: 'OD');
  final _referenceController = TextEditingController();
  final _libelleController = TextEditingController();

  DateTime _date = DateTime.now();
  bool _saving = false;

  final List<_LigneEcritureForm> _lignes = [
    _LigneEcritureForm(),
    _LigneEcritureForm(),
  ];

  @override
  void dispose() {
    _journalController.dispose();
    _referenceController.dispose();
    _libelleController.dispose();
    for (final ligne in _lignes) {
      ligne.dispose();
    }
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  double get _totalDebit =>
      _lignes.fold(0, (sum, l) => sum + _parse(l.debitController.text));

  double get _totalCredit =>
      _lignes.fold(0, (sum, l) => sum + _parse(l.creditController.text));

  bool get _equilibree => (_totalDebit - _totalCredit).abs() < 0.01;

  void _ajouterLigne() {
    setState(() => _lignes.add(_LigneEcritureForm()));
  }

  void _supprimerLigne(int index) {
    if (_lignes.length <= 2) return;
    setState(() {
      _lignes[index].dispose();
      _lignes.removeAt(index);
    });
  }

  Future<void> _selectionnerDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_totalDebit <= 0) {
      _erreur('Veuillez saisir au moins une ligne avec un montant.');
      return;
    }

    if (!_equilibree) {
      _erreur(
        'L\'écriture doit être équilibrée '
        '(débit = crédit).',
      );
      return;
    }

    for (final ligne in _lignes) {
      if (ligne.compte == null) {
        _erreur('Chaque ligne doit avoir un compte sélectionné.');
        return;
      }

      final debit = _parse(ligne.debitController.text);
      final credit = _parse(ligne.creditController.text);

      if (debit > 0 && credit > 0) {
        _erreur('Une ligne ne peut pas avoir à la fois un débit et un crédit.');
        return;
      }

      if (debit == 0 && credit == 0) {
        _erreur('Chaque ligne doit avoir un montant au débit ou au crédit.');
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final exercice = _date.year;
      final mois = _date.month;

      final premierJourMois = DateTime(exercice, mois, 1);
      final premierJourMoisSuivant = mois == 12
          ? DateTime(exercice + 1, 1, 1)
          : DateTime(exercice, mois + 1, 1);

      final periodeResponse = await _apiClient.dio.post(
        ApiEndpoints.comptabilitePeriodes,
        data: {
          'exercice': exercice,
          'mois': mois,
          'date_debut': premierJourMois.toIso8601String().split('T').first,
          'date_fin': premierJourMoisSuivant.toIso8601String().split('T').first,
          'statut': 'OUVERTE',
        },
      );

      final periodeId = periodeResponse.data['id'] as int;

      final ecritureResponse = await _apiClient.dio.post(
        ApiEndpoints.comptabiliteEcritures,
        data: {
          'periode_id': periodeId,
          'date_ecriture': _date.toIso8601String(),
          'journal': _journalController.text.trim(),
          'reference': _referenceController.text.trim().isEmpty
              ? null
              : _referenceController.text.trim(),
          'libelle': _libelleController.text.trim(),
          'lignes': _lignes.map((l) {
            return {
              'compte_id': l.compte!['id'],
              'libelle': l.libelleController.text.trim().isEmpty
                  ? null
                  : l.libelleController.text.trim(),
              'debit': _parse(l.debitController.text),
              'credit': _parse(l.creditController.text),
            };
          }).toList(),
        },
      );

      final ecritureId = ecritureResponse.data['id'] as int;

      if (!mounted) return;

      setState(() => _saving = false);

      await _proposerValidation(ecritureId);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _erreur(
        e.response?.data?['detail']?.toString() ??
            'Impossible d\'enregistrer l\'écriture.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _erreur('Une erreur inattendue est survenue.');
    }
  }

  Future<void> _proposerValidation(int ecritureId) async {
    final valider = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Écriture enregistrée'),
        content: const Text(
          'L\'écriture a été créée en brouillon et équilibrée. '
          'Voulez-vous la valider maintenant ? Une fois validée, elle '
          'apparaîtra dans le journal, le grand livre et la balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (valider == true) {
      try {
        await _apiClient.dio.post(ApiEndpoints.validerEcriture(ecritureId));
      } on DioException catch (e) {
        if (!mounted) return;
        _erreur(
          e.response?.data?['detail']?.toString() ??
              'Impossible de valider l\'écriture.',
        );
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _erreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Nouvelle écriture',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectionnerDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        '${_date.day.toString().padLeft(2, '0')}/'
                        '${_date.month.toString().padLeft(2, '0')}/'
                        '${_date.year}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _journalController,
                    decoration: const InputDecoration(
                      labelText: 'Journal (ex : OD, VE, AC, BQ)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Requis'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Référence (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _libelleController,
              decoration: const InputDecoration(
                labelText: 'Libellé de l\'écriture',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lignes d\'écriture',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _ajouterLigne,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Ajouter une ligne'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _lignes.length; i++) _buildLigneCard(i),
            const SizedBox(height: 12),
            _buildTotaux(),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _enregistrer,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enregistrer l\'écriture'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLigneCard(int index) {
    final ligne = _lignes[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Autocomplete<Map<String, dynamic>>(
                  displayStringForOption: (c) =>
                      '${c['numero']} - ${c['libelle']}',
                  optionsBuilder: (value) {
                    if (value.text.isEmpty) return widget.comptes;
                    final search = value.text.toLowerCase();
                    return widget.comptes.where((c) {
                      return c['numero'].toString().toLowerCase().contains(
                            search,
                          ) ||
                          c['libelle'].toString().toLowerCase().contains(
                            search,
                          );
                    });
                  },
                  onSelected: (compte) {
                    setState(() => ligne.compte = compte);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Compte',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    );
                  },
                ),
              ),
              if (_lignes.length > 2)
                IconButton(
                  onPressed: () => _supprimerLigne(index),
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: ligne.libelleController,
            decoration: const InputDecoration(
              labelText: 'Libellé de la ligne (optionnel)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ligne.debitController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Débit',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ligne.creditController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Crédit',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotaux() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _equilibree ? const Color(0xFFE7F6EC) : const Color(0xFFFDEDED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            _equilibree ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: _equilibree ? const Color(0xFF0F9D58) : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Débit : ${_totalDebit.toStringAsFixed(0)} FCFA   •   '
              'Crédit : ${_totalCredit.toStringAsFixed(0)} FCFA'
              '${_equilibree ? '  (équilibrée)' : '  (déséquilibrée)'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
