import 'package:flutter/material.dart';

import '../../models/client.dart';
import 'client_service.dart';

class ClientFormPage extends StatefulWidget {
  final Client? client;

  const ClientFormPage({super.key, this.client});

  bool get isEditing => client != null;

  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ClientService _clientService = ClientService();

  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _raisonSocialeController;
  late final TextEditingController _emailController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _adresseController;
  late final TextEditingController _villeController;
  late final TextEditingController _numeroContribuableController;
  late final TextEditingController _registreCommerceController;

  // Informations fiscales
  late final TextEditingController _secteurActiviteController;
  late final TextEditingController _regimeFiscalController;
  late final TextEditingController _communeController;
  late final TextEditingController _quartierController;
  late final TextEditingController _lieuDitController;
  late final TextEditingController _statutOccupationController;

  late final TextEditingController _notesController;

  String _typeClient = 'Entreprise';
  bool _assujettiTva = false;
  bool _margeAdministree = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final client = widget.client;

    _nomController = TextEditingController(text: client?.nom ?? '');
    _prenomController = TextEditingController(text: client?.prenom ?? '');
    _raisonSocialeController = TextEditingController(
      text: client?.raisonSociale ?? '',
    );
    _emailController = TextEditingController(text: client?.email ?? '');
    _telephoneController = TextEditingController(text: client?.telephone ?? '');
    _adresseController = TextEditingController(text: client?.adresse ?? '');
    _villeController = TextEditingController(text: client?.ville ?? '');
    _numeroContribuableController = TextEditingController(
      text: client?.numeroContribuable ?? '',
    );
    _registreCommerceController = TextEditingController(
      text: client?.registreCommerce ?? '',
    );

    _secteurActiviteController = TextEditingController(
      text: client?.secteurActivite ?? '',
    );
    _regimeFiscalController = TextEditingController(
      text: client?.regimeFiscal ?? '',
    );
    _communeController = TextEditingController(text: client?.commune ?? '');
    _quartierController = TextEditingController(text: client?.quartier ?? '');
    _lieuDitController = TextEditingController(text: client?.lieuDit ?? '');
    _statutOccupationController = TextEditingController(
      text: client?.statutOccupation ?? '',
    );

    _assujettiTva = client?.assujettiTva ?? false;
    _margeAdministree = client?.margeAdministree ?? false;

    _notesController = TextEditingController(text: client?.notes ?? '');

    _typeClient = client?.typeClient ?? 'Entreprise';
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _raisonSocialeController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _numeroContribuableController.dispose();
    _registreCommerceController.dispose();

    _secteurActiviteController.dispose();
    _regimeFiscalController.dispose();
    _communeController.dispose();
    _quartierController.dispose();
    _lieuDitController.dispose();
    _statutOccupationController.dispose();

    _notesController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final data = {
      'nom': _nomController.text.trim(),
      'prenom': _emptyToNull(_prenomController.text),
      'raison_sociale': _emptyToNull(_raisonSocialeController.text),
      'email': _emptyToNull(_emailController.text),
      'telephone': _telephoneController.text.trim(),
      'adresse': _emptyToNull(_adresseController.text),
      'ville': _emptyToNull(_villeController.text),
      'numero_contribuable': _emptyToNull(_numeroContribuableController.text),
      'registre_commerce': _emptyToNull(_registreCommerceController.text),
      'type_client': _typeClient,

      // Informations fiscales
      'secteur_activite': _emptyToNull(_secteurActiviteController.text),
      'assujetti_tva': _assujettiTva,
      'marge_administree': _margeAdministree,
      'regime_fiscal': _emptyToNull(_regimeFiscalController.text),
      'commune': _emptyToNull(_communeController.text),
      'quartier': _emptyToNull(_quartierController.text),
      'lieu_dit': _emptyToNull(_lieuDitController.text),
      'statut_occupation': _emptyToNull(_statutOccupationController.text),

      'notes': _emptyToNull(_notesController.text),
    };

    try {
      if (widget.isEditing) {
        await _clientService.updateClient(widget.client!.id, data);
      } else {
        await _clientService.createClient(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Client modifié avec succès.'
                : 'Client créé avec succès.',
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
          content: Text("Erreur lors de l'enregistrement : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Modifier le client' : 'Nouveau client';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3155D9),
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSection(
              title: 'Informations générales',
              icon: Icons.business_rounded,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _typeClient,
                  decoration: _inputDecoration(
                    'Type de client',
                    Icons.category_rounded,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Entreprise',
                      child: Text('Entreprise'),
                    ),
                    DropdownMenuItem(
                      value: 'Particulier',
                      child: Text('Particulier'),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _typeClient = value;
                            });
                          }
                        },
                ),
                const SizedBox(height: 16),
                if (_typeClient == 'Entreprise')
                  _buildField(
                    controller: _raisonSocialeController,
                    label: 'Raison sociale',
                    icon: Icons.business_center_rounded,
                  ),
                if (_typeClient == 'Entreprise') const SizedBox(height: 16),
                _buildField(
                  controller: _nomController,
                  label: 'Nom',
                  icon: Icons.person_rounded,
                  validator: (value) =>
                      _required(value, 'Le nom est obligatoire.'),
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _prenomController,
                  label: 'Prénom',
                  icon: Icons.person_outline_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSection(
              title: 'Coordonnées',
              icon: Icons.contact_phone_rounded,
              children: [
                _buildField(
                  controller: _telephoneController,
                  label: 'Téléphone',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      _required(value, 'Le téléphone est obligatoire.'),
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }

                    if (!value.contains('@')) {
                      return 'Adresse email invalide.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _adresseController,
                  label: 'Adresse',
                  icon: Icons.location_on_rounded,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _villeController,
                  label: 'Ville',
                  icon: Icons.location_city_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSection(
              title: 'Informations administratives',
              icon: Icons.assignment_rounded,
              children: [
                _buildField(
                  controller: _numeroContribuableController,
                  label: 'Numéro contribuable',
                  icon: Icons.badge_rounded,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _registreCommerceController,
                  label: 'Registre de commerce / RCCM',
                  icon: Icons.menu_book_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSection(
              title: 'Informations fiscales',
              icon: Icons.account_balance_rounded,
              children: [
                _buildField(
                  controller: _secteurActiviteController,
                  label: 'Secteur d\'activité',
                  icon: Icons.business_center_rounded,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _regimeFiscalController,
                  label: 'Régime fiscal',
                  icon: Icons.account_balance_rounded,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Assujetti à la TVA',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Le client est soumis à la TVA.'),
                  secondary: const Icon(Icons.receipt_long_rounded),
                  value: _assujettiTva,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _assujettiTva = value;
                          });
                        },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Marge administrée',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Le client est soumis à une marge administrée.',
                  ),
                  secondary: const Icon(Icons.percent_rounded),
                  value: _margeAdministree,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _margeAdministree = value;
                          });
                        },
                ),
                const SizedBox(height: 8),
                _buildField(
                  controller: _communeController,
                  label: 'Commune',
                  icon: Icons.location_city_rounded,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _quartierController,
                  label: 'Quartier',
                  icon: Icons.location_on_rounded,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _lieuDitController,
                  label: 'Lieu-dit',
                  icon: Icons.place_rounded,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _statutOccupationController,
                  label: 'Statut d\'occupation',
                  icon: Icons.home_work_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSection(
              title: 'Notes',
              icon: Icons.notes_rounded,
              children: [
                _buildField(
                  controller: _notesController,
                  label: 'Notes complémentaires',
                  icon: Icons.sticky_note_2_rounded,
                  maxLines: 5,
                ),
              ],
            ),
            const SizedBox(height: 25),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3155D9),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
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
                    : widget.isEditing
                    ? 'Enregistrer les modifications'
                    : 'Créer le client',
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
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
                  fontSize: 17,
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      enabled: !_saving,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8F9FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFF3155D9), width: 2),
      ),
    );
  }
}
