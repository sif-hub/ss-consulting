import 'package:file_picker/file_picker.dart';
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

  final _descriptionController = TextEditingController();

  String _typeDocument = 'Administratif';
  bool _saving = false;
  PlatformFile? _selectedFile;

  static const int _maxSize = 10 * 1024 * 1024;

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
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
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

    if (result.isEmpty) return;

    final file = result.first;
    final size = await file.length();

    if (size > _maxSize) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le fichier dépasse la taille maximale de 10 Mo.'),
        ),
      );
      return;
    }

    setState(() {
      _selectedFile = file;
    });
  }

  Future<void> _save() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez un fichier à envoyer.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _service.createDocument(
        dossierId: widget.dossierId,
        file: _selectedFile!,
        typeDocument: _typeDocument,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section(
            icon: Icons.description_rounded,
            title: 'Informations du document',
            children: [
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
              if (_selectedFile == null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Choisir un fichier'),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file_rounded,
                        color: Color(0xFF3155D9),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedFile!.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Formats acceptés : PDF, JPG, PNG, WEBP, DOC, DOCX, XLS, XLSX (10 Mo max).',
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
                _saving ? 'Envoi en cours...' : 'Enregistrer',
              ),
            ),
          ),
        ],
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
