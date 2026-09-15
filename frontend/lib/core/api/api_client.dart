import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // En développement local, pointe sur le backend local par défaut.
  // En production (Netlify, Vercel...), fournir l'URL du backend déployé
  // au moment du build :
  //   flutter build web --dart-define=API_BASE_URL=https://votre-backend.example.com/api/v1
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (error, handler) {
          debugPrint(
            'API ERROR: ${error.requestOptions.method} '
            '${error.requestOptions.uri}',
          );
          debugPrint(
            'STATUS: ${error.response?.statusCode}',
          );
          debugPrint(
            'DATA: ${error.response?.data}',
          );

          handler.next(error);
        },
      ),
    );
  }
}
