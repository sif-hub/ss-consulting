class Client {
  final int id;
  final String nom;
  final String? prenom;
  final String? raisonSociale;
  final String? email;
  final String telephone;
  final String? adresse;
  final String? ville;
  final String? numeroContribuable;
  final String? registreCommerce;
  final String typeClient;

  // Informations fiscales et administratives complémentaires
  final String? secteurActivite;
  final bool assujettiTva;
  final bool margeAdministree;
  final String? regimeFiscal;
  final String? commune;
  final String? quartier;
  final String? lieuDit;
  final String? statutOccupation;

  final String? notes;
  final bool actif;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Client({
    required this.id,
    required this.nom,
    this.prenom,
    this.raisonSociale,
    this.email,
    required this.telephone,
    this.adresse,
    this.ville,
    this.numeroContribuable,
    this.registreCommerce,
    required this.typeClient,
    this.secteurActivite,
    this.assujettiTva = false,
    this.margeAdministree = false,
    this.regimeFiscal,
    this.commune,
    this.quartier,
    this.lieuDit,
    this.statutOccupation,
    this.notes,
    required this.actif,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String?,
      raisonSociale: json['raison_sociale'] as String?,
      email: json['email'] as String?,
      telephone: json['telephone'] as String,
      adresse: json['adresse'] as String?,
      ville: json['ville'] as String?,
      numeroContribuable: json['numero_contribuable'] as String?,
      registreCommerce: json['registre_commerce'] as String?,
      typeClient: json['type_client'] as String? ?? 'Entreprise',
      secteurActivite: json['secteur_activite'] as String?,
      assujettiTva: json['assujetti_tva'] as bool? ?? false,
      margeAdministree: json['marge_administree'] as bool? ?? false,
      regimeFiscal: json['regime_fiscal'] as String?,
      commune: json['commune'] as String?,
      quartier: json['quartier'] as String?,
      lieuDit: json['lieu_dit'] as String?,
      statutOccupation: json['statut_occupation'] as String?,
      notes: json['notes'] as String?,
      actif: json['actif'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'raison_sociale': raisonSociale,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'ville': ville,
      'numero_contribuable': numeroContribuable,
      'registre_commerce': registreCommerce,
      'type_client': typeClient,
      'secteur_activite': secteurActivite,
      'assujetti_tva': assujettiTva,
      'marge_administree': margeAdministree,
      'regime_fiscal': regimeFiscal,
      'commune': commune,
      'quartier': quartier,
      'lieu_dit': lieuDit,
      'statut_occupation': statutOccupation,
      'notes': notes,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get nomComplet {
    if (raisonSociale != null && raisonSociale!.trim().isNotEmpty) {
      return raisonSociale!;
    }

    final prenomValue = prenom?.trim() ?? '';

    if (prenomValue.isEmpty) {
      return nom;
    }

    return '$prenomValue $nom';
  }

  String get initiales {
    final source = nomComplet.trim();

    if (source.isEmpty) {
      return '?';
    }

    final parts = source.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
