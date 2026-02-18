import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart'; // Import Dio
import '../../../../core/error/failures.dart';
import '../datasources/product_local_data_source.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../../../transaction/data/repositories/transaction_repository_impl.dart';

abstract class SyncRepository {
  Future<Either<Failure, void>> syncProducts();
}

class SyncRepositoryImpl implements SyncRepository {
  final ProductLocalDataSource localDataSource;
  final ProductRemoteDataSource remoteDataSource;

  final TransactionRepository transactionRepository;

  SyncRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.transactionRepository,
  });

  @override
  Future<Either<Failure, void>> syncProducts() async {
    try {
      String? lastSync = await localDataSource.getLastSyncTime();
      
      // Check if local DB is empty to force full sync
      final localProducts = await localDataSource.getCachedProducts();
      if (localProducts.isEmpty) {
        print('SyncRepository: Local DB is empty. Forcing full sync.');
        lastSync = null; 
      }

      // 1. Sync Pending Transactions to Server FIRST
      // This ensures server has latest sales before we fetch stock/products
      print('SyncRepository: Syncing Pending Transactions...');
      await transactionRepository.syncPendingTransactions();

      final data = await remoteDataSource.syncProducts(lastSync);

      final List<dynamic> categoriesJson = data['categories'];
      final List<dynamic> productsJson = data['products'];
      final String timestamp = data['timestamp'];

      // Upsert Categories
      final categories = categoriesJson.map((e) => CategoryModel.fromJson(e)).toList();
      await localDataSource.cacheCategories(categories);

      // Upsert Products
      print('SyncRepository: Products to save: ${productsJson.length}');
      final products = productsJson.map((e) => ProductModel.fromJson(e)).toList();
      await localDataSource.cacheProducts(products);
      print('SyncRepository: Products saved to local DB');

      // Save new timestamp
      await localDataSource.saveLastSyncTime(timestamp);

      return const Right(null);

    } catch (e) {
      print('SyncRepository Error: $e');
      if (e is DioError) {
         print('DioError Response: ${e.response?.data}');
         print('DioError Message: ${e.message}');
      }
      return Left(ServerFailure(e.toString()));
    }
  }
}
