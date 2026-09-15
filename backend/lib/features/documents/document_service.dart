import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../models/document.dart';

class DocumentService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Document>> getDocuments(int dossierId) async {
    final Response response = await _apiClient.dio.get(
      '/dossiers/$dossierId/documents',
    );

    final data = response.data;

    if (data is! List) {
      throw Exception('Réponse invalide du serveur');
    }

    return data
        .map(
          (item) => Document.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<Document> createDocument(
    int dossierId,
    Map<String, dynamic> data,
  ) async {
    final Response response = await _apiClient.dio.post(
      '/dossiers/$dossierId/documents',
      data: {
        ...data,
        'dossier_id': dossierId,
      },
    );

    return Document.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deleteDocument(int documentId) async {
    await _apiClient.dio.delete(
      '/documents/$documentId',
    );
  }
}
