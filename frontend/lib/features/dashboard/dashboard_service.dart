import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../models/dashboard_stats.dart';

class DashboardService {
  final ApiClient _apiClient = ApiClient();

  Future<DashboardStats> getStats() async {
    final Response response = await _apiClient.dio.get(
      '/dashboard/stats',
    );

    return DashboardStats.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
