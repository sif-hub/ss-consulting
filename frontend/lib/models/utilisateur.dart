enum UserRole {
  administrateur,
  managerSecretariat,
  secretaire,
  fiscaliste,
  comptable,
  client,
  inconnu,
}

class Utilisateur {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final int roleId;
  final int? clientId;
  final String role;
  final bool actif;

  const Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    required this.roleId,
    this.clientId,
    required this.role,
    required this.actif,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: (json['id'] as num).toInt(),
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      telephone: json['telephone']?.toString(),
      roleId: (json['role_id'] as num).toInt(),
      clientId: (json['client_id'] as num?)?.toInt(),
      role: json['role']?.toString() ?? '',
      actif: json['actif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'role_id': roleId,
      'client_id': clientId,
      'role': role,
      'actif': actif,
    };
  }

  String get nomComplet => '$prenom $nom';

  UserRole get userRole {
    switch (roleId) {
      case 1:
        return UserRole.administrateur;
      case 2:
        return UserRole.managerSecretariat;
      case 3:
        return UserRole.secretaire;
      case 4:
        return UserRole.fiscaliste;
      case 5:
        return UserRole.comptable;
      case 6:
        return UserRole.client;
      default:
        return UserRole.inconnu;
    }
  }

  String get roleLabel {
    switch (userRole) {
      case UserRole.administrateur:
        return 'Administrateur';
      case UserRole.managerSecretariat:
        return 'Manager Secretariat';
      case UserRole.secretaire:
        return 'Secrétaire';
      case UserRole.fiscaliste:
        return 'Fiscaliste';
      case UserRole.comptable:
        return 'Comptable';
      case UserRole.client:
        return 'Client';
      case UserRole.inconnu:
        return role.isNotEmpty ? role : 'Rôle inconnu';
    }
  }
}
