import 'package:flutter/material.dart';

import '../../models/client.dart';
import '../../models/utilisateur.dart';
import '../clients/client_service.dart';
import 'user_service.dart';

const int _roleClientId = 6;

class UserFormPage extends StatefulWidget {
  final Utilisateur? user;

  const UserFormPage({
    super.key,
    this.user,
  });

  bool get isEditing => user != null;

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final ClientService _clientService = ClientService();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();

  List<Map<String, dynamic>> _roles = [];
  int? _selectedRoleId;

  List<Client> _clients = [];
  int? _selectedClientId;

  bool _loading = true;
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final roles = await _userService.getRoles();
      final clients = await _clientService.getClients();

      if (!mounted) return;

      setState(() {
        _roles = roles;
        _clients = clients;

        if (widget.user != null) {
          _nomController.text = widget.user!.nom;
          _prenomController.text = widget.user!.prenom;
          _emailController.text = widget.user!.email;
          _telephoneController.text = widget.user!.telephone ?? '';
          _selectedRoleId = widget.user!.roleId;
          _selectedClientId = widget.user!.clientId;
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un rôle.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final clientId =
          _selectedRoleId == _roleClientId ? _selectedClientId : null;

      if (widget.isEditing) {
        await _userService.updateUser(
          userId: widget.user!.id,
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          email: _emailController.text.trim(),
          telephone: _telephoneController.text.trim().isEmpty
              ? null
              : _telephoneController.text.trim(),
          roleId: _selectedRoleId!,
          clientId: clientId,
        );
      } else {
        await _userService.createUser(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          email: _emailController.text.trim(),
          telephone: _telephoneController.text.trim().isEmpty
              ? null
              : _telephoneController.text.trim(),
          motDePasse: _passwordController.text,
          roleId: _selectedRoleId!,
          clientId: clientId,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Utilisateur modifié avec succès.'
                : 'Utilisateur créé avec succès.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String? _validateName(String? value, String field) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '$field est obligatoire.';
    }

    if (text.length < 2) {
      return '$field doit contenir au moins 2 caractères.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'L’adresse email est obligatoire.';
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Adresse email invalide.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (widget.isEditing) {
      return null;
    }

    final password = value ?? '';

    if (password.isEmpty) {
      return 'Le mot de passe est obligatoire.';
    }

    if (password.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }

    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    if (widget.isEditing) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        validator: _validatePassword,
        decoration: InputDecoration(
          labelText: 'Mot de passe',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildRoleField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        initialValue: _selectedRoleId,
        decoration: const InputDecoration(
          labelText: 'Rôle',
          prefixIcon: Icon(Icons.badge_outlined),
          border: OutlineInputBorder(),
        ),
        items: _roles.map((role) {
          final id = (role['id'] as num).toInt();
          final nom = role['nom']?.toString() ?? '';

          return DropdownMenuItem<int>(
            value: id,
            child: Text(nom),
          );
        }).toList(),
        onChanged: _saving
            ? null
            : (value) {
                setState(() {
                  _selectedRoleId = value;
                });
              },
        validator: (value) {
          if (value == null) {
            return 'Veuillez sélectionner un rôle.';
          }

          return null;
        },
      ),
    );
  }

  Widget _buildClientField() {
    if (_selectedRoleId != _roleClientId) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int?>(
        initialValue: _selectedClientId,
        decoration: const InputDecoration(
          labelText: 'Client associé (optionnel)',
          helperText:
              'Peut être laissé vide et associé plus tard en modifiant '
              'le compte.',
          prefixIcon: Icon(Icons.business_outlined),
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Aucun pour l’instant'),
          ),
          ..._clients.map((client) {
            return DropdownMenuItem<int?>(
              value: client.id,
              child: Text(client.nomComplet),
            );
          }),
        ],
        onChanged: _saving
            ? null
            : (value) {
                setState(() {
                  _selectedClientId = value;
                });
              },
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _nomController,
            label: 'Nom',
            icon: Icons.person_outline,
            validator: (value) => _validateName(value, 'Le nom'),
          ),
          _buildTextField(
            controller: _prenomController,
            label: 'Prénom',
            icon: Icons.person,
            validator: (value) => _validateName(value, 'Le prénom'),
          ),
          _buildTextField(
            controller: _emailController,
            label: 'Adresse email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          _buildTextField(
            controller: _telephoneController,
            label: 'Téléphone',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          _buildRoleField(),
          _buildClientField(),
          _buildPasswordField(),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    widget.isEditing
                        ? Icons.save_outlined
                        : Icons.person_add_outlined,
                  ),
            label: Text(
              _saving
                  ? 'Enregistrement...'
                  : widget.isEditing
                      ? 'Enregistrer les modifications'
                      : 'Créer l’utilisateur',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing
        ? 'Modifier l’utilisateur'
        : 'Nouvel utilisateur';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 650,
                  ),
                  child: _buildForm(),
                ),
              ),
            ),
    );
  }
}
