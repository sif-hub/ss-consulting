import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../models/depense.dart';

class DepenseService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Depense>> getDepenses({int skip = 0, int limit = 200}) async {
    final Response response = await _apiClient.dio.get(
      '/depenses',
      queryParameters: {'skip': skip, 'limit': limit},
    );

    final data = response.data;

    if (data is! List) {
      throw Exception('Réponse invalide du serveur');
    }

    return data
        .map((item) => Depense.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Depense> getDepense(int id) async {
    final Response response = await _apiClient.dio.get('/depenses/$id');

    return Depense.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Depense> createDepense(Map<String, dynamic> data) async {
    final Response response = await _apiClient.dio.post(
      '/depenses',
      data: data,
    );

    return Depense.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Depense> updateDepense(int id, Map<String, dynamic> data) async {
    final Response response = await _apiClient.dio.put(
      '/depenses/$id',
      data: data,
    );

    return Depense.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteDepense(int id) async {
    await _apiClient.dio.delete('/depenses/$id');
  }

  Future<Map<String, dynamic>> getStatistiquesTotal() async {
    final Response response = await _apiClient.dio.get(
      '/depenses/statistiques/total',
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getStatistiquesCategories() async {
    final Response response = await _apiClient.dio.get(
      '/depenses/statistiques/categories',
    );

    return List<dynamic>.from(
      response.data as List,
    ).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
