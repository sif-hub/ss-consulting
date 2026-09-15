import 'package:flutter/material.dart';

import '../../models/facture.dart';
import 'facture_service.dart';

class FactureFormPage extends StatefulWidget {
  final int? clientId;
  final int? dossierId;
  final Facture? facture;

  const FactureFormPage({
    super.key,
    this.clientId,
    this.dossierId,
    this.facture,
  });

  bool get isEditing => facture != null;

  @override
  State<FactureFormPage> createState() => _FactureFormPageState();
}

class _FactureFormPageState extends State<FactureFormPage> {
  final FactureService _service = FactureService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _numeroController;
  late final TextEditingController _montantHtController;
  late final TextEditingController _tvaController;
  late final TextEditingController _notesController;

  late int? _clientId;
  late int? _dossierId;

  String _statut = 'Brouillon';
  String? _modePaiement;
  DateTime _dateEmission = DateTime.now();
  DateTime? _dateEcheance;
  bool _saving = false;

  final List<String> _statuts = [
    'Brouillon',
    'En attente',
    'Payée',
    'Impayée',
    'Annulée',
  ];

  final List<String> _modesPaiement = [
    'Espèces',
    'Virement bancaire',
    'Orange Money',
    'MTN Mobile Money',
    'Chèque',
    'Carte bancaire',
  ];

  @override
  void initState() {
    super.initState();

    final facture = widget.facture;

    _numeroController = TextEditingController(
      text: facture?.numero ?? '',
    );

    _montantHtController = TextEditingController(
      text: facture != null
          ? facture.montantHt.toString()
          : '',
    );

    _tvaController = TextEditingController(
      text: facture != null
          ? facture.tauxTva.toString()
          : '19.25',
    );

    _notesController = TextEditingController(
      text: facture?.notes ?? '',
    );

    _clientId = facture?.clientId ?? widget.clientId;
    _dossierId = facture?.dossierId ?? widget.dossierId;

    if (facture != null) {
      _statut = facture.statut;
      _modePaiement = facture.modePaiement;
      _dateEmission = facture.dateEmission;
      _dateEcheance = facture.dateEcheance;
    }
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _montantHtController.dispose();
    _tvaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _montantHt =>
      double.tryParse(_montantHtController.text.replaceAll(',', '.')) ??
      0;

  double get _tauxTva =>
      double.tryParse(_tvaController.text.replaceAll(',', '.')) ??
      0;

  double get _montantTva =>
      _montantHt * _tauxTva / 100;

  double get _montantTtc =>
      _montantHt + _montantTva;

  Future<void> _selectDate({
    required bool emission,
  }) async {
    final initialDate =
        emission ? _dateEmission : (_dateEcheance ?? DateTime.now());

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );

    if (selected == null) return;

    setState(() {
      if (emission) {
        _dateEmission = selected;
      } else {
        _dateEcheance = selected;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Un client doit être associé à la facture.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final data = {
        'numero': _numeroController.text.trim().isEmpty
            ? null
            : _numeroController.text.trim(),
        'client_id': _clientId,
        'dossier_id': _dossierId,
        'date_emission': _dateEmission.toIso8601String(),
        'date_echeance': _dateEcheance?.toIso8601String(),
        'montant_ht': _montantHt,
        'taux_tva': _tauxTva,
        'montant_tva': _montantTva,
        'montant_ttc': _montantTtc,
        'statut': _statut,
        'mode_paiement': _modePaiement,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      };

      if (widget.isEditing) {
        await _service.updateFacture(
          widget.facture!.id,
          data,
        );
      } else {
        await _service.createFacture(data);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erreur lors de l'enregistrement : $e",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Modifier la facture'
              : 'Nouvelle facture',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(
              controller: _numeroController,
              label: 'Numéro de facture',
              hint: 'Ex. FAC-2026-001',
              icon: Icons.tag_rounded,
            ),
            const SizedBox(height: 16),
            _dateTile(
              title: 'Date d’émission',
              date: _dateEmission,
              onTap: () => _selectDate(emission: true),
            ),
            const SizedBox(height: 16),
            _dateTile(
              title: 'Date d’échéance',
              date: _dateEcheance,
              onTap: () => _selectDate(emission: false),
              clearable: true,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _montantHtController,
              label: 'Montant HT',
              hint: '0',
              icon: Icons.payments_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final amount = double.tryParse(
                  (value ?? '').replaceAll(',', '.'),
                );

                if (amount == null || amount < 0) {
                  return 'Montant invalide';
                }

                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _field(
              controller: _tvaController,
              label: 'Taux TVA (%)',
              hint: '19.25',
              icon: Icons.percent_rounded,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _buildAmountSummary(),
            const SizedBox(height: 16),
            _dropdown(
              label: 'Statut',
              value: _statut,
              values: _statuts,
              icon: Icons.flag_outlined,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _statut = value);
                }
              },
            ),
            const SizedBox(height: 16),
            _dropdown(
              label: 'Mode de paiement',
              value: _modePaiement,
              values: _modesPaiement,
              icon: Icons.account_balance_wallet_outlined,
              allowNull: true,
              onChanged: (value) {
                setState(() => _modePaiement = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Informations complémentaires...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 45),
                  child: Icon(Icons.notes_rounded),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _saving
                    ? 'Enregistrement...'
                    : widget.isEditing
                        ? 'Enregistrer les modifications'
                        : 'Créer la facture',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> values,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    bool allowNull = false,
  }) {
    final items = values
        .map(
          (item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          ),
        )
        .toList();

    if (allowNull) {
      items.insert(
        0,
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Non défini'),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _dateTile({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
    bool clearable = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: title,
          prefixIcon: const Icon(Icons.event_rounded),
          suffixIcon: clearable && date != null
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _dateEcheance = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        child: Text(
          date == null
              ? 'Aucune date'
              : _formatDate(date),
        ),
      ),
    );
  }

  Widget _buildAmountSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1565C0),
            Color(0xFF42A5F5),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _amountRow(
            'Montant HT',
            _montantHt,
          ),
          const SizedBox(height: 8),
          _amountRow(
            'TVA ($_tauxTva%)',
            _montantTva,
          ),
          const Divider(color: Colors.white38),
          _amountRow(
            'Total TTC',
            _montantTtc,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    String label,
    double value, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontWeight:
                bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${_formatMoney(value)} FCFA',
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                bold ? FontWeight.bold : FontWeight.w600,
            fontSize: bold ? 17 : 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatMoney(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ' ',
        );
  }
}
