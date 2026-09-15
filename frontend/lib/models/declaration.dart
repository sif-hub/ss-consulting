class Declaration {
  final int id;
  final int clientId;
  final int mois;
  final int annee;
  final double chiffreAffaires;
  final double totalVentes;
  final double totalAchats;
  final int nombreEmployes;
  final String? observations;
  final String statut;
  final String? commentaireAdmin;
  final DateTime dateCreation;
  final DateTime? dateSoumission;
  final DateTime? dateValidation;
  final int? traiteParId;

  const Declaration({
    required this.id,
    required this.clientId,
    required this.mois,
    required this.annee,
    required this.chiffreAffaires,
    required this.totalVentes,
    required this.totalAchats,
    required this.nombreEmployes,
    this.observations,
    required this.statut,
    this.commentaireAdmin,
    required this.dateCreation,
    this.dateSoumission,
    this.dateValidation,
    this.traiteParId,
  });

  factory Declaration.fromJson(Map<String, dynamic> json) {
    return Declaration(
      id: (json['id'] as num).toInt(),
      clientId: (json['client_id'] as num).toInt(),
      mois: (json['mois'] as num).toInt(),
      annee: (json['annee'] as num).toInt(),
      chiffreAffaires:
          double.parse(json['chiffre_affaires'].toString()),
      totalVentes:
          double.parse(json['total_ventes'].toString()),
      totalAchats:
          double.parse(json['total_achats'].toString()),
      nombreEmployes:
          (json['nombre_employes'] as num).toInt(),
      observations: json['observations']?.toString(),
      statut: json['statut']?.toString() ?? 'BROUILLON',
      commentaireAdmin:
          json['commentaire_admin']?.toString(),
      dateCreation:
          DateTime.parse(json['date_creation'].toString()),
      dateSoumission: json['date_soumission'] != null
          ? DateTime.parse(json['date_soumission'].toString())
          : null,
      dateValidation: json['date_validation'] != null
          ? DateTime.parse(json['date_validation'].toString())
          : null,
      traiteParId: json['traite_par_id'] != null
          ? (json['traite_par_id'] as num).toInt()
          : null,
    );
  }

  String get moisLabel {
    const labels = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];

    return labels[mois];
  }

  String get periode => '$moisLabel $annee';

  bool get estBrouillon => statut == 'BROUILLON';
  bool get estSoumise => statut == 'SOUMISE';
  bool get enVerification => statut == 'EN_VERIFICATION';
  bool get estValidee => statut == 'VALIDEE';
  bool get aCorriger => statut == 'A_CORRIGER';
  bool get estRejetee => statut == 'REJETEE';

  String get statutLabel {
    switch (statut) {
      case 'BROUILLON':
        return 'Brouillon';
      case 'SOUMISE':
        return 'Soumise';
      case 'EN_VERIFICATION':
        return 'En vérification';
      case 'VALIDEE':
        return 'Validée';
      case 'A_CORRIGER':
        return 'À corriger';
      case 'REJETEE':
        return 'Rejetée';
      default:
        return statut;
    }
  }
}
