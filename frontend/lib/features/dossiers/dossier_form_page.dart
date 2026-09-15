import 'package:flutter/material.dart';

import '../../models/client.dart';
import '../../models/dossier.dart';
import '../clients/client_service.dart';
import 'dossier_service.dart';

class DossierFormPage extends StatefulWidget {
  final Dossier? dossier;
  final int? clientId;

  const DossierFormPage({
    super.key,
    this.dossier,
    this.clientId,
  });

  @override
  State<DossierFormPage> createState() => _DossierFormPageState();
}

class _DossierFormPageState extends State<DossierFormPage> {
  final _formKey = GlobalKey<FormState>();

  final DossierService _dossierService = DossierService();
  final ClientService _clientService = ClientService();

  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Client> _clients = [];
  Client? _selectedClient;

  String _typeDossier = 'Fiscalité';
  String _statut = 'En cours';
  String _priorite = 'Normale';

  bool _loadingClients = true;
  bool _saving = false;

  final List<String> _typesDossier = [
    'Fiscalité',
    'Comptabilité',
    'Juridique',
    'Social',
    'Administratif',
    'Création entreprise',
    'Autre',
  ];

  final List<String> _statuts = [
    'En cours',
    'En attente',
    'Terminé',
    'Annulé',
  ];

  final List<String> _priorites = [
    'Basse',
    'Normale',
    'Haute',
    'Urgente',
  ];

  bool get _isEditing => widget.dossier != null;

  @override
  void initState() {
    super.initState();

    final dossier = widget.dossier;

    if (dossier != null) {
      _titreController.text = dossier.titre;
      _descriptionController.text = dossier.description ?? '';
      _typeDossier = dossier.typeDossier;
      _statut = dossier.statut;
      _priorite = dossier.priorite;
    }

    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await _clientService.getClients();

      if (!mounted) return;

      Client? selected;

      final targetClientId =
          widget.dossier?.clientId ?? widget.clientId;

      if (targetClientId != null) {
        for (final client in clients) {
          if (client.id == targetClientId) {
            selected = client;
            break;
          }
        }
      }

      setState(() {
        _clients = clients;
        _selectedClient = selected;
        _loadingClients = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingClients = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un client.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final data = {
      'client_id': _selectedClient!.id,
      'titre': _titreController.text.trim(),
      'type_dossier': _typeDossier,
      'description': _emptyToNull(
        _descriptionController.text,
      ),
      'statut': _statut,
      'priorite': _priorite,
      'actif': true,
    };

    try {
      if (_isEditing) {
        await _dossierService.updateDossier(
          widget.dossier!.id,
          data,
        );
      } else {
        await _dossierService.createDossier(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Dossier modifié avec succès.'
                : 'Dossier créé avec succès.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erreur lors de l'enregistrement : $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Modifier le dossier' : 'Nouveau dossier',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _section(
              title: 'Client',
              icon: Icons.person_rounded,
              child: _buildClientSelector(),
            ),

            const SizedBox(height: 16),

            _section(
              title: 'Informations du dossier',
              icon: Icons.folder_rounded,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titreController,
                    decoration: _inputDecoration(
                      'Titre du dossier',
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
                    initialValue: _typeDossier,
                    decoration: _inputDecoration(
                      'Type de dossier',
                      Icons.category_rounded,
                    ),
                    items: _typesDossier
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _typeDossier = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _statut,
                    decoration: _inputDecoration(
                      'Statut',
                      Icons.track_changes_rounded,
                    ),
                    items: _statuts
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
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
                    decoration: _inputDecoration(
                      'Priorité',
                      Icons.priority_high_rounded,
                    ),
                    items: _priorites
                        .map(
                          (priority) => DropdownMenuItem(
                            value: priority,
                            child: Text(priority),
                          ),
                        )
                        .toList(),
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
                    decoration: _inputDecoration(
                      'Description',
                      Icons.notes_rounded,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _saving
                      ? 'Enregistrement...'
                      : _isEditing
                          ? 'Enregistrer les modifications'
                          : 'Créer le dossier',
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSelector() {
    if (_loadingClients) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_clients.isEmpty) {
      return const Text(
        'Aucun client disponible. Créez d’abord un client.',
      );
    }

    return DropdownButtonFormField<Client>(
      initialValue: _selectedClient,
      isExpanded: true,
      decoration: _inputDecoration(
        'Client',
        Icons.business_rounded,
      ),
      items: _clients
          .map(
            (client) => DropdownMenuItem<Client>(
              value: client,
              child: Text(
                client.nomComplet,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (client) {
        setState(() {
          _selectedClient = client;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Sélectionnez un client';
        }
        return null;
      },
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF3155D9),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
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
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF3155D9),
          width: 1.5,
        ),
      ),
    );
  }
}
