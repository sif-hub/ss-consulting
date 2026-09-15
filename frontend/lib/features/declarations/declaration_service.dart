import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/api/api_client.dart';
import '../../models/declaration.dart';

class DeclarationService {
  final Dio _dio = ApiClient().dio;

  Future<List<Declaration>> getDeclarations({
    int? clientId,
    int? mois,
    int? annee,
    String? statut,
  }) async {
    final queryParameters = <String, dynamic>{};

    if (clientId != null) {
      queryParameters['client_id'] = clientId;
    }

    if (mois != null) {
      queryParameters['mois'] = mois;
    }

    if (annee != null) {
      queryParameters['annee'] = annee;
    }

    if (statut != null && statut.isNotEmpty) {
      queryParameters['statut'] = statut;
    }

    final response = await _dio.get(
      '/declarations',
      queryParameters: queryParameters,
    );

    final data = response.data as List;

    return data
        .map((json) => Declaration.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<Declaration> getDeclaration(int id) async {
    final response = await _dio.get('/declarations/$id');

    return Declaration.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<Declaration> createDeclaration({
    required int clientId,
    required int mois,
    required int annee,
    double chiffreAffaires = 0,
    double totalVentes = 0,
    double totalAchats = 0,
    int nombreEmployes = 0,
    String? observations,
  }) async {
    final response = await _dio.post(
      '/declarations',
      data: {
        'client_id': clientId,
        'mois': mois,
        'annee': annee,
        'chiffre_affaires': chiffreAffaires,
        'total_ventes': totalVentes,
        'total_achats': totalAchats,
        'nombre_employes': nombreEmployes,
        'observations': observations,
      },
    );

    return Declaration.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<Declaration> updateDeclaration({
    required int id,
    required int mois,
    required int annee,
    double chiffreAffaires = 0,
    double totalVentes = 0,
    double totalAchats = 0,
    int nombreEmployes = 0,
    String? observations,
  }) async {
    final response = await _dio.put(
      '/declarations/$id',
      data: {
        'mois': mois,
        'annee': annee,
        'chiffre_affaires': chiffreAffaires,
        'total_ventes': totalVentes,
        'total_achats': totalAchats,
        'nombre_employes': nombreEmployes,
        'observations': observations,
      },
    );

    return Declaration.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<Map<String, dynamic>> uploadDeclarationDocument({
    required int declarationId,
    required PlatformFile file,
    String? description,
  }) async {
    final bytes = await file.readAsBytes();

    final formData = FormData.fromMap({
      'fichier': MultipartFile.fromBytes(bytes, filename: file.name),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    });

    final response = await _dio.post(
      '/declarations/$declarationId/documents',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<Uint8List> downloadDeclarationDocument(int documentId) async {
    final response = await _dio.get<List<int>>(
      '/documents/$documentId/fichier',
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.data == null) {
      throw Exception('Le fichier téléchargé est vide.');
    }

    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> genererDsfPdf({
    required int clientId,
    required int annee,
  }) async {
    final response = await _dio.get<List<int>>(
      '/pdf/dsf/$clientId',
      queryParameters: {'annee': annee},
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.data == null) {
      throw Exception('Le document généré est vide.');
    }

    return Uint8List.fromList(response.data!);
  }

  Future<List<Map<String, dynamic>>> getDeclarationDocuments(
    int declarationId,
  ) async {
    final response = await _dio.get('/declarations/$declarationId/documents');

    final data = response.data as List;

    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<Declaration> submitDeclaration(int id) async {
    final response = await _dio.post('/declarations/$id/soumettre');

    return Declaration.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<Declaration> startReview(int id) async {
    final response = await _dio.post('/declarations/$id/verification');

    return Declaration.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<Declaration> reviewDeclaration({
    required int id,
    required String statut,
    String? commentaireAdmin,
  }) async {
    final response = await _dio.post(
      '/declarations/$id/traiter',
      data: {'statut': statut, 'commentaire_admin': commentaireAdmin},
    );

    return Declaration.fromJson(Map<String, dynamic>.from(response.data));
  }
}
