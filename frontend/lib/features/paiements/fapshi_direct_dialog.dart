import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import 'paiement_service.dart';

/// Paiement Mobile Money sans quitter l'application : le client saisit
/// son numéro, confirme sur son téléphone, et le statut est suivi ici.
///
/// Renvoie `true` si le paiement est validé, `false` sinon (échec,
/// expiration ou fermeture pendant l'attente).
Future<bool?> showFapshiDirectDialog(
  BuildContext context, {
  required int factureId,
  required double resteAPayer,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _FapshiDirectDialog(factureId: factureId, resteAPayer: resteAPayer),
  );
}

enum _Etape { saisie, attente, succes, echec }

class _FapshiDirectDialog extends StatefulWidget {
  final int factureId;
  final double resteAPayer;

  const _FapshiDirectDialog({
    required this.factureId,
    required this.resteAPayer,
  });

  @override
  State<_FapshiDirectDialog> createState() => _FapshiDirectDialogState();
}

class _FapshiDirectDialogState extends State<_FapshiDirectDialog> {
  static const _delaiMaxAttente = Duration(minutes: 2);
  static const _intervalleSuivi = Duration(seconds: 3);

  final PaiementService _service = PaiementService();
  final _montantController = TextEditingController();
  final _telephoneController = TextEditingController();

  _Etape _etape = _Etape.saisie;
  bool _envoi = false;
  String? _erreurSaisie;
  String? _messageEchec;
  Timer? _suivi;
  DateTime? _debutAttente;
  int? _paiementId;
  double _taux = 0;

  @override
  void initState() {
    super.initState();
    _montantController.text = widget.resteAPayer.toStringAsFixed(0);
    _chargerTaux();
  }

  Future<void> _chargerTaux() async {
    try {
      final taux = await _service.getTauxCommission();

      if (!mounted) return;

      setState(() => _taux = taux);
    } catch (_) {
      // Sans le taux, le détail des frais n'est simplement pas affiché.
    }
  }

  double? get _montantSaisi =>
      double.tryParse(_montantController.text.trim().replaceAll(',', '.'));

  double _commissionSur(double montant) =>
      (montant * _taux / 100).ceilToDouble();

  @override
  void dispose() {
    _suivi?.cancel();
    _montantController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  String _formatMontant(double montant) => '${montant.toStringAsFixed(0)} FCFA';

  Future<void> _payer() async {
    final montant = double.tryParse(
      _montantController.text.trim().replaceAll(',', '.'),
    );
    final telephone = _telephoneController.text.trim();

    if (montant == null || montant <= 0) {
      setState(() => _erreurSaisie = 'Saisissez un montant valide.');
      return;
    }

    if (montant > widget.resteAPayer) {
      setState(() {
        _erreurSaisie = 'Le montant ne peut pas dépasser le reste à payer.';
      });
      return;
    }

    if (telephone.length != 9 || !telephone.startsWith('6')) {
      setState(() {
        _erreurSaisie = 'Numéro invalide : 9 chiffres, ex. 6XXXXXXXX.';
      });
      return;
    }

    setState(() {
      _erreurSaisie = null;
      _envoi = true;
    });

    try {
      final paiementId = await _service.payerDirectFapshi(
        factureId: widget.factureId,
        montant: montant,
        telephone: telephone,
      );

      if (!mounted) return;

      _paiementId = paiementId;
      _debutAttente = DateTime.now();

      setState(() {
        _etape = _Etape.attente;
        _envoi = false;
      });

      _suivi = Timer.periodic(_intervalleSuivi, (_) => _verifier());
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _envoi = false;
        _erreurSaisie = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _verifier() async {
    final paiementId = _paiementId;

    if (paiementId == null) return;

    if (DateTime.now().difference(_debutAttente!) > _delaiMaxAttente) {
      _suivi?.cancel();

      if (!mounted) return;

      setState(() {
        _etape = _Etape.echec;
        _messageEchec =
            'Le délai est dépassé. Si vous avez confirmé sur votre '
            'téléphone, le paiement apparaîtra dans quelques instants '
            'dans la liste (bouton actualiser).';
      });
      return;
    }

    try {
      final result = await _service.verifierStatutFapshi(paiementId);

      if (!mounted) return;

      final statut = result['statut']?.toString();

      if (statut == 'Validé') {
        _suivi?.cancel();
        setState(() => _etape = _Etape.succes);
      } else if (statut == 'Échec' || statut == 'Expiré') {
        _suivi?.cancel();
        setState(() {
          _etape = _Etape.echec;
          _messageEchec = statut == 'Expiré'
              ? 'La demande a expiré. Veuillez réessayer.'
              : 'Le paiement a été refusé ou annulé. Vérifiez votre solde '
                    'et réessayez.';
        });
      }
    } catch (_) {
      // Erreur réseau ponctuelle : on réessaie au prochain passage.
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_etape) {
      case _Etape.saisie:
        return _buildSaisie();
      case _Etape.attente:
        return _buildAttente();
      case _Etape.succes:
        return _buildResultat(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          title: 'Paiement confirmé',
          message: 'Merci ! Votre paiement a bien été reçu.',
          reussi: true,
        );
      case _Etape.echec:
        return _buildResultat(
          icon: Icons.error_rounded,
          color: AppColors.danger,
          title: 'Paiement non abouti',
          message: _messageEchec ?? 'Le paiement n\'a pas pu aboutir.',
          reussi: false,
        );
    }
  }

  Widget _buildSaisie() {
    return AlertDialog(
      title: const Text('Payer par Mobile Money'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reste à payer : ${_formatMontant(widget.resteAPayer)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _montantController,
              onChanged: (_) => setState(() {}),
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
            const SizedBox(height: 14),
            TextField(
              controller: _telephoneController,
              keyboardType: TextInputType.phone,
              maxLength: 9,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Numéro MTN ou Orange Money',
                prefixText: '+237 ',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_taux > 0 && (_montantSaisi ?? 0) > 0) ...[
              const SizedBox(height: 12),
              _buildDetailFrais(_montantSaisi!),
            ],
            const SizedBox(height: 8),
            Text(
              'Vous recevrez une demande de confirmation sur ce numéro. '
              'Un paiement partiel est possible.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            if (_erreurSaisie != null) ...[
              const SizedBox(height: 10),
              Text(
                _erreurSaisie!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _envoi ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _envoi ? null : _payer,
          child: _envoi
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Payer'),
        ),
      ],
    );
  }

  Widget _buildDetailFrais(double montant) {
    final commission = _commissionSur(montant);
    final tauxAffiche = _taux == _taux.roundToDouble()
        ? _taux.toStringAsFixed(0)
        : _taux.toString();

    Widget ligne(String label, String valeur, {bool fort = false}) {
      final style = TextStyle(
        fontWeight: fort ? FontWeight.w700 : FontWeight.w400,
        fontSize: fort ? 15 : 13,
      );

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(valeur, style: style),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.pageBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ligne('Montant de la facture', _formatMontant(montant)),
          const SizedBox(height: 4),
          ligne(
            'Frais de service ($tauxAffiche %)',
            _formatMontant(commission),
          ),
          const Divider(height: 16),
          ligne(
            'Total débité',
            _formatMontant(montant + commission),
            fort: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAttente() {
    return AlertDialog(
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            const Text(
              'Confirmez sur votre téléphone',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Une demande de paiement vient d\'être envoyée au '
              '+237 ${_telephoneController.text}. Validez-la avec votre '
              'code secret pour terminer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _suivi?.cancel();
            Navigator.pop(context, false);
          },
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildResultat({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required bool reussi,
  }) {
    return AlertDialog(
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context, reussi),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
