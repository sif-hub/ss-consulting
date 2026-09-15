import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../models/paiement.dart';
import '../../models/notchpay_init.dart';

class PaiementService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Paiement>> getPaiements({
    int? factureId,
  }) async {
    final queryParameters = <String, dynamic>{
      'facture_id': ?factureId,
    };

    final Response response = await _apiClient.dio.get(
      '/paiements',
      queryParameters: queryParameters,
    );

    final data = response.data;

    if (data is! List) {
      throw Exception('Réponse invalide du serveur');
    }

    return data
        .map(
          (item) => Paiement.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<Paiement> getPaiement(int id) async {
    final Response response = await _apiClient.dio.get(
      '/paiements/$id',
    );

    return Paiement.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Paiement> createPaiement(
    Map<String, dynamic> data,
  ) async {
    final Response response = await _apiClient.dio.post(
      '/paiements',
      data: data,
    );

    return Paiement.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Paiement> initierPaiementMobile(
    Map<String, dynamic> data,
  ) async {
    final Response response = await _apiClient.dio.post(
      '/paiements/mobile/initier',
      data: data,
    );

    return Paiement.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Paiement> confirmerPaiementMobile(
    int paiementId,
  ) async {
    final Response response = await _apiClient.dio.post(
      '/paiements/mobile/$paiementId/confirmer',
    );

    return Paiement.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<NotchPayInit> initierPaiementNotchPay({
    required int factureId,
    required double montant,
  }) async {
    final Response response = await _apiClient.dio.post(
      '/paiements/notchpay/initier',
      data: {
        'facture_id': factureId,
        'montant': montant,
      },
    );

    return NotchPayInit.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Paiement> updatePaiement(
    int id,
    Map<String, dynamic> data,
  ) async {
    final Response response = await _apiClient.dio.put(
      '/paiements/$id',
      data: data,
    );

    return Paiement.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deletePaiement(int id) async {
    await _apiClient.dio.delete(
      '/paiements/$id',
    );
  }

  Future<Map<String, dynamic>> getResumeFacture(
    int factureId,
  ) async {
    final Response response = await _apiClient.dio.get(
      '/paiements/facture/$factureId/resume',
    );

    return Map<String, dynamic>.from(
      response.data as Map,
    );
  }
}
