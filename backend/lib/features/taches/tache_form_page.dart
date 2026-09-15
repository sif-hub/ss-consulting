import 'package:flutter/material.dart';

import '../../models/tache.dart';
import 'tache_service.dart';

class TacheFormPage extends StatefulWidget {
  final int dossierId;
  final Tache? tache;

  const TacheFormPage({
    super.key,
    required this.dossierId,
    this.tache,
  });

  @override
  State<TacheFormPage> createState() => _TacheFormPageState();
}

class _TacheFormPageState extends State<TacheFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TacheService _service = TacheService();

  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();

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

  bool get _editing => widget.tache != null;

  @override
  void initState() {
    super.initState();

    final tache = widget.tache;

    if (tache != null) {
      _titreController.text = tache.titre;
      _descriptionController.text = tache.description ?? '';
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

    final data = {
      'titre': _titreController.text.trim(),
      'description':
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
      'statut': _statut,
      'priorite': _priorite,
      'date_echeance':
          _dateEcheance?.toIso8601String(),
      'dossier_id': widget.dossierId,
    };

    try {
      if (_editing) {
        await _service.updateTache(
          widget.tache!.id,
          data,
        );
      } else {
        await _service.createTache(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing
                ? 'Tâche modifiée avec succès'
                : 'Tâche créée avec succès',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de l\'enregistrement : $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          _editing ? 'Modifier la tâche' : 'Nouvelle tâche',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
            _section(
              icon: Icons.task_alt_rounded,
              title: 'Informations',
              children: [
                TextFormField(
                  controller: _titreController,
                  decoration: _decoration(
                    'Titre de la tâche',
                    Icons.title_rounded,
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Le titre est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _statut,
                  decoration: _decoration(
                    'Statut',
                    Icons.flag_rounded,
                  ),
                  items: _statuts.map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _statut = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _priorite,
                  decoration: _decoration(
                    'Priorité',
                    Icons.priority_high_rounded,
                  ),
                  items: _priorites.map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _priorite = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: _decoration(
                    'Description',
                    Icons.notes_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _section(
              icon: Icons.event_rounded,
              title: 'Échéance',
              children: [
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: _decoration(
                      'Date d\'échéance',
                      Icons.calendar_month_rounded,
                    ),
                    child: Text(
                      _dateEcheance == null
                          ? 'Aucune échéance'
                          : _formatDate(_dateEcheance!),
                    ),
                  ),
                ),
                if (_dateEcheance != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _dateEcheance = null;
                        });
                      },
                      icon: const Icon(Icons.clear_rounded),
                      label: const Text(
                        'Supprimer l\'échéance',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _saving
                      ? 'Enregistrement...'
                      : 'Enregistrer',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFFF97316),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _decoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
