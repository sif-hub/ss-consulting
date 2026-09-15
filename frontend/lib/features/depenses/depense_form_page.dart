import 'package:flutter/material.dart';

import '../../models/depense.dart';
import 'depense_service.dart';

class DepenseFormPage extends StatefulWidget {
  final Depense? depense;

  const DepenseFormPage({super.key, this.depense});

  bool get isEditing => depense != null;

  @override
  State<DepenseFormPage> createState() => _DepenseFormPageState();
}

class _DepenseFormPageState extends State<DepenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final DepenseService _service = DepenseService();

  late final TextEditingController _descriptionController;
  late final TextEditingController _categorieController;
  late final TextEditingController _fournisseurController;
  late final TextEditingController _montantHtController;
  late final TextEditingController _tauxTvaController;
  late final TextEditingController _referenceController;
  late final TextEditingController _notesController;

  DateTime _dateDepense = DateTime.now();
  String _modePaiement = 'Espèces';
  String _statut = 'Payée';
  bool _isLoading = false;

  final List<String> _modesPaiement = [
    'Espèces',
    'Virement',
    'Chèque',
    'Orange Money',
    'MTN MoMo',
  ];

  final List<String> _statuts = ['Payée', 'En attente'];

  @override
  void initState() {
    super.initState();

    final depense = widget.depense;

    _descriptionController = TextEditingController(
      text: depense?.description ?? '',
    );
    _categorieController = TextEditingController(
      text: depense?.categorie ?? '',
    );
    _fournisseurController = TextEditingController(
      text: depense?.fournisseur ?? '',
    );
    _montantHtController = TextEditingController(
      text: depense?.montantHt.toStringAsFixed(2) ?? '',
    );
    _tauxTvaController = TextEditingController(
      text: (depense?.tauxTva ?? 19.25).toStringAsFixed(2),
    );
    _referenceController = TextEditingController(
      text: depense?.reference ?? '',
    );
    _notesController = TextEditingController(text: depense?.notes ?? '');

    if (depense != null) {
      _dateDepense = depense.dateDepense;
      _modePaiement = depense.modePaiement ?? _modePaiement;
      _statut = depense.statut;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _categorieController.dispose();
    _fournisseurController.dispose();
    _montantHtController.dispose();
    _tauxTvaController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  double get _montantTva =>
      _parse(_montantHtController.text) * _parse(_tauxTvaController.text) / 100;

  double get _montantTtc => _parse(_montantHtController.text) + _montantTva;

  Future<void> _selectionnerDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateDepense,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() => _dateDepense = selected);
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'description': _descriptionController.text.trim(),
      'categorie': _categorieController.text.trim(),
      'fournisseur': _fournisseurController.text.trim().isEmpty
          ? null
          : _fournisseurController.text.trim(),
      'date_depense': _dateDepense.toIso8601String(),
      'montant_ht': _parse(_montantHtController.text),
      'taux_tva': _parse(_tauxTvaController.text),
      'mode_paiement': _modePaiement,
      'reference': _referenceController.text.trim().isEmpty
          ? null
          : _referenceController.text.trim(),
      'statut': _statut,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    try {
      if (widget.isEditing) {
        await _service.updateDepense(widget.depense!.id, data);
      } else {
        await _service.createDepense(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Dépense modifiée avec succès'
                : 'Dépense créée avec succès',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Modifier la dépense' : 'Nouvelle dépense',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().length < 2) ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categorieController,
              decoration: const InputDecoration(
                labelText: 'Catégorie (ex : Loyer, Fournitures, Transport...)',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().length < 2) ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fournisseurController,
              decoration: const InputDecoration(
                labelText: 'Fournisseur (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectionnerDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de la dépense',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  '${_dateDepense.day.toString().padLeft(2, '0')}/'
                  '${_dateDepense.month.toString().padLeft(2, '0')}/${_dateDepense.year}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _montantHtController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Montant HT',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final amount = double.tryParse(
                        (value ?? '').replaceAll(',', '.'),
                      );
                      if (amount == null || amount <= 0)
                        return 'Montant invalide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _tauxTvaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Taux TVA (%)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TVA : ${_montantTva.toStringAsFixed(0)} FCFA'),
                  Text(
                    'Total TTC : ${_montantTtc.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _modePaiement,
              decoration: const InputDecoration(
                labelText: 'Mode de paiement',
                border: OutlineInputBorder(),
              ),
              items: _modesPaiement
                  .map(
                    (mode) => DropdownMenuItem(value: mode, child: Text(mode)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _modePaiement = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _statut,
              decoration: const InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(),
              ),
              items: _statuts
                  .map(
                    (statut) =>
                        DropdownMenuItem(value: statut, child: Text(statut)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _statut = value);
              },
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
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _enregistrer,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isEditing
                            ? 'Enregistrer les modifications'
                            : 'Créer la dépense',
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
