class Tache {
  final int id;
  final int dossierId;
  final int? responsableId;
  final String titre;
  final String? description;
  final String statut;
  final String priorite;
  final DateTime? dateEcheance;
  final DateTime dateCreation;
  final DateTime? dateTerminaison;
  final bool actif;

  const Tache({
    required this.id,
    required this.dossierId,
    this.responsableId,
    required this.titre,
    this.description,
    required this.statut,
    required this.priorite,
    this.dateEcheance,
    required this.dateCreation,
    this.dateTerminaison,
    required this.actif,
  });

  factory Tache.fromJson(Map<String, dynamic> json) {
    return Tache(
      id: json['id'] as int,
      dossierId: json['dossier_id'] as int,
      responsableId: json['responsable_id'] as int?,
      titre: json['titre'] as String,
      description: json['description'] as String?,
      statut: json['statut'] as String? ?? 'À faire',
      priorite: json['priorite'] as String? ?? 'Normale',
      dateEcheance: json['date_echeance'] != null
          ? DateTime.parse(json['date_echeance'] as String)
          : null,
      dateCreation: DateTime.parse(json['date_creation'] as String),
      dateTerminaison: json['date_terminaison'] != null
          ? DateTime.parse(json['date_terminaison'] as String)
          : null,
      actif: json['actif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dossier_id': dossierId,
      'responsable_id': responsableId,
      'titre': titre,
      'description': description,
      'statut': statut,
      'priorite': priorite,
      'date_echeance': dateEcheance?.toIso8601String(),
      'date_creation': dateCreation.toIso8601String(),
      'date_terminaison': dateTerminaison?.toIso8601String(),
      'actif': actif,
    };
  }
}
