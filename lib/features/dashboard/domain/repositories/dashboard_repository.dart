import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/dashboard_remote_data_source.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardModel>> getDashboardData();
}
