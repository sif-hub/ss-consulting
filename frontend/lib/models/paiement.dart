class Paiement {
  final int id;
  final int factureId;
  final double montant;
  final String modePaiement;
  final String? operateur;
  final String? transactionId;
  final String? numeroClient;
  final double frais;
  final double tauxCommission;
  final double montantCommission;
  final double montantTotal;
  final String? reference;
  final DateTime? datePaiement;
  final String statut;
  final String? notes;
  final bool actif;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Paiement({
    required this.id,
    required this.factureId,
    required this.montant,
    required this.modePaiement,
    this.operateur,
    this.transactionId,
    this.numeroClient,
    required this.frais,
    required this.tauxCommission,
    required this.montantCommission,
    required this.montantTotal,
    this.reference,
    this.datePaiement,
    required this.statut,
    this.notes,
    required this.actif,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Paiement.fromJson(Map<String, dynamic> json) {
    return Paiement(
      id: json['id'] as int,
      factureId: json['facture_id'] as int,
      montant: (json['montant'] as num).toDouble(),
      modePaiement: json['mode_paiement'] as String,
      operateur: json['operateur'] as String?,
      transactionId: json['transaction_id'] as String?,
      numeroClient: json['numero_client'] as String?,
      frais: (json['frais'] as num?)?.toDouble() ?? 0,
      tauxCommission:
          (json['taux_commission'] as num?)?.toDouble() ?? 2,
      montantCommission:
          (json['montant_commission'] as num?)?.toDouble() ?? 0,
      montantTotal:
          (json['montant_total'] as num?)?.toDouble() ?? 0,
      reference: json['reference'] as String?,
      datePaiement: json['date_paiement'] != null
          ? DateTime.parse(json['date_paiement'] as String)
          : null,
      statut: json['statut'] as String? ?? 'En attente',
      notes: json['notes'] as String?,
      actif: json['actif'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'facture_id': factureId,
      'montant': montant,
      'mode_paiement': modePaiement,
      'operateur': operateur,
      'transaction_id': transactionId,
      'numero_client': numeroClient,
      'frais': frais,
      'taux_commission': tauxCommission,
      'montant_commission': montantCommission,
      'montant_total': montantTotal,
      'reference': reference,
      'date_paiement': datePaiement?.toIso8601String(),
      'statut': statut,
      'notes': notes,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
