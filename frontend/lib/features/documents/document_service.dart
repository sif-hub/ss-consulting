import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/token_storage.dart';
import '../../models/document.dart';

class DocumentService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

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

  Future<List<Document>> getAllDocuments({String? search}) async {
    final Response response = await _apiClient.dio.get(
      '/documents',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
      },
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

  /// URL directe (avec jeton en paramètre) permettant d'ouvrir ou de
  /// télécharger le fichier d'un document dans le navigateur, sans
  /// pouvoir positionner d'en-tête Authorization.
  Future<String> getDownloadUrl(int documentId) async {
    final token = await _tokenStorage.getToken();

    return Uri.parse(
      '${ApiClient.baseUrl}/documents/$documentId/fichier',
    ).replace(
      queryParameters: {
        if (token != null && token.isNotEmpty) 'token': token,
      },
    ).toString();
  }
}
