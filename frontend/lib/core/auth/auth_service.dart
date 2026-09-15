import 'package:dio/dio.dart';

import '../../models/utilisateur.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import 'token_storage.dart';

class AuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Utilisateur> login({
    required String email,
    required String motDePasse,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'mot_de_passe': motDePasse,
        },
      );

      final data = response.data as Map<String, dynamic>;

      final token = data['access_token'] as String;

      await _tokenStorage.saveToken(token);

      return Utilisateur.fromJson(
        data['user'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];

      if (detail is String) {
        throw Exception(detail);
      }

      throw Exception(
        'Impossible de contacter le serveur.',
      );
    }
  }

  Future<void> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    String? telephone,
  }) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.register,
        data: {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'mot_de_passe': motDePasse,
          if (telephone != null && telephone.isNotEmpty)
            'telephone': telephone,
        },
      );
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];

      if (detail is String) {
        throw Exception(detail);
      }

      throw Exception(
        'Impossible de créer le compte.',
      );
    }
  }

  Future<Utilisateur> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.me,
      );

      return Utilisateur.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];

      if (detail is String) {
        throw Exception(detail);
      }

      throw Exception(
        'Impossible de récupérer l’utilisateur connecté.',
      );
    }
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
  }

  Future<bool> isAuthenticated() async {
    return _tokenStorage.hasToken();
  }
}
