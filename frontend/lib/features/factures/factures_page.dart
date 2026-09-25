import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

import '../../core/pdf/facture_pdf_service.dart';
import '../../models/facture.dart';
import 'facture_service.dart';
import 'facture_form_page.dart';
import '../clients/client_service.dart';
import '../paiements/paiement_detail_page.dart';
import '../paiements/paiement_service.dart';

class FacturesPage extends StatefulWidget {
  final int? clientId;
  final int? dossierId;

  const FacturesPage({
    super.key,
    this.clientId,
    this.dossierId,
  });

  @override
  State<FacturesPage> createState() => _FacturesPageState();
}

class _FacturesPageState extends State<FacturesPage> {
  final FactureService _service = FactureService();
  final ClientService _clientService = ClientService();
  final PaiementService _paiementService = PaiementService();
  final TextEditingController _searchController = TextEditingController();

  bool _impressionEnCours = false;

  List<Facture> _factures = [];
  bool _isLoading = true;
  String? _error;
  String _statutFiltre = 'Toutes';
  String _recherche = '';

  final List<String> _filtres = [
    'Toutes',
    'Brouillon',
    'En attente',
    'Payée',
    'Impayée',
    'Annulée',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _recherche = _searchController.text.trim().toLowerCase();
      });
    });
    _loadFactures();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFactures() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final factures = await _service.getFactures(
        clientId: widget.clientId,
        dossierId: widget.dossierId,
      );

      if (!mounted) return;

      setState(() {
        _factures = factures;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Facture> get _facturesFiltrees {
    return _factures.where((facture) {
      final correspondStatut =
          _statutFiltre == 'Toutes' || facture.statut == _statutFiltre;

      final texte =
          '${facture.numero} ${facture.notes ?? ''} ${facture.modePaiement ?? ''}'
              .toLowerCase();

      final correspondRecherche =
          _recherche.isEmpty || texte.contains(_recherche);

      return correspondStatut && correspondRecherche;
    }).toList();
  }

  double get _totalTtc {
    return _factures.fold(
      0,
      (total, facture) => total + (facture.montantTtc ?? 0),
    );
  }

  double get _totalPaye {
    return _factures
        .where((facture) => facture.statut == 'Payée')
        .fold(
          0,
          (total, facture) => total + (facture.montantTtc ?? 0),
        );
  }

  double get _totalImpaye {
    return _factures
        .where((facture) => facture.statut == 'Impayée')
        .fold(
          0,
          (total, facture) => total + (facture.montantTtc ?? 0),
        );
  }

  Future<void> _openForm({Facture? facture}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FactureFormPage(
          clientId: widget.clientId,
          dossierId: widget.dossierId,
          facture: facture,
        ),
      ),
    );

    if (result == true) {
      _loadFactures();
    }
  }

  Future<void> _deleteFacture(Facture facture) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la facture'),
          content: Text(
            'Voulez-vous vraiment supprimer la facture ${facture.numero} ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmation != true) return;

    try {
      await _service.deleteFacture(facture.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Facture supprimée'),
          backgroundColor: Colors.green,
        ),
      );

      _loadFactures();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _statusColor(String statut) {
    switch (statut) {
      case 'Payée':
        return AppColors.success;
      case 'Impayée':
        return AppColors.danger;
      case 'En attente':
        return AppColors.warning;
      case 'Annulée':
        return AppColors.neutral;
      default:
        return AppColors.info;
    }
  }

  String _formatMontant(double montant) {
    return '${montant.toStringAsFixed(0)} FCFA';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBackground,
      appBar: AppBar(
        title: const Text(
          'Factures',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFactures,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle facture'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 150),
          Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Impossible de charger les factures',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton.icon(
              onPressed: _loadFactures,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildSearch(),
        const SizedBox(height: 14),
        _buildFilters(),
        const SizedBox(height: 16),
        if (_facturesFiltrees.isEmpty)
          _buildEmpty()
        else
          ..._facturesFiltrees.map(_buildFactureCard),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF10B981),
            Color(0xFF059669),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(width: 12),
              Text(
                'Gestion des factures',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  'Total',
                  '${_factures.length}',
                  Icons.receipt_rounded,
                ),
              ),
              Expanded(
                child: _buildStat(
                  'Payées',
                  '${_factures.where((f) => f.statut == 'Payée').length}',
                  Icons.check_circle_rounded,
                ),
              ),
              Expanded(
                child: _buildStat(
                  'Impayées',
                  '${_factures.where((f) => f.statut == 'Impayée').length}',
                  Icons.warning_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Total TTC : ${_formatMontant(_totalTtc)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Payé : ${_formatMontant(_totalPaye)}  •  Impayé : ${_formatMontant(_totalImpaye)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 22,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Rechercher une facture...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _recherche.isNotEmpty
            ? IconButton(
                onPressed: _searchController.clear,
                icon: const Icon(Icons.clear_rounded),
              )
            : null,
        filled: true,
        fillColor: context.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filtres.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtre = _filtres[index];
          final selected = _statutFiltre == filtre;

          return ChoiceChip(
            label: Text(filtre),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _statutFiltre = filtre;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildFactureCard(Facture facture) {
    final color = _statusColor(facture.statut);
    final montant = facture.montantTtc ?? facture.montantHt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openForm(facture: facture),
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
                      Icons.receipt_long_rounded,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facture.numero,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Émise le ${_formatDate(facture.dateEmission)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                facture.statut,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _formatMontant(montant),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'modifier') {
                        _openForm(facture: facture);
                      } else if (value == 'paiements') {
                        _openPaiements(facture);
                      } else if (value == 'imprimer') {
                        _printFacture(facture);
                      } else if (value == 'supprimer') {
                        _deleteFacture(facture);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'modifier',
                        child: ListTile(
                          leading: Icon(Icons.edit_rounded),
                          title: Text('Modifier'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'paiements',
                        child: ListTile(
                          leading: Icon(
                            Icons.payments_rounded,
                            color: Colors.teal,
                          ),
                          title: Text('Paiements'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'imprimer',
                        child: ListTile(
                          leading: Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.indigo,
                          ),
                          title: Text('Imprimer la facture'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'supprimer',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                          ),
                          title: Text('Supprimer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openPaiements(facture),
                    icon: const Icon(
                      Icons.payments_rounded,
                      size: 19,
                    ),
                    label: const Text('Paiements'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: BorderSide(
                        color: Colors.teal.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _impressionEnCours
                        ? null
                        : () => _printFacture(facture),
                    icon: const Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 19,
                    ),
                    label: const Text('Imprimer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      side: BorderSide(
                        color: Colors.indigo.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printFacture(Facture facture) async {
    if (_impressionEnCours) return;

    setState(() => _impressionEnCours = true);

    try {
      final client = await _clientService.getClient(facture.clientId);

      Map<String, dynamic>? resume;
      try {
        resume = await _paiementService.getResumeFacture(facture.id);
      } catch (_) {
        resume = null;
      }

      if (!mounted) return;

      await FacturePdfService.printFacture(
        facture: facture,
        client: client,
        resume: resume,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la génération : $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _impressionEnCours = false);
      }
    }
  }

  Future<void> _openPaiements(Facture facture) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaiementDetailPage(
          facture: facture,
        ),
      ),
    );

    if (!mounted) return;

    _loadFactures();
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 70,
            color: context.borderColor,
          ),
          const SizedBox(height: 18),
          Text(
            _recherche.isNotEmpty || _statutFiltre != 'Toutes'
                ? 'Aucune facture trouvée'
                : 'Aucune facture',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première facture avec le bouton ci-dessous.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
