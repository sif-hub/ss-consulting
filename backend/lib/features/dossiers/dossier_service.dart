import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../models/dossier.dart';

class DossierService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Dossier>> getDossiers({
    int? clientId,
  }) async {
    final Response response = await _apiClient.dio.get(
      '/dossiers',
      queryParameters: clientId != null
          ? {'client_id': clientId}
          : null,
    );

    final data = response.data;

    if (data is! List) {
      throw Exception('Réponse invalide du serveur');
    }

    return data
        .map(
          (item) => Dossier.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<Dossier> getDossier(int id) async {
    final Response response = await _apiClient.dio.get(
      '/dossiers/$id',
    );

    return Dossier.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Dossier> createDossier(
    Map<String, dynamic> data,
  ) async {
    final Response response = await _apiClient.dio.post(
      '/dossiers',
      data: data,
    );

    return Dossier.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Dossier> updateDossier(
    int id,
    Map<String, dynamic> data,
  ) async {
    final Response response = await _apiClient.dio.put(
      '/dossiers/$id',
      data: data,
    );

    return Dossier.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deleteDossier(int id) async {
    await _apiClient.dio.delete('/dossiers/$id');
  }
}
