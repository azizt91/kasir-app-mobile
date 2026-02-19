import 'package:dio/dio.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<void> updateFcmToken(String token);
}


class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  // Replace with your actual local IP address for emulator (e.g., 10.0.2.2 for Android Emulator, or your LAN IP)
  // For Real Device, use your machine's LAN IP (e.g., 192.168.1.x)

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
          'device_name': 'mobile_app',
        },
        options: Options(
          headers: {'Accept': 'application/json'},
          validateStatus: (status) => status! < 500, // Let 401 pass to be handled manually
        ),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid credentials');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> updateFcmToken(String token) async {
    try {
      await dio.post('/user/fcm-token', data: {'fcm_token': token});
    } catch (e) {
      // Ignore error or log it
      print("Error updating FCM token: $e");
    }
  }
}
