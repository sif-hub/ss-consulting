import 'package:flutter/material.dart';

import '../../models/paiement.dart';
import '../../models/facture.dart';
import '../factures/facture_service.dart';
import 'paiement_service.dart';

class PaiementFormPage extends StatefulWidget {
  final int? factureId;
  final Paiement? paiement;

  const PaiementFormPage({
    super.key,
    this.factureId,
    this.paiement,
  });

  bool get isEditing => paiement != null;


  @override
  State<PaiementFormPage> createState() => _PaiementFormPageState();
}

class _PaiementFormPageState extends State<PaiementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final PaiementService _service = PaiementService();
  final FactureService _factureService = FactureService();

  List<Facture> _factures = [];
  int? _selectedFactureId;
  bool _isLoadingFactures = false;
  Map<String, dynamic>? _resumeFacture;
  bool _isLoadingResume = false;

  late final TextEditingController _montantController;
  late final TextEditingController _operateurController;
  late final TextEditingController _transactionController;
  late final TextEditingController _numeroClientController;
  late final TextEditingController _fraisController;
  late final TextEditingController _referenceController;
  late final TextEditingController _notesController;

  String _modePaiement = 'Espèces';
  String _statut = 'En attente';
  DateTime _datePaiement = DateTime.now();

  bool _isLoading = false;

  final List<String> _modesPaiement = [
    'Espèces',
    'Virement bancaire',
    'Chèque',
    'Carte bancaire',
    'Orange Money',
    'MTN MoMo',
  ];

  final List<String> _statuts = [
    'En attente',
    'Validé',
    'Échoué',
    'Annulé',
  ];

  bool get _isMobilePayment =>
      _modePaiement == 'Orange Money' || _modePaiement == 'MTN MoMo';

  double get _montant {
    return double.tryParse(
          _montantController.text.replaceAll(',', '.'),
        ) ??
        0;
  }

  double get _commission {
    return _montant * 2 / 100;
  }

  double get _total {
    return _montant + _commission;
  }

  Future<void> _loadResumeFacture(int factureId) async {
    setState(() {
      _isLoadingResume = true;
      _resumeFacture = null;
    });

    try {
      final resume = await _service.getResumeFacture(factureId);

      if (!mounted) return;

      setState(() {
        _resumeFacture = resume;
        _isLoadingResume = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingResume = false;
        _resumeFacture = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _selectedFactureId = widget.factureId ?? widget.paiement?.factureId;

    if (_selectedFactureId == null) {
      _loadFactures();
    }

    final paiement = widget.paiement;

    _montantController = TextEditingController(
      text: paiement?.montant.toStringAsFixed(2) ?? '',
    );

    _operateurController = TextEditingController(
      text: paiement?.operateur ?? '',
    );

    _transactionController = TextEditingController(
      text: paiement?.transactionId ?? '',
    );

    _numeroClientController = TextEditingController(
      text: paiement?.numeroClient ?? '',
    );

    _fraisController = TextEditingController(
      text: paiement?.frais.toStringAsFixed(2) ?? '0',
    );

    _referenceController = TextEditingController(
      text: paiement?.reference ?? '',
    );

    _notesController = TextEditingController(
      text: paiement?.notes ?? '',
    );

    if (paiement != null) {
      _modePaiement = paiement.modePaiement;
      _statut = paiement.statut;

      if (paiement.datePaiement != null) {
        _datePaiement = paiement.datePaiement!;
      }
    }
  }

  Future<void> _loadFactures() async {
    setState(() => _isLoadingFactures = true);

    try {
      final factures = await _factureService.getFactures();

      if (!mounted) return;

      setState(() {
        _factures = factures
            .where((facture) => facture.actif)
            .toList();
        _isLoadingFactures = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingFactures = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de charger les factures : $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  void dispose() {
    _montantController.dispose();
    _operateurController.dispose();
    _transactionController.dispose();
    _numeroClientController.dispose();
    _fraisController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _datePaiement,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        _datePaiement = DateTime(
          date.year,
          date.month,
          date.day,
          _datePaiement.hour,
          _datePaiement.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFactureId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une facture.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final montant = _montant;
      final frais =
          double.tryParse(
            _fraisController.text.replaceAll(',', '.'),
          ) ??
          0;

      final data = {
        'facture_id': _selectedFactureId,
        'montant': montant,
        'mode_paiement': _modePaiement,
        'operateur': _isMobilePayment
            ? _operateurController.text.trim()
            : null,
        'transaction_id': _transactionController.text.trim().isEmpty
            ? null
            : _transactionController.text.trim(),
        'numero_client': _isMobilePayment
            ? _numeroClientController.text.trim()
            : null,
        'frais': frais,
        'reference': _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        'date_paiement': _datePaiement.toIso8601String(),
        'statut': _statut,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      };

      if (widget.isEditing) {
        await _service.updatePaiement(
          widget.paiement!.id,
          data,
        );
      } else if (_isMobilePayment) {
        await _service.initierPaiementMobile(data);
      } else {
        await _service.createPaiement(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Paiement modifié avec succès'
                : 'Paiement enregistré avec succès',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  InputDecoration _decoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.teal,
          width: 2,
        ),
      ),
    );
  }

  String _formatMoney(double value) {
    return '${value.toStringAsFixed(0)} FCFA';
  }

  Widget _buildResumeFacture() {
    final resume = _resumeFacture!;

    final montantTtc =
        (resume['montant_ttc'] as num?)?.toDouble() ?? 0;
    final totalPaye =
        (resume['total_paye'] as num?)?.toDouble() ?? 0;
    final reste =
        (resume['reste_a_payer'] as num?)?.toDouble() ?? 0;
    final totalFrais =
        (resume['total_frais'] as num?)?.toDouble() ?? 0;

    final progression = montantTtc > 0
        ? (totalPaye / montantTtc).clamp(0.0, 1.0)
        : 0.0;

    final statut = resume['statut']?.toString() ?? 'Brouillon';
    final numero = resume['numero']?.toString() ?? '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résumé de la facture',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      numero,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statut,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _resumeItem(
                  'Montant TTC',
                  _formatMoney(montantTtc),
                  Icons.receipt_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _resumeItem(
                  'Déjà payé',
                  _formatMoney(totalPaye),
                  Icons.check_circle_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _resumeItem(
                  'Reste à payer',
                  _formatMoney(reste),
                  Icons.pending_actions_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _resumeItem(
                  'Frais',
                  _formatMoney(totalFrais),
                  Icons.account_balance_wallet_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression du paiement',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${(progression * 100).toStringAsFixed(0)} %',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progression,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumeItem(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Modifier le paiement'
              : 'Nouveau paiement',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildSection(
              title: 'Informations du paiement',
              icon: Icons.payments_rounded,
              children: [
                if (widget.factureId == null && !widget.isEditing) ...[
                  if (_isLoadingFactures)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: _selectedFactureId,
                      decoration: _decoration(
                        'Facture concernée',
                        Icons.receipt_long_rounded,
                        hint: 'Sélectionnez une facture',
                      ),
                      items: _factures.map((facture) {
                        return DropdownMenuItem<int>(
                          value: facture.id,
                          child: Text(
                            '${facture.numero} — '
                            '${_formatMoney(facture.montantTtc ?? facture.montantHt)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFactureId = value;
                        });

                        if (value != null) {
                          _loadResumeFacture(value);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Sélectionnez une facture';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 14),
                ],

                if (_isLoadingResume)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

                if (_resumeFacture != null) ...[
                  _buildResumeFacture(),
                  const SizedBox(height: 14),
                ],

                TextFormField(
                  controller: _montantController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: _decoration(
                    'Montant',
                    Icons.attach_money_rounded,
                    hint: 'Ex. 150000',
                  ),
                  validator: (value) {
                    final amount = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );

                    if (amount == null || amount <= 0) {
                      return 'Entrez un montant valide';
                    }

                    if (_resumeFacture != null) {
                      final reste = (
                        _resumeFacture!['reste_a_payer'] as num?
                      )?.toDouble() ?? 0;

                      if (amount > reste) {
                        return 'Le montant dépasse le reste à payer '
                            '(${_formatMoney(reste)})';
                      }
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _modePaiement,
                  decoration: _decoration(
                    'Mode de paiement',
                    Icons.account_balance_wallet_rounded,
                  ),
                  items: _modesPaiement.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(mode),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _modePaiement = value;

                      if (!_isMobilePayment) {
                        _operateurController.clear();
                        _numeroClientController.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _statut,
                  decoration: _decoration(
                    'Statut',
                    Icons.flag_rounded,
                  ),
                  items: _statuts.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: widget.isEditing
                      ? (value) {
                          if (value != null) {
                            setState(() => _statut = value);
                          }
                        }
                      : (value) {
                          if (value != null) {
                            setState(() => _statut = value);
                          }
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isMobilePayment) ...[
              _buildSection(
                title: 'Paiement mobile',
                icon: Icons.phone_android_rounded,
                children: [
                  TextFormField(
                    controller: _operateurController,
                    decoration: _decoration(
                      'Opérateur',
                      Icons.business_rounded,
                    ),
                    validator: (value) {
                      if (_isMobilePayment &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Indiquez l’opérateur';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _numeroClientController,
                    keyboardType: TextInputType.phone,
                    decoration: _decoration(
                      'Numéro du client',
                      Icons.phone_rounded,
                      hint: 'Ex. 690000000',
                    ),
                    validator: (value) {
                      if (_isMobilePayment &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Indiquez le numéro du client';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _transactionController,
                    decoration: _decoration(
                      'ID de transaction',
                      Icons.receipt_long_rounded,
                      hint: 'Référence de transaction',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            _buildSection(
              title: 'Références',
              icon: Icons.tag_rounded,
              children: [
                TextFormField(
                  controller: _referenceController,
                  decoration: _decoration(
                    'Référence',
                    Icons.confirmation_number_rounded,
                    hint: 'Référence interne',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _fraisController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decoration(
                    'Frais',
                    Icons.money_off_rounded,
                    hint: '0',
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(15),
                  child: InputDecorator(
                    decoration: _decoration(
                      'Date du paiement',
                      Icons.calendar_month_rounded,
                    ),
                    child: Text(
                      '${_datePaiement.day.toString().padLeft(2, '0')}/'
                      '${_datePaiement.month.toString().padLeft(2, '0')}/'
                      '${_datePaiement.year}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCommissionCard(),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Notes',
              icon: Icons.notes_rounded,
              children: [
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: _decoration(
                    'Notes',
                    Icons.edit_note_rounded,
                    hint: 'Informations complémentaires...',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F766E),
            Color(0xFF14B8A6),
            Color(0xFF2DD4BF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              widget.isEditing
                  ? 'Modifiez les informations du règlement'
                  : 'Enregistrez un nouveau règlement',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.teal,
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCommissionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withValues(alpha: 0.95),
            Colors.purple.withValues(alpha: 0.80),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.percent_rounded,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Résumé financier',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _summaryRow(
            'Montant',
            '${_montant.toStringAsFixed(2)} FCFA',
          ),
          _summaryRow(
            'Commission (2 %)',
            '${_commission.toStringAsFixed(2)} FCFA',
          ),
          const Divider(
            color: Colors.white38,
            height: 24,
          ),
          _summaryRow(
            'Total',
            '${_total.toStringAsFixed(2)} FCFA',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              _isLoading
                  ? 'Enregistrement...'
                  : widget.isEditing
                      ? 'Enregistrer les modifications'
                      : 'Enregistrer le paiement',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
