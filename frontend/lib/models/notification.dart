class NotificationModel {
  final int id;
  final int utilisateurId;
  final String type;
  final String titre;
  final String message;
  final String? referenceType;
  final int? referenceId;
  final DateTime? dateEcheance;
  final bool lu;
  final DateTime? dateLecture;
  final bool actif;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.utilisateurId,
    required this.type,
    required this.titre,
    required this.message,
    this.referenceType,
    this.referenceId,
    this.dateEcheance,
    required this.lu,
    this.dateLecture,
    required this.actif,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      utilisateurId: json['utilisateur_id'] as int,
      type: json['type'] as String,
      titre: json['titre'] as String,
      message: json['message'] as String,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as int?,
      dateEcheance: json['date_echeance'] != null
          ? DateTime.tryParse(json['date_echeance'].toString())
          : null,
      lu: json['lu'] as bool? ?? false,
      dateLecture: json['date_lecture'] != null
          ? DateTime.tryParse(json['date_lecture'].toString())
          : null,
      actif: json['actif'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}
