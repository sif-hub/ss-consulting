import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

import '../../models/paiement.dart';
import 'paiement_service.dart';
import '../../core/pdf/paiement_pdf_service.dart';
import '../factures/facture_service.dart';
import '../clients/client_service.dart';
import 'paiement_form_page.dart';

class PaiementsPage extends StatefulWidget {
  final int? factureId;

  const PaiementsPage({super.key, this.factureId});

  @override
  State<PaiementsPage> createState() => _PaiementsPageState();
}

class _PaiementsPageState extends State<PaiementsPage> {
  final PaiementService _service = PaiementService();
  final FactureService _factureService = FactureService();
  final ClientService _clientService = ClientService();
  final TextEditingController _searchController = TextEditingController();

  List<Paiement> _paiements = [];
  Map<String, dynamic>? _resumeFacture;
  bool _isLoading = true;
  bool _isLoadingResume = false;
  String _selectedStatus = 'Toutes';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPaiements();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPaiements() async {
    setState(() {
      _isLoading = true;
      _isLoadingResume = widget.factureId != null;
    });

    try {
      final paiements = await _service.getPaiements(
        factureId: widget.factureId,
      );

      Map<String, dynamic>? resume;

      if (widget.factureId != null) {
        try {
          resume = await _service.getResumeFacture(widget.factureId!);
        } catch (_) {
          resume = null;
        }
      }

      if (!mounted) return;

      setState(() {
        _paiements = paiements;
        _resumeFacture = resume;
        _isLoading = false;
        _isLoadingResume = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isLoadingResume = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Paiement> get _filteredPaiements {
    return _paiements.where((paiement) {
      final matchesStatus =
          _selectedStatus == 'Toutes' || paiement.statut == _selectedStatus;

      final search = _searchQuery.trim();

      if (search.isEmpty) {
        return matchesStatus;
      }

      final searchableText = [
        paiement.modePaiement,
        paiement.operateur ?? '',
        paiement.transactionId ?? '',
        paiement.reference ?? '',
        paiement.numeroClient ?? '',
        paiement.statut,
      ].join(' ').toLowerCase();

      return matchesStatus && searchableText.contains(search);
    }).toList();
  }

  double get _totalEncaisse {
    return _paiements
        .where((p) => p.statut == 'Validé')
        .fold(0, (sum, p) => sum + p.montant);
  }

  double get _totalCommission {
    return _paiements
        .where((p) => p.statut == 'Validé')
        .fold(0, (sum, p) => sum + p.montantCommission);
  }

  int get _nombreValides {
    return _paiements.where((p) => p.statut == 'Validé').length;
  }

  int get _nombreEnAttente {
    return _paiements.where((p) => p.statut == 'En attente').length;
  }

  String _formatMoney(double value) {
    return '${value.toStringAsFixed(0)} FCFA';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Validé':
        return AppColors.success;
      case 'En attente':
        return AppColors.warning;
      case 'Annulé':
        return AppColors.neutral;
      case 'Échoué':
        return AppColors.danger;
      default:
        return AppColors.info;
    }
  }

  IconData _paymentIcon(String mode) {
    switch (mode) {
      case 'Orange Money':
        return Icons.phone_android_rounded;
      case 'MTN MoMo':
        return Icons.phone_android_rounded;
      case 'Virement bancaire':
        return Icons.account_balance_rounded;
      case 'Chèque':
        return Icons.receipt_long_rounded;
      case 'Carte bancaire':
        return Icons.credit_card_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  Future<void> _deletePaiement(Paiement paiement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le paiement'),
          content: const Text('Voulez-vous vraiment supprimer ce paiement ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.deletePaiement(paiement.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement supprimé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      _loadPaiements();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmerPaiement(Paiement paiement) async {
    try {
      await _service.confirmerPaiementMobile(paiement.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement mobile confirmé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      _loadPaiements();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de confirmation : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaiementFormPage(factureId: widget.factureId),
      ),
    );

    if (result == true) {
      _loadPaiements();
    }
  }

  Future<void> _openEdit(Paiement paiement) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PaiementFormPage(factureId: paiement.factureId, paiement: paiement),
      ),
    );

    if (result == true) {
      _loadPaiements();
    }
  }

  Widget _buildResumeFacture() {
    if (widget.factureId == null) {
      return const SizedBox.shrink();
    }

    if (_isLoadingResume) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final resume = _resumeFacture;

    if (resume == null) {
      return const SizedBox.shrink();
    }

    final montantTtc = (resume['montant_ttc'] as num?)?.toDouble() ?? 0;

    final totalPaye = (resume['total_paye'] as num?)?.toDouble() ?? 0;

    final totalFrais = (resume['total_frais'] as num?)?.toDouble() ?? 0;

    final reste = (resume['reste_a_payer'] as num?)?.toDouble() ?? 0;

    final statut = resume['statut']?.toString() ?? 'Inconnu';

    final numero = resume['numero']?.toString() ?? 'Facture';

    final progression = montantTtc > 0
        ? (totalPaye / montantTtc).clamp(0.0, 1.0)
        : 0.0;

    final statutColor = _statusColor(statut);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade400],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résumé de la facture',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      numero,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.80),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statut,
                  style: TextStyle(
                    color: statutColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _resumeItem(
                  'Montant TTC',
                  _formatMoney(montantTtc),
                  Icons.account_balance_wallet_rounded,
                ),
              ),
              Expanded(
                child: _resumeItem(
                  'Total payé',
                  _formatMoney(totalPaye),
                  Icons.check_circle_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _resumeItem(
                  'Reste à payer',
                  _formatMoney(reste),
                  Icons.pending_actions_rounded,
                ),
              ),
              Expanded(
                child: _resumeItem(
                  'Frais',
                  _formatMoney(totalFrais),
                  Icons.percent_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression du paiement',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              Text(
                '${(progression * 100).toStringAsFixed(0)} %',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progression,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.20),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumeItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.white.withValues(alpha: 0.85)),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPaiements;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.factureId != null ? 'Paiements de la facture' : 'Paiements',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadPaiements,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPaiements,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _buildHeader(),
                  if (widget.factureId != null) ...[
                    const SizedBox(height: 12),
                    _buildResumeFacture(),
                  ],
                  const SizedBox(height: 18),
                  _buildStats(),
                  const SizedBox(height: 18),
                  _buildSearch(),
                  const SizedBox(height: 12),
                  _buildFilters(),
                  const SizedBox(height: 18),
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else
                    ...filtered.map(_buildPaiementCard),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau paiement'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6), Color(0xFF2DD4BF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.factureId != null
                      ? 'Règlements de la facture'
                      : 'Gestion des paiements',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_paiements.length} paiement(s) enregistré(s)',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _statCard(
          title: 'Encaissé',
          value: _formatMoney(_totalEncaisse),
          icon: Icons.account_balance_wallet_rounded,
          color: Colors.green,
        ),
        _statCard(
          title: 'Paiements validés',
          value: '$_nombreValides',
          icon: Icons.check_circle_rounded,
          color: Colors.blue,
        ),
        _statCard(
          title: 'En attente',
          value: '$_nombreEnAttente',
          icon: Icons.pending_actions_rounded,
          color: Colors.orange,
        ),
        _statCard(
          title: 'Commissions',
          value: _formatMoney(_totalCommission),
          icon: Icons.percent_rounded,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
        hintText: 'Rechercher un paiement...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () => _searchController.clear(),
                icon: const Icon(Icons.clear_rounded),
              )
            : null,
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
    const statuses = ['Toutes', 'En attente', 'Validé', 'Annulé', 'Échoué'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((status) {
          final selected = _selectedStatus == status;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: selected,
              label: Text(status),
              onSelected: (_) {
                setState(() {
                  _selectedStatus = status;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _generatePaymentReceipt(Paiement paiement) async {
    try {
      final facture = await _factureService.getFacture(paiement.factureId);
      final client = await _clientService.getClient(facture.clientId);
      Map<String, dynamic>? resume;
      try {
        resume = await _service.getResumeFacture(paiement.factureId);
      } catch (_) {
        resume = null;
      }
      if (mounted == false) return;
      await PaiementPdfService.printReceipt(
        paiement: paiement,
        clientName: client.nomComplet,
        invoiceNumber: facture.numero,
        resume: resume,
      );
    } catch (e) {
      if (mounted == false) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de générer le reçu : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPaiementCard(Paiement paiement) {
    final statusColor = _statusColor(paiement.statut);
    final isMobile =
        paiement.modePaiement == 'Orange Money' ||
        paiement.modePaiement == 'MTN MoMo';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openEdit(paiement),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _paymentIcon(paiement.modePaiement),
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paiement.modePaiement,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          paiement.reference ??
                              paiement.transactionId ??
                              'Paiement #${paiement.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatMoney(paiement.montant),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          paiement.statut,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (paiement.operateur != null)
                    _infoItem(Icons.business_rounded, paiement.operateur!),
                  if (paiement.numeroClient != null) ...[
                    const SizedBox(width: 14),
                    _infoItem(Icons.phone_rounded, paiement.numeroClient!),
                  ],
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'pdf') {
                        _generatePaymentReceipt(paiement);
                      } else if (value == 'edit') {
                        _openEdit(paiement);
                      } else if (value == 'delete') {
                        _deletePaiement(paiement);
                      } else if (value == 'confirm') {
                        _confirmerPaiement(paiement);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'pdf',
                        child: ListTile(
                          leading: Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.teal,
                          ),
                          title: Text('Générer le reçu PDF'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_rounded),
                          title: Text('Modifier'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (isMobile && paiement.statut == 'En attente')
                        const PopupMenuItem(
                          value: 'confirm',
                          child: ListTile(
                            leading: Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                            ),
                            title: Text('Confirmer'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_rounded,
                            color: Colors.red,
                          ),
                          title: Text('Supprimer'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
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
          Icon(Icons.payments_outlined, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Aucun paiement trouvé',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.factureId != null
                ? 'Cette facture ne possède encore aucun paiement.'
                : 'Commencez par enregistrer un paiement.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          if (widget.factureId != null)
            FilledButton.icon(
              onPressed: _openCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter un paiement'),
            ),
        ],
      ),
    );
  }
}
