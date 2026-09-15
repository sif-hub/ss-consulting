import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../models/utilisateur.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Utilisateur>> getUsers({
    bool? actif,
    int? roleId,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{};

    if (actif != null) {
      queryParameters['actif'] = actif;
    }

    if (roleId != null) {
      queryParameters['role_id'] = roleId;
    }

    final cleanedSearch = search?.trim();

    if (cleanedSearch != null && cleanedSearch.isNotEmpty) {
      queryParameters['search'] = cleanedSearch;
    }

    final response = await _apiClient.dio.get(
      '/users',
      queryParameters: queryParameters,
    );

    final data = response.data as List;

    return data
        .map(
          (json) => Utilisateur.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getRoles() async {
    final response = await _apiClient.dio.get('/users/roles');

    final data = response.data as List;

    return data
        .map(
          (json) => Map<String, dynamic>.from(json as Map),
        )
        .toList();
  }

  Future<Utilisateur> createUser({
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    required String motDePasse,
    required int roleId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/users',
        data: {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'telephone': telephone,
          'mot_de_passe': motDePasse,
          'role_id': roleId,
        },
      );

      return Utilisateur.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];

      if (detail is String) {
        throw Exception(detail);
      }

      throw Exception(
        'Impossible de créer l’utilisateur.',
      );
    }
  }

  Future<Utilisateur> updateUser({
    required int userId,
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    required int roleId,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/users/$userId',
        data: {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'telephone': telephone,
          'role_id': roleId,
        },
      );

      return Utilisateur.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];

      if (detail is String) {
        throw Exception(detail);
      }

      throw Exception(
        'Impossible de modifier l’utilisateur.',
      );
    }
  }

  Future<Utilisateur> activateUser(int userId) async {
    final response = await _apiClient.dio.patch(
      '/users/$userId/activer',
    );

    return Utilisateur.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Utilisateur> deactivateUser(int userId) async {
    final response = await _apiClient.dio.patch(
      '/users/$userId/desactiver',
    );

    return Utilisateur.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> changePassword({
    required int userId,
    required String motDePasse,
  }) async {
    try {
      await _apiClient.dio.patch(
        '/users/$userId/mot-de-passe',
        data: {
          'mot_de_passe': motDePasse,
        },
      );
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];

      if (detail is String) {
        throw Exception(detail);
      }

      throw Exception(
        'Impossible de modifier le mot de passe.',
      );
    }
  }
}
