class Depense {
  final int id;
  final String? fournisseur;
  final String description;
  final String categorie;
  final DateTime dateDepense;
  final double montantHt;
  final double tauxTva;
  final double? montantTva;
  final double? montantTtc;
  final String? modePaiement;
  final String? reference;
  final String statut;
  final String? justificatif;
  final String? notes;
  final bool actif;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Depense({
    required this.id,
    this.fournisseur,
    required this.description,
    required this.categorie,
    required this.dateDepense,
    required this.montantHt,
    required this.tauxTva,
    this.montantTva,
    this.montantTtc,
    this.modePaiement,
    this.reference,
    required this.statut,
    this.justificatif,
    this.notes,
    required this.actif,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Depense.fromJson(Map<String, dynamic> json) {
    return Depense(
      id: json['id'] as int,
      fournisseur: json['fournisseur'] as String?,
      description: json['description'] as String? ?? '',
      categorie: json['categorie'] as String? ?? 'Autre',
      dateDepense: DateTime.parse(json['date_depense'] as String),
      montantHt: (json['montant_ht'] as num?)?.toDouble() ?? 0,
      tauxTva: (json['taux_tva'] as num?)?.toDouble() ?? 19.25,
      montantTva: (json['montant_tva'] as num?)?.toDouble(),
      montantTtc: (json['montant_ttc'] as num?)?.toDouble(),
      modePaiement: json['mode_paiement'] as String?,
      reference: json['reference'] as String?,
      statut: json['statut'] as String? ?? 'Payée',
      justificatif: json['justificatif'] as String?,
      notes: json['notes'] as String?,
      actif: json['actif'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fournisseur': fournisseur,
      'description': description,
      'categorie': categorie,
      'date_depense': dateDepense.toIso8601String(),
      'montant_ht': montantHt,
      'taux_tva': tauxTva,
      'montant_tva': montantTva,
      'montant_ttc': montantTtc,
      'mode_paiement': modePaiement,
      'reference': reference,
      'statut': statut,
      'justificatif': justificatif,
      'notes': notes,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
