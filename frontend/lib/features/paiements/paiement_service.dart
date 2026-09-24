import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../models/paiement.dart';

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

  /// Paiement Mobile Money sans redirection : Fapshi envoie la demande de
  /// confirmation directement sur le téléphone du client. Renvoie l'id du
  /// paiement à suivre via [verifierStatutFapshi].
  Future<int> payerDirectFapshi({
    required int factureId,
    required double montant,
    required String telephone,
  }) async {
    try {
      final Response response = await _apiClient.dio.post(
        '/paiements/fapshi/direct',
        data: {
          'facture_id': factureId,
          'montant': montant,
          'telephone': telephone,
        },
      );

      return (response.data as Map)['paiement_id'] as int;
    } on DioException catch (e) {
      final data = e.response?.data;
      final detail = data is Map ? data['detail'] : null;

      throw Exception(
        detail is String
            ? detail
            : 'Impossible de contacter le service de paiement.',
      );
    }
  }

  /// Interroge directement Fapshi pour rafraîchir le statut d'un
  /// paiement en attente (utilisé pendant que le client confirme sur
  /// son téléphone, avant que le webhook ne confirme côté serveur).
  Future<Map<String, dynamic>> verifierStatutFapshi(int paiementId) async {
    final Response response = await _apiClient.dio.get(
      '/paiements/fapshi/$paiementId/statut',
    );

    return Map<String, dynamic>.from(response.data as Map);
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
