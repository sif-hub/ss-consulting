import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../models/client.dart';

class ClientService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Client>> getClients() async {
    final Response response = await _apiClient.dio.get('/clients');

    final data = response.data;

    if (data is! List) {
      throw Exception('Réponse invalide du serveur');
    }

    return data
        .map(
          (item) => Client.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<Client> getClient(int id) async {
    final Response response = await _apiClient.dio.get('/clients/$id');

    return Client.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Client> createClient(Map<String, dynamic> data) async {
    final Response response = await _apiClient.dio.post(
      '/clients',
      data: data,
    );

    return Client.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Client> updateClient(
    int id,
    Map<String, dynamic> data,
  ) async {
    final Response response = await _apiClient.dio.put(
      '/clients/$id',
      data: data,
    );

    return Client.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deleteClient(int id) async {
    await _apiClient.dio.delete('/clients/$id');
  }

  Future<Map<String, dynamic>> getSituation(int id) async {
    final Response response = await _apiClient.dio.get(
      '/clients/$id/situation',
    );

    return Map<String, dynamic>.from(
      response.data as Map,
    );
  }
}
