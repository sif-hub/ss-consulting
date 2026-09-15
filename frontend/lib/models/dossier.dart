class Dossier {
  final int id;
  final int clientId;
  final int? collaborateurId;
  final String titre;
  final String typeDossier;
  final String? description;
  final String statut;
  final String priorite;
  final DateTime dateOuverture;
  final DateTime? dateCloture;
  final bool actif;

  const Dossier({
    required this.id,
    required this.clientId,
    this.collaborateurId,
    required this.titre,
    required this.typeDossier,
    this.description,
    required this.statut,
    required this.priorite,
    required this.dateOuverture,
    this.dateCloture,
    required this.actif,
  });

  factory Dossier.fromJson(Map<String, dynamic> json) {
    return Dossier(
      id: json['id'] as int,
      clientId: json['client_id'] as int,
      collaborateurId: (json['collaborateur_id'] as num?)?.toInt(),
      titre: json['titre'] as String,
      typeDossier: json['type_dossier'] as String,
      description: json['description'] as String?,
      statut: json['statut'] as String? ?? 'En cours',
      priorite: json['priorite'] as String? ?? 'Normale',
      dateOuverture: DateTime.parse(json['date_ouverture'] as String),
      dateCloture: json['date_cloture'] != null
          ? DateTime.parse(json['date_cloture'] as String)
          : null,
      actif: json['actif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'collaborateur_id': collaborateurId,
      'titre': titre,
      'type_dossier': typeDossier,
      'description': description,
      'statut': statut,
      'priorite': priorite,
      'date_ouverture': dateOuverture.toIso8601String(),
      'date_cloture': dateCloture?.toIso8601String(),
      'actif': actif,
    };
  }
}
