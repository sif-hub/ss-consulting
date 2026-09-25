import 'package:flutter/material.dart';

import '../../models/tache.dart';
import 'tache_service.dart';
import '../../core/theme/app_colors.dart';

class TacheFormPage extends StatefulWidget {
  final int dossierId;
  final Tache? tache;

  const TacheFormPage({
    super.key,
    required this.dossierId,
    this.tache,
  });

  bool get isEditing => tache != null;

  @override
  State<TacheFormPage> createState() => _TacheFormPageState();
}

class _TacheFormPageState extends State<TacheFormPage> {
  final TacheService _service = TacheService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titreController;
  late final TextEditingController _descriptionController;

  String _statut = 'À faire';
  String _priorite = 'Normale';
  DateTime? _dateEcheance;
  bool _saving = false;

  final List<String> _statuts = [
    'À faire',
    'En cours',
    'Terminée',
    'Annulée',
  ];

  final List<String> _priorites = [
    'Basse',
    'Normale',
    'Haute',
    'Urgente',
  ];

  @override
  void initState() {
    super.initState();

    final tache = widget.tache;

    _titreController = TextEditingController(
      text: tache?.titre ?? '',
    );

    _descriptionController = TextEditingController(
      text: tache?.description ?? '',
    );

    if (tache != null) {
      _statut = tache.statut;
      _priorite = tache.priorite;
      _dateEcheance = tache.dateEcheance;
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _dateEcheance ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );

    if (selected != null) {
      setState(() {
        _dateEcheance = selected;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      final data = {
        'titre': _titreController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'statut': _statut,
        'priorite': _priorite,
        'date_echeance': _dateEcheance?.toIso8601String(),
        'dossier_id': widget.dossierId,
      };

      if (widget.isEditing) {
        await _service.updateTache(
          widget.tache!.id,
          data,
        );
      } else {
        await _service.createTache(data);
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
      backgroundColor: context.pageBackground,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Modifier la tâche' : 'Nouvelle tâche',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.surfaceColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(
              controller: _titreController,
              label: 'Titre',
              hint: 'Ex. Préparer la déclaration fiscale',
              icon: Icons.title_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est obligatoire';
                }
                return null;
              },
            ),
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
              label: 'Priorité',
              value: _priorite,
              values: _priorites,
              icon: Icons.priority_high_rounded,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _priorite = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Décrivez la tâche...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 70),
                  child: Icon(Icons.notes_rounded),
                ),
                filled: true,
                fillColor: context.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date d’échéance',
                  prefixIcon: const Icon(Icons.event_rounded),
                  suffixIcon: _dateEcheance != null
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
                  fillColor: context.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                child: Text(
                  _dateEcheance == null
                      ? 'Aucune date'
                      : _formatDate(_dateEcheance!),
                ),
              ),
            ),
            const SizedBox(height: 30),
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
                        : 'Créer la tâche',
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: context.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> values,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: context.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
