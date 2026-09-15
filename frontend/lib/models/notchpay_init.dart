class NotchPayInit {
  final int paiementId;
  final int factureId;
  final String reference;
  final double montant;
  final String statut;
  final String authorizationUrl;

  const NotchPayInit({
    required this.paiementId,
    required this.factureId,
    required this.reference,
    required this.montant,
    required this.statut,
    required this.authorizationUrl,
  });

  factory NotchPayInit.fromJson(Map<String, dynamic> json) {
    return NotchPayInit(
      paiementId: json['paiement_id'] as int,
      factureId: json['facture_id'] as int,
      reference: json['reference'] as String,
      montant: (json['montant'] as num).toDouble(),
      statut: json['statut'] as String? ?? 'En attente',
      authorizationUrl: json['authorization_url'] as String,
    );
  }
}
