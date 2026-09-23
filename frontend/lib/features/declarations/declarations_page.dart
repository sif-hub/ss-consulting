import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

import '../../core/auth/auth_service.dart';
import '../../models/declaration.dart';
import '../../models/utilisateur.dart';
import 'declaration_form_page.dart';
import 'declaration_service.dart';

class DeclarationsPage extends StatefulWidget {
  const DeclarationsPage({super.key});

  @override
  State<DeclarationsPage> createState() => _DeclarationsPageState();
}

class _DeclarationsPageState extends State<DeclarationsPage> {
  final DeclarationService _service = DeclarationService();
  final AuthService _authService = AuthService();

  bool _loading = true;
  bool _processing = false;
  String? _error;

  List<Declaration> _declarations = [];
  Utilisateur? _user;

  bool get _isClient => _user?.userRole == UserRole.client;

  bool get _isFiscaliste =>
      _user?.userRole == UserRole.fiscaliste;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final user = await _authService.getCurrentUser();

      if (!mounted) return;

      setState(() {
        _user = user;
      });

      await _loadDeclarations();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de récupérer votre profil.';
      });
    }
  }

  Future<void> _loadDeclarations() async {
    if (_user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final declarations = await _service.getDeclarations();

      if (!mounted) return;

      setState(() {
        _declarations = declarations;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger les déclarations.';
      });
    }
  }

  Color _statusColor(String statut) {
    switch (statut) {
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

      case 'BROUILLON':
      default:
        return AppColors.neutral;
    }
  }

  Future<void> _createDeclaration() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DeclarationFormPage(),
      ),
    );

    if (result == true && mounted) {
      await _loadDeclarations();
    }
  }

  Future<void> _submit(Declaration declaration) async {
    try {
      setState(() {
        _processing = true;
      });

      await _service.submitDeclaration(declaration.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Déclaration soumise avec succès.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await _loadDeclarations();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la soumission : $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Future<void> _startReview(Declaration declaration) async {
    try {
      setState(() {
        _processing = true;
      });

      await _service.startReview(declaration.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Déclaration placée en vérification.',
          ),
          backgroundColor: Colors.blue,
        ),
      );

      await _loadDeclarations();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du démarrage de la vérification : $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Future<void> _review(Declaration declaration) async {
    String? selectedStatus;
    final commentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Traiter la déclaration',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      declaration.periode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Décision',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'VALIDEE',
                          child: Text('Valider'),
                        ),
                        DropdownMenuItem(
                          value: 'A_CORRIGER',
                          child: Text('Demander une correction'),
                        ),
                        DropdownMenuItem(
                          value: 'REJETEE',
                          child: Text('Rejeter'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Commentaire',
                        hintText:
                            'Ajouter une remarque ou une justification...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: selectedStatus == null
                      ? null
                      : () {
                          Navigator.pop(dialogContext, true);
                        },
                  icon: const Icon(Icons.check),
                  label: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true ||
        selectedStatus == null ||
        !mounted) {
      commentController.dispose();
      return;
    }

    try {
      setState(() {
        _processing = true;
      });

      await _service.reviewDeclaration(
        id: declaration.id,
        statut: selectedStatus!,
        commentaireAdmin:
            commentController.text.trim().isEmpty
                ? null
                : commentController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Déclaration traitée avec succès.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await _loadDeclarations();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du traitement : $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      commentController.dispose();

      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  String get _pageTitle {
    if (_isClient) {
      return 'Mes déclarations';
    }

    if (_isFiscaliste) {
      return 'Déclarations fiscales';
    }

    return 'Déclarations fiscales';
  }

  String get _pageSubtitle {
    if (_isClient) {
      return 'Déposez et suivez vos déclarations fiscales.';
    }

    if (_isFiscaliste) {
      return 'Vérifiez et traitez les déclarations des clients.';
    }

    return 'Consultation des déclarations fiscales.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        actions: [
          IconButton(
            onPressed: _processing ? null : _loadDeclarations,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),

      floatingActionButton: _isClient
          ? FloatingActionButton.extended(
              onPressed:
                  _processing ? null : _createDeclaration,
              icon: const Icon(Icons.add),
              label: const Text(
                'Nouvelle déclaration',
              ),
            )
          : null,

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 55,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _initialize,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeclarations,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        children: [
          _buildHeaderCard(),

          const SizedBox(height: 20),

          if (_declarations.isEmpty)
            _buildEmptyState()
          else
            ..._declarations.map(
              (declaration) =>
                  _buildDeclarationCard(declaration),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _isFiscaliste
                ? Colors.deepPurple
                : Colors.blue,
            _isFiscaliste
                ? Colors.deepPurple.shade300
                : Colors.blue.shade300,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                Colors.white.withValues(alpha: 0.18),
            child: Icon(
              _isFiscaliste
                  ? Icons.fact_check_rounded
                  : Icons.description_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _pageTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _pageSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _isFiscaliste
                ? 'Aucune déclaration à traiter.'
                : 'Aucune déclaration trouvée.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_isClient)
            Text(
              'Créez votre première déclaration fiscale.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeclarationCard(
    Declaration declaration,
  ) {
    final statusColor =
        _statusColor(declaration.statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        declaration.periode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isClient)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 4,
                          ),
                          child: Text(
                            'Client #${declaration.clientId}',
                            style: TextStyle(
                              color:
                                  Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    declaration.statutLabel,
                  ),
                  backgroundColor:
                      statusColor.withValues(
                    alpha: 0.12,
                  ),
                  labelStyle: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            _info(
              'Chiffre d’affaires',
              '${declaration.chiffreAffaires.toStringAsFixed(0)} FCFA',
            ),

            _info(
              'Total ventes',
              '${declaration.totalVentes.toStringAsFixed(0)} FCFA',
            ),

            _info(
              'Total achats',
              '${declaration.totalAchats.toStringAsFixed(0)} FCFA',
            ),

            _info(
              'Employés',
              declaration.nombreEmployes.toString(),
            ),

            if (declaration.observations != null &&
                declaration.observations!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInformationBox(
                icon: Icons.notes_rounded,
                title: 'Observations',
                text: declaration.observations!,
              ),
            ],

            if (declaration.commentaireAdmin != null &&
                declaration.commentaireAdmin!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInformationBox(
                icon: Icons.comment_rounded,
                title: 'Commentaire du fiscaliste',
                text: declaration.commentaireAdmin!,
                warning: true,
              ),
            ],

            if (_isClient &&
                (declaration.estBrouillon ||
                    declaration.aCorriger)) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _processing
                      ? null
                      : () => _submit(declaration),
                  icon: const Icon(Icons.send_rounded),
                  label: Text(
                    declaration.aCorriger
                        ? 'Soumettre après correction'
                        : 'Soumettre',
                  ),
                ),
              ),
            ],

            if (_isFiscaliste &&
                declaration.estSoumise) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _processing
                      ? null
                      : () => _startReview(
                            declaration,
                          ),
                  icon: const Icon(
                    Icons.manage_search_rounded,
                  ),
                  label: const Text(
                    'Commencer la vérification',
                  ),
                ),
              ),
            ],

            if (_isFiscaliste &&
                declaration.enVerification) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _processing
                          ? null
                          : () => _review(
                                declaration,
                              ),
                      icon: const Icon(
                        Icons.fact_check_rounded,
                      ),
                      label: const Text(
                        'Traiter',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInformationBox({
    required IconData icon,
    required String title,
    required String text,
    bool warning = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warning
            ? Colors.orange.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: warning
              ? Colors.orange.withValues(alpha: 0.20)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: warning
                ? Colors.orange.shade700
                : Colors.grey.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
