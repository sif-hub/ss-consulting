import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../models/tache.dart';

class TacheService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Tache>> getTaches({
    int? dossierId,
    int? responsableId,
  }) async {
    final queryParameters = <String, dynamic>{
      'dossier_id': ?dossierId,
      'responsable_id': ?responsableId,
    };

    final Response response = await _apiClient.dio.get(
      '/taches',
      queryParameters: queryParameters,
    );

    final data = response.data;

    if (data is! List) {
      throw Exception('Réponse invalide du serveur');
    }

    return data
        .map(
          (item) => Tache.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<Tache> getTache(int id) async {
    final Response response = await _apiClient.dio.get('/taches/$id');

    return Tache.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Tache> createTache(Map<String, dynamic> data) async {
    final Response response = await _apiClient.dio.post(
      '/taches',
      data: data,
    );

    return Tache.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Tache> updateTache(
    int id,
    Map<String, dynamic> data,
  ) async {
    final Response response = await _apiClient.dio.put(
      '/taches/$id',
      data: data,
    );

    return Tache.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deleteTache(int id) async {
    await _apiClient.dio.delete('/taches/$id');
  }
}
