import 'package:flutter/material.dart';

import 'document_service.dart';

class DocumentFormPage extends StatefulWidget {
  final int dossierId;

  const DocumentFormPage({
    super.key,
    required this.dossierId,
  });

  @override
  State<DocumentFormPage> createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  final DocumentService _service = DocumentService();

  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cheminController = TextEditingController();

  String _typeDocument = 'Administratif';
  bool _saving = false;

  final List<String> _types = [
    'Fiscalité',
    'Comptabilité',
    'Juridique',
    'Administratif',
    'Social',
    'Autre',
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _cheminController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      await _service.createDocument(
        widget.dossierId,
        {
          'nom': _nomController.text.trim(),
          'type_document': _typeDocument,
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'chemin_fichier': _cheminController.text.trim().isEmpty
              ? null
              : _cheminController.text.trim(),
          'statut': 'Actif',
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document ajouté avec succès'),
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
          content: Text('Erreur lors de l\'enregistrement : $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Nouveau document',
          style: TextStyle(fontWeight: FontWeight.bold),
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
              icon: Icons.description_rounded,
              title: 'Informations du document',
              children: [
                TextFormField(
                  controller: _nomController,
                  decoration: _decoration(
                    'Nom du document',
                    Icons.title_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom du document est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _typeDocument,
                  decoration: _decoration(
                    'Type de document',
                    Icons.category_rounded,
                  ),
                  items: _types.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _typeDocument = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: _decoration(
                    'Description',
                    Icons.notes_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _section(
              icon: Icons.attach_file_rounded,
              title: 'Fichier',
              children: [
                TextFormField(
                  controller: _cheminController,
                  decoration: _decoration(
                    'Chemin ou URL du fichier',
                    Icons.link_rounded,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Le stockage réel des fichiers pourra être connecté ensuite à un stockage local ou S3/MinIO.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
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
                  _saving ? 'Enregistrement...' : 'Enregistrer',
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
              Icon(icon, color: const Color(0xFF3155D9)),
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
}
