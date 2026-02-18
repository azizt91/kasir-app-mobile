import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../datasources/dashboard_remote_data_source.dart';
import 'package:mobile_app/features/transaction/data/datasources/transaction_local_data_source.dart';

import 'package:mobile_app/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final TransactionLocalDataSource transactionLocalDataSource; // Add this

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.transactionLocalDataSource,
  });

  @override
  Future<Either<Failure, DashboardModel>> getDashboardData() async {
    try {
      final remoteData = await remoteDataSource.getDashboardData();
      final pendingTransactions = await transactionLocalDataSource.getPendingTransactions();
      
      // We can either return a new model that combines both, or modify the stats in the model.
      // Let's assume we modify the 'stats' map to include 'pending_sync_count'
      // Or better, create a specific field in DashboardModel if we can change it.
      // Since DashboardModel is strict, let's inject it into 'stats' map for now for simplicity
      // or wrapping it in a domain entity.
      // Let's modify the stats map.
      final newStats = Map<String, dynamic>.from(remoteData.stats);
      newStats['pending_sync_count'] = pendingTransactions.length;
      
      return Right(DashboardModel(
        stats: newStats, 
        salesChart: remoteData.salesChart, 
        topProducts: remoteData.topProducts,
        lowStockItems: remoteData.lowStockItems,
      ));

    } catch (e) {
      // If offline, maybe return local stats only?
      // For now, adhering to original plan of returning failure if API fails, 
      // but ideally we should return local cached data + pending count.
      // Let's just return failure with message, but we could improve this for full offline dashboard.
      return Left(ServerFailure(e.toString()));
    }
  }
}
