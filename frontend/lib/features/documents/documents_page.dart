import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/document.dart';
import '../ia/ai_service.dart';
import 'document_form_page.dart';
import 'document_service.dart';

class DocumentsPage extends StatefulWidget {
  final int dossierId;

  const DocumentsPage({super.key, required this.dossierId});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final DocumentService _service = DocumentService();
  final AiService _aiService = AiService();
  final TextEditingController _searchController = TextEditingController();

  List<Document> _documents = [];
  bool _loading = true;
  String? _error;
  String _filter = 'Tous';

  final List<String> _filters = [
    'Tous',
    'Fiscal',
    'Comptable',
    'Juridique',
    'Administratif',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final documents = await _service.getDocuments(widget.dossierId);

      if (!mounted) return;

      setState(() {
        _documents = documents;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger les documents.';
      });
    }
  }

  List<Document> get _filteredDocuments {
    final search = _searchController.text.trim().toLowerCase();

    return _documents.where((document) {
      final matchesSearch =
          search.isEmpty ||
          document.nom.toLowerCase().contains(search) ||
          document.typeDocument.toLowerCase().contains(search) ||
          (document.description?.toLowerCase().contains(search) ?? false);

      final matchesFilter =
          _filter == 'Tous' ||
          document.typeDocument.toLowerCase().contains(_filter.toLowerCase());

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _createDocument() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentFormPage(dossierId: widget.dossierId),
      ),
    );

    if (result == true) {
      _loadDocuments();
    }
  }

  Future<void> _deleteDocument(Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le document'),
          content: Text('Voulez-vous vraiment supprimer « ${document.nom} » ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.deleteDocument(document.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document supprimé avec succès')),
      );

      _loadDocuments();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  Future<void> _openDocument(Document document) async {
    try {
      final url = await _service.getDownloadUrl(document.id);

      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir le document.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  Future<void> _analyserDocument(Document document) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Analyse du document en cours...'),
          ],
        ),
      ),
    );

    try {
      final analyse = await _aiService.analyserDocument(document.id);

      if (!mounted) return;
      Navigator.pop(context);

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1)),
              SizedBox(width: 10),
              Text('Analyse IA'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (analyse.typeDocument.isNotEmpty) ...[
                  Text(
                    'Type : ${analyse.typeDocument}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                ],
                if (analyse.resume.isNotEmpty) ...[
                  Text(analyse.resume),
                  const SizedBox(height: 12),
                ],
                if (analyse.montantsDetectes.isNotEmpty) ...[
                  const Text(
                    'Montants détectés :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...analyse.montantsDetectes.map((m) => Text('• $m')),
                  const SizedBox(height: 12),
                ],
                if (analyse.dateDetectee.isNotEmpty) ...[
                  Text('Date détectée : ${analyse.dateDetectee}'),
                  const SizedBox(height: 12),
                ],
                if (analyse.pointsAttention.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('⚠️ ${analyse.pointsAttention}'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = _filteredDocuments;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Documents',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createDocument,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau document'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDocuments,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSearch(),
            const SizedBox(height: 14),
            _buildFilters(),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _buildError()
            else if (documents.isEmpty)
              _buildEmpty()
            else
              ...documents.map(_buildDocumentCard),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3155D9), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.folder_copy_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Documents du dossier',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_documents.length} document${_documents.length > 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Rechercher un document...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: _searchController.clear,
                icon: const Icon(Icons.clear_rounded),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final selected = _filter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _filter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDocumentCard(Document document) {
    final color = _documentColor(document.typeDocument);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDocument(document),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _documentIcon(document.typeDocument),
                  color: color,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.nom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      document.typeDocument,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (document.description != null &&
                        document.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        document.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'open') {
                    _openDocument(document);
                  } else if (value == 'analyser') {
                    _analyserDocument(document);
                  } else if (value == 'delete') {
                    _deleteDocument(document);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'open',
                    child: Row(
                      children: [
                        Icon(
                          Icons.open_in_new_rounded,
                          color: Color(0xFF3155D9),
                        ),
                        SizedBox(width: 10),
                        Text('Ouvrir / Télécharger'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'analyser',
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF6366F1),
                        ),
                        SizedBox(width: 10),
                        Text('Analyser avec l\'IA'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Supprimer'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 15),
          const Text(
            'Aucun document',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 7),
          Text(
            'Ajoutez le premier document de ce dossier.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 60, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: _loadDocuments,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Color _documentColor(String type) {
    final value = type.toLowerCase();

    if (value.contains('fiscal')) {
      return Colors.orange;
    }

    if (value.contains('compt')) {
      return Colors.green;
    }

    if (value.contains('jurid')) {
      return Colors.red;
    }

    if (value.contains('administr')) {
      return Colors.blue;
    }

    return Colors.deepPurple;
  }

  IconData _documentIcon(String type) {
    final value = type.toLowerCase();

    if (value.contains('fiscal')) {
      return Icons.account_balance_rounded;
    }

    if (value.contains('compt')) {
      return Icons.calculate_rounded;
    }

    if (value.contains('jurid')) {
      return Icons.gavel_rounded;
    }

    if (value.contains('administr')) {
      return Icons.business_center_rounded;
    }

    return Icons.description_rounded;
  }
}
