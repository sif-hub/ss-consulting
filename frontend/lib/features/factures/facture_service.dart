import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../models/facture.dart';

class FactureService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Facture>> getFactures({
    int? clientId,
    int? dossierId,
  }) async {
    final queryParameters = <String, dynamic>{
      'client_id': ?clientId,
      'dossier_id': ?dossierId,
    };

    final Response response = await _apiClient.dio.get(
      '/factures',
      queryParameters: queryParameters,
    );

    final data = response.data;

    if (data is! List) {
      throw Exception('Réponse invalide du serveur');
    }

    return data
        .map(
          (item) => Facture.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<Facture> getFacture(int id) async {
    final Response response = await _apiClient.dio.get(
      '/factures/$id',
    );

    return Facture.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Facture> createFacture(
    Map<String, dynamic> data,
  ) async {
    final Response response = await _apiClient.dio.post(
      '/factures',
      data: data,
    );

    return Facture.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Facture> updateFacture(
    int id,
    Map<String, dynamic> data,
  ) async {
    final Response response = await _apiClient.dio.put(
      '/factures/$id',
      data: data,
    );

    return Facture.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deleteFacture(int id) async {
    await _apiClient.dio.delete(
      '/factures/$id',
    );
  }
}
