import 'package:dio/dio.dart';
import 'package:mobile_app/features/auth/data/datasources/auth_remote_data_source.dart';

import '../models/dashboard_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardModel> getDashboardData();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio dio;

  DashboardRemoteDataSourceImpl({required this.dio});

  @override
  Future<DashboardModel> getDashboardData() async {
    try {
      final response = await dio.get(
        '/dashboard',
        options: Options(
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        return DashboardModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e, stackTrace) {
      print('Dashboard Error: $e');
      print('Stack Trace: $stackTrace');
      throw Exception('Dashboard Error: $e');
    }
  }
}
