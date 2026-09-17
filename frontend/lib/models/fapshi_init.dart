class FapshiInit {
  final int paiementId;
  final int factureId;
  final String reference;
  final double montant;
  final String statut;
  final String paymentLink;

  const FapshiInit({
    required this.paiementId,
    required this.factureId,
    required this.reference,
    required this.montant,
    required this.statut,
    required this.paymentLink,
  });

  factory FapshiInit.fromJson(Map<String, dynamic> json) {
    return FapshiInit(
      paiementId: json['paiement_id'] as int,
      factureId: json['facture_id'] as int,
      reference: json['reference'] as String,
      montant: (json['montant'] as num).toDouble(),
      statut: json['statut'] as String? ?? 'En attente',
      paymentLink: json['payment_link'] as String,
    );
  }
}
