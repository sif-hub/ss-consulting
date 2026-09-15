class Document {
  final int id;
  final int? dossierId;
  final int? declarationId;
  final String nom;
  final String typeDocument;
  final String? description;
  final String? cheminFichier;
  final String statut;
  final bool actif;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Document({
    required this.id,
    this.dossierId,
    this.declarationId,
    required this.nom,
    required this.typeDocument,
    this.description,
    this.cheminFichier,
    required this.statut,
    required this.actif,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as int,
      dossierId: json['dossier_id'] as int?,
      declarationId: json['declaration_id'] as int?,
      nom: json['nom'] as String,
      typeDocument: json['type_document'] as String,
      description: json['description'] as String?,
      cheminFichier: json['chemin_fichier'] as String?,
      statut: json['statut'] as String? ?? 'Actif',
      actif: json['actif'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dossier_id': dossierId,
      'declaration_id': declarationId,
      'nom': nom,
      'type_document': typeDocument,
      'description': description,
      'chemin_fichier': cheminFichier,
      'statut': statut,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
