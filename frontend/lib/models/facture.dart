class Facture {
  final int id;
  final String numero;
  final int clientId;
  final int? dossierId;
  final DateTime dateEmission;
  final DateTime? dateEcheance;
  final double montantHt;
  final double tauxTva;
  final double? montantTva;
  final double? montantTtc;
  final String statut;
  final String? modePaiement;
  final String? notes;
  final bool actif;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Facture({
    required this.id,
    required this.numero,
    required this.clientId,
    this.dossierId,
    required this.dateEmission,
    this.dateEcheance,
    required this.montantHt,
    required this.tauxTva,
    this.montantTva,
    this.montantTtc,
    required this.statut,
    this.modePaiement,
    this.notes,
    required this.actif,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Facture.fromJson(Map<String, dynamic> json) {
    return Facture(
      id: json['id'] as int,
      numero: json['numero'] as String,
      clientId: json['client_id'] as int,
      dossierId: json['dossier_id'] as int?,
      dateEmission: DateTime.parse(
        json['date_emission'] as String,
      ),
      dateEcheance: json['date_echeance'] != null
          ? DateTime.parse(json['date_echeance'] as String)
          : null,
      montantHt: (json['montant_ht'] as num?)?.toDouble() ?? 0,
      tauxTva: (json['taux_tva'] as num?)?.toDouble() ?? 19.25,
      montantTva: (json['montant_tva'] as num?)?.toDouble(),
      montantTtc: (json['montant_ttc'] as num?)?.toDouble(),
      statut: json['statut'] as String? ?? 'Brouillon',
      modePaiement: json['mode_paiement'] as String?,
      notes: json['notes'] as String?,
      actif: json['actif'] as bool? ?? true,
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'client_id': clientId,
      'dossier_id': dossierId,
      'date_emission': dateEmission.toIso8601String(),
      'date_echeance': dateEcheance?.toIso8601String(),
      'montant_ht': montantHt,
      'taux_tva': tauxTva,
      'montant_tva': montantTva,
      'montant_ttc': montantTtc,
      'statut': statut,
      'mode_paiement': modePaiement,
      'notes': notes,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
