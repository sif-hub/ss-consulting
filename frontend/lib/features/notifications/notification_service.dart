
import '../../core/api/api_client.dart';
import '../../models/notification.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotificationModel>> getNotifications({
    bool nonLues = false,
    String? type,
    int limit = 100,
  }) async {
    final response = await _apiClient.dio.get(
      '/notifications',
      queryParameters: {
        'non_lues': nonLues,
        if (type != null && type.isNotEmpty) 'type': type,
        'limit': limit,
      },
    );

    final data = response.data as List;

    return data
        .map(
          (json) => NotificationModel.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get(
      '/notifications/non-lues/count',
    );

    return (response.data['count'] as num).toInt();
  }

  Future<NotificationModel> markAsRead(int notificationId) async {
    final response = await _apiClient.dio.patch(
      '/notifications/$notificationId/lire',
    );

    return NotificationModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<int> markAllAsRead() async {
    final response = await _apiClient.dio.patch(
      '/notifications/lire-toutes',
    );

    return (response.data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> deleteNotification(int notificationId) async {
    await _apiClient.dio.delete(
      '/notifications/$notificationId',
    );
  }
}
