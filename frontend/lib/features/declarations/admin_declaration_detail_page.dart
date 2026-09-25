import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';

import '../../models/declaration.dart';
import '../../models/client.dart';
import '../clients/client_service.dart';
import 'declaration_service.dart';

class AdminDeclarationDetailPage extends StatefulWidget {
  final int declarationId;

  const AdminDeclarationDetailPage({super.key, required this.declarationId});

  @override
  State<AdminDeclarationDetailPage> createState() =>
      _AdminDeclarationDetailPageState();
}

class _AdminDeclarationDetailPageState
    extends State<AdminDeclarationDetailPage> {
  final DeclarationService _service = DeclarationService();
  final ClientService _clientService = ClientService();

  Declaration? _declaration;
  Client? _client;

  List<dynamic> _documents = [];

  bool _loading = true;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final declaration = await _service.getDeclaration(widget.declarationId);

      final documents = await _service.getDeclarationDocuments(
        widget.declarationId,
      );

      final client = await _clientService.getClient(declaration.clientId);

      if (!mounted) return;

      setState(() {
        _declaration = declaration;
        _client = client;
        _documents = documents;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors du chargement : $e')));
    }
  }

  String _formatNumber(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');

    final integer = parts[0];
    final buffer = StringBuffer();

    for (int i = 0; i < integer.length; i++) {
      if (i > 0 && (integer.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(integer[i]);
    }

    return '${buffer.toString()},${parts[1]}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} à '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'VALIDEE':
        return AppColors.success;
      case 'REJETEE':
        return AppColors.danger;
      case 'A_CORRIGER':
        return AppColors.warning;
      case 'EN_VERIFICATION':
        return AppColors.info;
      case 'SOUMISE':
        return AppColors.pending;
      default:
        return AppColors.neutral;
    }
  }

  Future<void> _startReview() async {
    setState(() => _actionLoading = true);

    try {
      await _service.startReview(widget.declarationId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Déclaration mise en vérification.')),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _processDeclaration(
    String status, {
    required String title,
    required String successMessage,
    bool requireComment = false,
  }) async {
    String? commentaire;

    if (requireComment) {
      commentaire = await _askComment(title);

      if (commentaire == null || commentaire.trim().isEmpty) {
        return;
      }
    } else {
      final confirmed = await _confirm(title);

      if (!confirmed) return;
    }

    setState(() => _actionLoading = true);

    try {
      await _service.reviewDeclaration(
        id: widget.declarationId,
        statut: status,
        commentaireAdmin: commentaire,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<String?> _askComment(String title) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Commentaire',
              hintText: 'Expliquez la décision au client...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  Future<bool> _confirm(String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: const Text('Voulez-vous vraiment effectuer cette action ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      color: context.surfaceColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildActions(Declaration declaration) {
    if (_actionLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (declaration.estSoumise) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _startReview,
          icon: const Icon(Icons.fact_check_rounded),
          label: const Text('Mettre en vérification'),
        ),
      );
    }

    if (declaration.enVerification) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: () {
              _processDeclaration(
                'VALIDEE',
                title: 'Valider la déclaration',
                successMessage: 'Déclaration validée.',
              );
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Valider'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              _processDeclaration(
                'A_CORRIGER',
                title: 'Demander une correction',
                successMessage: 'Demande de correction envoyée.',
                requireComment: true,
              );
            },
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Demander correction'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              _processDeclaration(
                'REJETEE',
                title: 'Rejeter la déclaration',
                successMessage: 'Déclaration rejetée.',
                requireComment: true,
              );
            },
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Rejeter'),
          ),
        ],
      );
    }

    return Text(
      'Aucune action disponible pour le statut actuel.',
      style: TextStyle(color: Colors.grey.shade600),
    );
  }

  Future<void> _downloadDocument(Map<String, dynamic> document) async {
    final documentId = document['id'];

    if (documentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiant du document introuvable.')),
      );
      return;
    }

    final nom =
        document['nom_fichier']?.toString() ??
        document['filename']?.toString() ??
        document['nom']?.toString() ??
        'document';

    try {
      setState(() => _actionLoading = true);

      final bytes = await _service.downloadDeclarationDocument(
        (documentId as num).toInt(),
      );

      if (!mounted) return;

      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) {
        throw Exception('Répertoire utilisateur introuvable.');
      }

      final downloadDir = Directory('$home/Downloads');

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final savedFile = File('${downloadDir.path}/$nom');
      await savedFile.writeAsBytes(bytes);

      final savedPath = savedFile.path;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document enregistré : $savedPath')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléchargement : $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<int?> _askAnnee(int defaut) async {
    final controller = TextEditingController(text: defaut.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Générer la DSF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'La DSF sera générée à partir de toutes les déclarations '
                'mensuelles validées de ce client pour l\'exercice choisi.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Exercice (année)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final annee = int.tryParse(controller.text.trim());
                Navigator.pop(context, annee);
              },
              child: const Text('Générer'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  Future<void> _genererDsf(Declaration declaration) async {
    final annee = await _askAnnee(declaration.annee);

    if (annee == null) return;

    setState(() => _actionLoading = true);

    try {
      final bytes = await _service.genererDsfPdf(
        clientId: declaration.clientId,
        annee: annee,
      );

      if (!mounted) return;

      final nomClient = (_client?.nomComplet ?? 'client').replaceAll(
        RegExp(r'[^\w\-]+'),
        '_',
      );

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'DSF_${nomClient}_$annee.pdf',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur lors de la génération : $e')));
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  IconData _documentIcon(String type, String nom) {
    final value = '$type $nom'.toLowerCase();

    if (value.contains('pdf')) {
      return Icons.picture_as_pdf_rounded;
    }

    if (value.contains('image') ||
        value.contains('jpg') ||
        value.contains('jpeg') ||
        value.contains('png') ||
        value.contains('webp')) {
      return Icons.image_rounded;
    }

    if (value.contains('word') ||
        value.contains('doc') ||
        value.contains('docx')) {
      return Icons.description_rounded;
    }

    if (value.contains('excel') ||
        value.contains('xls') ||
        value.contains('xlsx')) {
      return Icons.table_chart_rounded;
    }

    return Icons.insert_drive_file_rounded;
  }

  Widget _buildDocuments() {
    if (_documents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.pageBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun document joint.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _documents.map((document) {
        final map = document is Map<String, dynamic>
            ? document
            : <String, dynamic>{};

        final nom =
            map['nom_fichier']?.toString() ??
            map['filename']?.toString() ??
            map['nom']?.toString() ??
            'Document';

        final type =
            map['type_mime']?.toString() ??
            map['mime_type']?.toString() ??
            map['type_document']?.toString() ??
            '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: context.pageBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(child: Icon(_documentIcon(type, nom))),
            title: Text(nom, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: type.isNotEmpty ? Text(type) : null,
            trailing: IconButton(
              onPressed: _actionLoading ? null : () => _downloadDocument(map),
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Télécharger',
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBackground,
      appBar: AppBar(
        title: const Text('Détail de la déclaration'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _declaration == null
          ? const Center(child: Text('Déclaration introuvable.'))
          : _buildContent(_declaration!),
    );
  }

  Widget _buildContent(Declaration declaration) {
    final statusColor = _statusColor(declaration.statut);

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              color: context.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.assignment_rounded,
                        color: statusColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            declaration.periode,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _client?.nomComplet ??
                                'Client #${declaration.clientId}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        declaration.statutLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.indigo.withValues(alpha: 0.2),
                ),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_rounded,
                        color: Colors.indigo.shade700,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Générer la DSF de ce client pour un exercice donné.',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _actionLoading
                        ? null
                        : () => _genererDsf(declaration),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Générer la DSF'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_client != null)
              _section(
                title: 'Informations du client',
                child: Column(
                  children: [
                    _infoRow('Nom / raison sociale', _client!.nomComplet),
                    _infoRow('Type', _client!.typeClient),
                    _infoRow('Téléphone', _client!.telephone),
                    _infoRow('Email', _client!.email ?? '—'),
                    _infoRow('Adresse', _client!.adresse ?? '—'),
                    _infoRow('Ville', _client!.ville ?? '—'),
                    _infoRow(
                      'N° contribuable',
                      _client!.numeroContribuable ?? '—',
                    ),
                    _infoRow(
                      'Registre de commerce',
                      _client!.registreCommerce ?? '—',
                    ),
                  ],
                ),
              ),

            _section(
              title: 'Informations fiscales',
              child: Column(
                children: [
                  _infoRow('Mois', declaration.moisLabel),
                  _infoRow('Année', declaration.annee.toString()),
                  _infoRow(
                    'Chiffre d’affaires',
                    '${_formatNumber(declaration.chiffreAffaires)} FCFA',
                  ),
                  _infoRow(
                    'Total des ventes',
                    '${_formatNumber(declaration.totalVentes)} FCFA',
                  ),
                  _infoRow(
                    'Total des achats',
                    '${_formatNumber(declaration.totalAchats)} FCFA',
                  ),
                  _infoRow(
                    'Nombre d’employés',
                    declaration.nombreEmployes.toString(),
                  ),
                ],
              ),
            ),

            _section(
              title: 'Suivi de la déclaration',
              child: Column(
                children: [
                  _infoRow('Créée le', _formatDate(declaration.dateCreation)),
                  _infoRow(
                    'Soumise le',
                    _formatDate(declaration.dateSoumission),
                  ),
                  _infoRow(
                    'Traitée le',
                    _formatDate(declaration.dateValidation),
                  ),
                  _infoRow(
                    'Traitée par',
                    declaration.traiteParId?.toString() ?? '—',
                  ),
                ],
              ),
            ),

            if (declaration.observations != null &&
                declaration.observations!.trim().isNotEmpty)
              _section(
                title: 'Observations du client',
                child: Text(
                  declaration.observations!,
                  style: const TextStyle(height: 1.5),
                ),
              ),

            if (declaration.commentaireAdmin != null &&
                declaration.commentaireAdmin!.trim().isNotEmpty)
              _section(
                title: 'Commentaire administratif',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    declaration.commentaireAdmin!,
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ),

            _section(title: 'Documents joints', child: _buildDocuments()),

            _section(title: 'Traitement', child: _buildActions(declaration)),
          ],
        ),
      ),
    );
  }
}
