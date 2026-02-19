import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import '../../../../core/network/api_client.dart'; // Assuming exist
// If ApiClient doesn't exist, use Dio directly or find where Dio is provided.
// I'll check main.dart or injection container later. For now, assume Dio is passed.

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({int page = 1});
  Future<int> getUnreadCount();
  Future<void> markAllRead();
  Future<void> clearAll();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio dio;

  NotificationRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<NotificationModel>> getNotifications({int page = 1}) async {
    try {
      final response = await dio.get('/notifications', queryParameters: {'page': page});
      final List data = response.data['data'];
      return data.map((e) => NotificationModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await dio.get('/notifications/unread-count');
      return response.data['count'];
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> markAllRead() async {
    await dio.post('/notifications/mark-read');
  }

  @override
  Future<void> clearAll() async {
    await dio.delete('/notifications/clear');
  }
}
