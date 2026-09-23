import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';

import '../../models/facture.dart';
import '../../models/paiement.dart';
import 'paiement_service.dart';

class PaiementDetailPage extends StatefulWidget {
  final Facture facture;

  const PaiementDetailPage({
    super.key,
    required this.facture,
  });

  @override
  State<PaiementDetailPage> createState() => _PaiementDetailPageState();
}

class _PaiementDetailPageState extends State<PaiementDetailPage> {
  final PaiementService _service = PaiementService();

  List<Paiement> _paiements = [];
  bool _isLoading = true;
  bool _isPaying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPaiements();
  }

  Future<void> _loadPaiements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final paiements = await _service.getPaiements(
        factureId: widget.facture.id,
      );

      if (!mounted) return;

      setState(() {
        _paiements = paiements;
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

  double get _montantFacture {
    return widget.facture.montantTtc ?? widget.facture.montantHt;
  }

  double get _totalPaye {
    return _paiements
        .where((paiement) =>
            paiement.actif && paiement.statut == 'Validé')
        .fold(
          0,
          (total, paiement) => total + paiement.montant,
        );
  }

  double get _resteAPayer {
    return (_montantFacture - _totalPaye).clamp(0, double.infinity);
  }

  double _montantPourcentage() {
    if (_montantFacture <= 0) return 0;

    return (_totalPaye / _montantFacture)
        .clamp(0, 1)
        .toDouble();
  }

  String _formatMontant(double montant) {
    return '${montant.toStringAsFixed(0)} FCFA';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _statusColor(String statut) {
    switch (statut) {
      case 'Validé':
        return AppColors.success;
      case 'En attente':
        return AppColors.warning;
      case 'Échec':
        return AppColors.danger;
      case 'Annulé':
        return AppColors.neutral;
      case 'Expiré':
        return AppColors.neutral;
      default:
        return AppColors.info;
    }
  }

  Future<void> _payerAvecFapshi() async {
    if (_resteAPayer <= 0) {
      _showMessage(
        'Cette facture est déjà entièrement payée.',
        Colors.green,
      );
      return;
    }

    final montantController = TextEditingController(
      text: _resteAPayer.toStringAsFixed(0),
    );

    final montant = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Paiement Fapshi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reste à payer : ${_formatMontant(_resteAPayer)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: montantController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Montant du paiement',
                  suffixText: 'FCFA',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous pouvez effectuer un paiement partiel.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(
                  montantController.text
                      .trim()
                      .replaceAll(',', '.'),
                );

                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Veuillez saisir un montant valide.',
                      ),
                    ),
                  );
                  return;
                }

                if (value > _resteAPayer) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Le montant ne peut pas dépasser le reste à payer.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Continuer'),
            ),
          ],
        );
      },
    );

    montantController.dispose();

    if (montant == null || !mounted) return;

    setState(() {
      _isPaying = true;
    });

    try {
      final result = await _service.initierPaiementFapshi(
        factureId: widget.facture.id,
        montant: montant,
      );

      if (!mounted) return;

      final uri = Uri.tryParse(result.paymentLink);

      if (uri == null ||
          !(uri.scheme == 'http' || uri.scheme == 'https')) {
        throw Exception(
          'Lien de paiement Fapshi invalide.',
        );
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception(
          'Impossible d’ouvrir la page de paiement Fapshi.',
        );
      }

      if (!mounted) return;

      _showMessage(
        'Paiement initialisé. Finalisez le paiement dans Fapshi, '
        'puis revenez rafraîchir le statut.',
        Colors.orange,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Erreur lors de l’initialisation du paiement : $e',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Widget _buildSummaryCard() {
    final pourcentage = _montantPourcentage();

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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Facture',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.facture.numero,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Montant TTC',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatMontant(_montantFacture),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pourcentage,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.20),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Payé',
                  _formatMontant(_totalPaye),
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Reste',
                  _formatMontant(_resteAPayer),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton() {
    final alreadyPaid = _resteAPayer <= 0;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: alreadyPaid || _isPaying
            ? null
            : _payerAvecFapshi,
        icon: _isPaying
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.payment_rounded),
        label: Text(
          _isPaying
              ? 'Initialisation...'
              : alreadyPaid
                  ? 'Facture entièrement payée'
                  : 'Payer avec Fapshi',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 10),
              const Text(
                'Impossible de charger les paiements',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loadPaiements,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_paiements.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              Text(
                'Aucun paiement enregistré',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _paiements.map(_buildPaymentCard).toList(),
    );
  }

  Widget _buildPaymentCard(Paiement paiement) {
    final color = _statusColor(paiement.statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.payments_rounded,
            color: color,
          ),
        ),
        title: Text(
          _formatMontant(paiement.montant),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              paiement.modePaiement,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            if (paiement.reference != null) ...[
              const SizedBox(height: 3),
              Text(
                paiement.reference!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 3),
            Text(
              _formatDate(paiement.datePaiement),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (paiement.modePaiement == 'Fapshi' &&
                paiement.statut == 'En attente')
              IconButton(
                tooltip: 'Vérifier le statut',
                onPressed: () => _verifierStatutFapshi(paiement),
                icon: const Icon(Icons.refresh_rounded, size: 20),
              ),
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
                paiement.statut,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifierStatutFapshi(Paiement paiement) async {
    try {
      final result = await _service.verifierStatutFapshi(paiement.id);

      if (!mounted) return;

      final statut = result['statut']?.toString() ?? paiement.statut;

      _showMessage(
        statut == 'Validé'
            ? 'Paiement confirmé !'
            : 'Statut Fapshi : $statut',
        statut == 'Validé' ? Colors.green : Colors.orange,
      );

      await _loadPaiements();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Erreur lors de la vérification : $e',
        Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          widget.facture.numero,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadPaiements,
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPaiements,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildPaymentButton(),
            const SizedBox(height: 24),
            const Text(
              'Historique des paiements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentList(),
          ],
        ),
      ),
    );
  }
}
