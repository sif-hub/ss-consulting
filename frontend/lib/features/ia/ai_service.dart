import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class ChatMessage {
  final String role;
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class DocumentAnalyse {
  final String typeDocument;
  final String resume;
  final List<String> montantsDetectes;
  final String dateDetectee;
  final String pointsAttention;

  const DocumentAnalyse({
    required this.typeDocument,
    required this.resume,
    required this.montantsDetectes,
    required this.dateDetectee,
    required this.pointsAttention,
  });

  factory DocumentAnalyse.fromJson(Map<String, dynamic> json) {
    return DocumentAnalyse(
      typeDocument: json['type_document']?.toString() ?? '',
      resume: json['resume']?.toString() ?? '',
      montantsDetectes:
          (json['montants_detectes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dateDetectee: json['date_detectee']?.toString() ?? '',
      pointsAttention: json['points_attention']?.toString() ?? '',
    );
  }
}

class AiService {
  final ApiClient _apiClient = ApiClient();

  Future<String> chat(List<ChatMessage> messages) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.iaChat,
        data: {'messages': messages.map((m) => m.toJson()).toList()},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      return Map<String, dynamic>.from(response.data as Map)['reponse']
              as String? ??
          '';
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<String> suggererObservations({
    required int mois,
    required int annee,
    required double chiffreAffaires,
    required double totalVentes,
    required double totalAchats,
    required int nombreEmployes,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.iaSuggestionDeclaration,
        data: {
          'mois': mois,
          'annee': annee,
          'chiffre_affaires': chiffreAffaires,
          'total_ventes': totalVentes,
          'total_achats': totalAchats,
          'nombre_employes': nombreEmployes,
        },
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      return Map<String, dynamic>.from(response.data as Map)['suggestion']
              as String? ??
          '';
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<DocumentAnalyse> analyserDocument(int documentId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.iaAnalyserDocument(documentId),
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );

      return DocumentAnalyse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  String _errorMessage(DioException e) {
    final data = e.response?.data;
    final detail = data is Map ? data['detail'] : null;

    if (detail is String) return detail;

    return 'Impossible de contacter l\'assistant IA.';
  }
}
