import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'declaration_service.dart';
import '../../core/auth/auth_service.dart';
import '../ia/ai_service.dart';

class DeclarationFormPage extends StatefulWidget {
  const DeclarationFormPage({super.key});

  @override
  State<DeclarationFormPage> createState() => _DeclarationFormPageState();
}

class _DeclarationFormPageState extends State<DeclarationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final DeclarationService _service = DeclarationService();
  final AuthService _authService = AuthService();
  final AiService _aiService = AiService();
  bool _suggestingObservations = false;

  final _caController = TextEditingController();
  final _ventesController = TextEditingController();
  final _achatsController = TextEditingController();
  final _employesController = TextEditingController();
  final _observationsController = TextEditingController();

  int _mois = DateTime.now().month;
  int _annee = DateTime.now().year;
  bool _loading = false;

  final List<PlatformFile> _selectedFiles = [];

  @override
  void dispose() {
    _caController.dispose();
    _ventesController.dispose();
    _achatsController.dispose();
    _employesController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  double _parseDouble(String value) {
    return double.tryParse(value.replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
  }

  int _parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  Future<void> _suggererObservations() async {
    setState(() => _suggestingObservations = true);

    try {
      final suggestion = await _aiService.suggererObservations(
        mois: _mois,
        annee: _annee,
        chiffreAffaires: _parseDouble(_caController.text),
        totalVentes: _parseDouble(_ventesController.text),
        totalAchats: _parseDouble(_achatsController.text),
        nombreEmployes: _parseInt(_employesController.text),
      );

      if (!mounted) return;

      setState(() {
        _observationsController.text = suggestion;
        _suggestingObservations = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _suggestingObservations = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'webp',
        'doc',
        'docx',
        'xls',
        'xlsx',
      ],
    );

    if (result.isEmpty) {
      return;
    }

    const maxSize = 10 * 1024 * 1024;

    final validFiles = <PlatformFile>[];

    for (final file in result) {
      final size = await file.length();

      if (size > maxSize) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Le fichier ${file.name} dépasse la taille maximale de 10 Mo.',
            ),
          ),
        );

        continue;
      }

      final exists = _selectedFiles.any((item) => item.name == file.name);

      if (!exists) {
        validFiles.add(file);
      }
    }

    if (!mounted || validFiles.isEmpty) {
      return;
    }

    setState(() {
      _selectedFiles.addAll(validFiles);
    });
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = await _authService.getCurrentUser();

    if (user.clientId == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre compte n’est associé à aucun client.'),
        ),
      );

      return;
    }

    final clientId = user.clientId!;

    setState(() {
      _loading = true;
    });

    try {
      final declaration = await _service.createDeclaration(
        clientId: clientId,
        mois: _mois,
        annee: _annee,
        chiffreAffaires: _parseDouble(_caController.text),
        totalVentes: _parseDouble(_ventesController.text),
        totalAchats: _parseDouble(_achatsController.text),
        nombreEmployes: _parseInt(_employesController.text),
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
      );

      for (final file in _selectedFiles) {
        await _service.uploadDeclarationDocument(
          declarationId: declaration.id,
          file: file,
          description:
              'Pièce justificative de la déclaration '
              '${_moisLabel(_mois)} $_annee',
        );
      }

      await _service.submitDeclaration(declaration.id);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création : $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle déclaration')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<int>(
              initialValue: _mois,
              decoration: const InputDecoration(
                labelText: 'Mois',
                border: OutlineInputBorder(),
              ),
              items: List.generate(12, (index) {
                final mois = index + 1;

                return DropdownMenuItem(
                  value: mois,
                  child: Text(_moisLabel(mois)),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _mois = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _annee.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Année',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final year = int.tryParse(value);

                if (year != null) {
                  _annee = year;
                }
              },
              validator: (value) {
                final year = int.tryParse(value ?? '');

                if (year == null || year < 2000 || year > 2100) {
                  return 'Année invalide';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            _numberField(
              controller: _caController,
              label: 'Chiffre d’affaires',
            ),
            const SizedBox(height: 16),
            _numberField(
              controller: _ventesController,
              label: 'Total des ventes',
            ),
            const SizedBox(height: 16),
            _numberField(
              controller: _achatsController,
              label: 'Total des achats',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _employesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nombre d’employés',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final number = int.tryParse(value ?? '');

                if (number == null || number < 0) {
                  return 'Nombre invalide';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observationsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Observations',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _suggestingObservations
                    ? null
                    : _suggererObservations,
                icon: _suggestingObservations
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Suggérer avec l\'IA'),
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                "Pièces justificatives",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...List.generate(_selectedFiles.length, (index) {
                final file = _selectedFiles[index];
                return ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(
                    file.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    "${((file.lengthSync() ?? 0) / (1024 * 1024)).toStringAsFixed(2)} Mo",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _loading ? null : () => _removeFile(index),
                  ),
                );
              }),
            ],
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickFiles,
              icon: const Icon(Icons.upload_file),
              label: const Text("Ajouter une pièce justificative"),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _loading ? 'Enregistrement...' : 'Créer la déclaration',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '$label (FCFA)',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ce champ est obligatoire';
        }

        if (_parseDouble(value) < 0) {
          return 'La valeur doit être positive';
        }

        return null;
      },
    );
  }

  String _moisLabel(int mois) {
    const labels = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];

    return labels[mois - 1];
  }
}
