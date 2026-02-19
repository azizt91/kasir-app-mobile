import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../models/notification_model.dart';
import '../datasources/notification_remote_data_source.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationModel>>> getNotifications({int page = 1});
  Future<Either<Failure, int>> getUnreadCount();
  Future<Either<Failure, void>> markAllRead();
  Future<Either<Failure, void>> clearAll();
}

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<NotificationModel>>> getNotifications({int page = 1}) async {
    try {
      final result = await remoteDataSource.getNotifications(page: page);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final result = await remoteDataSource.getUnreadCount();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    try {
      await remoteDataSource.markAllRead();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearAll() async {
    try {
      await remoteDataSource.clearAll();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
