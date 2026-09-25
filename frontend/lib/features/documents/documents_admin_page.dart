import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/document.dart';
import '../ia/ai_service.dart';
import 'document_service.dart';
import '../../core/theme/app_colors.dart';

class DocumentsAdminPage extends StatefulWidget {
  const DocumentsAdminPage({super.key});

  @override
  State<DocumentsAdminPage> createState() => _DocumentsAdminPageState();
}

class _DocumentsAdminPageState extends State<DocumentsAdminPage> {
  final DocumentService _service = DocumentService();
  final AiService _aiService = AiService();
  final TextEditingController _searchController = TextEditingController();

  List<Document> _documents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final documents = await _service.getAllDocuments();

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

  List<Document> get _filtered {
    final search = _searchController.text.trim().toLowerCase();

    if (search.isEmpty) return _documents;

    return _documents.where((d) {
      return d.nom.toLowerCase().contains(search) ||
          d.typeDocument.toLowerCase().contains(search) ||
          (d.description ?? '').toLowerCase().contains(search);
    }).toList();
  }

  Color _documentColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('pdf')) return const Color(0xFFEF4444);
    if (t.contains('image') || t.contains('png') || t.contains('jpg')) {
      return const Color(0xFF3155D9);
    }
    if (t.contains('excel') || t.contains('sheet'))
      return const Color(0xFF0F9D58);
    return const Color(0xFF6366F1);
  }

  IconData _documentIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (t.contains('image') || t.contains('png') || t.contains('jpg')) {
      return Icons.image_rounded;
    }
    if (t.contains('excel') || t.contains('sheet'))
      return Icons.table_chart_rounded;
    return Icons.insert_drive_file_rounded;
  }

  String _origine(Document document) {
    if (document.dossierId != null) return 'Dossier #${document.dossierId}';
    if (document.declarationId != null) {
      return 'Déclaration #${document.declarationId}';
    }
    return 'Sans dossier';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
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

  Future<void> _deleteDocument(Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteDocument(document.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document supprimé avec succès')),
      );

      _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = _filtered;

    return Scaffold(
      backgroundColor: context.pageBackground,
      appBar: AppBar(
        title: const Text(
          'Documents',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un document...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: context.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
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
              ...documents.map(_buildCard),
            const SizedBox(height: 40),
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
          colors: [Color(0xFF0EA5E9), Color(0xFF3155D9)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.folder_copy_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Documents du cabinet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
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

  Widget _buildCard(Document document) {
    final color = _documentColor(document.typeDocument);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: context.surfaceColor,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_origine(document)} • ${_formatDate(document.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
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
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 15),
          Text(_error ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
