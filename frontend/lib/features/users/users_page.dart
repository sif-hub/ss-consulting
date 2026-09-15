import 'package:flutter/material.dart';

import '../../models/utilisateur.dart';
import 'user_form_page.dart';
import 'user_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  List<Utilisateur> _users = [];
  List<Map<String, dynamic>> _roles = [];

  bool _loading = true;
  String? _error;

  bool? _actifFilter;
  int? _roleFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _userService.getUsers(
          actif: _actifFilter,
          roleId: _roleFilter,
          search: _searchController.text,
        ),
        _userService.getRoles(),
      ]);

      if (!mounted) return;

      setState(() {
        _users = results[0] as List<Utilisateur>;
        _roles = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _search() async {
    await _loadData();
  }

  Future<void> _openCreate() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const UserFormPage(),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _openEdit(Utilisateur user) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UserFormPage(user: user),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _changePassword(Utilisateur user) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${user.prenom} ${user.nom}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Le mot de passe doit contenir au moins 6 caractères.',
                      ),
                    ),
                  );
                  return;
                }

                if (controller.text != confirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Les mots de passe ne correspondent pas.'),
                    ),
                  );
                  return;
                }

                try {
                  await _userService.changePassword(
                    userId: user.id,
                    motDePasse: controller.text,
                  );

                  if (!context.mounted) return;

                  Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    confirmController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe modifié avec succès.'),
        ),
      );
    }
  }

  Future<void> _toggleStatus(Utilisateur user) async {
    final action = user.actif ? 'désactiver' : 'activer';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${action[0].toUpperCase()}${action.substring(1)} le compte'),
          content: Text(
            'Voulez-vous vraiment $action le compte de '
            '${user.prenom} ${user.nom} ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action[0].toUpperCase() + action.substring(1)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      if (user.actif) {
        await _userService.deactivateUser(user.id);
      } else {
        await _userService.activateUser(user.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.actif
                ? 'Utilisateur désactivé.'
                : 'Utilisateur activé.',
          ),
        ),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  String _roleName(Utilisateur user) {
    return user.roleLabel;
  }

  Widget _buildUserCard(Utilisateur user) {
    final initials =
        '${user.prenom.isNotEmpty ? user.prenom[0] : ''}'
        '${user.nom.isNotEmpty ? user.nom[0] : ''}'
            .toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          radius: 24,
          child: Text(
            initials,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.nomComplet,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: user.actif
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.red.withValues(alpha: 0.12),
              ),
              child: Text(
                user.actif ? 'Actif' : 'Inactif',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: user.actif ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email),
              if (user.telephone != null &&
                  user.telephone!.trim().isNotEmpty)
                Text(user.telephone!),
              const SizedBox(height: 4),
              Text(
                _roleName(user),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _openEdit(user);
                break;
              case 'password':
                _changePassword(user);
                break;
              case 'status':
                _toggleStatus(user);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Modifier'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'password',
              child: ListTile(
                leading: Icon(Icons.lock_reset),
                title: Text('Changer le mot de passe'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'status',
              child: ListTile(
                leading: Icon(
                  Icons.power_settings_new,
                ),
                title: Text(
                  'Activer / Désactiver',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<bool?>(
                    initialValue: _actifFilter,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<bool?>(
                        value: null,
                        child: Text('Tous'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: true,
                        child: Text('Actifs'),
                      ),
                      DropdownMenuItem<bool?>(
                        value: false,
                        child: Text('Inactifs'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _actifFilter = value;
                      });
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _roleFilter,
                    decoration: const InputDecoration(
                      labelText: 'Rôle',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tous les rôles'),
                      ),
                      ..._roles.map(
                        (role) => DropdownMenuItem<int?>(
                          value: (role['id'] as num).toInt(),
                          child: Text(
                            role['nom']?.toString() ?? '',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _roleFilter = value;
                      });
                      _loadData();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
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
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Icon(
              Icons.people_outline,
              size: 64,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Aucun utilisateur trouvé.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          return _buildUserCard(_users[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildFilters(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildContent(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.person_add),
        label: const Text('Nouvel utilisateur'),
      ),
    );
  }
}
