import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import 'package:mobile_app/features/history/data/models/transaction_model.dart';
import '../../../../core/database/database_helper.dart';
import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';

// --- DataSource Interface ---
abstract class ReceivableRemoteDataSource {
  Future<List<TransactionModel>> getReceivables();
  Future<void> markAsPaid(int id, String method);
}

abstract class ReceivableLocalDataSource {
  Future<List<TransactionModel>> getCachedReceivables();
  Future<void> cacheReceivables(List<TransactionModel> transactions);
  Future<void> updateLocalTransactionStatus(int id, String method);
}

// --- Implementation ---
class ReceivableRemoteDataSourceImpl implements ReceivableRemoteDataSource {
  final Dio dio;
  ReceivableRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<TransactionModel>> getReceivables() async {
    try {
      final response = await dio.get('/receivables');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        print('DEBUG RECEIVABLES REMOTE: Found ${data.length} items');
        if (data.isNotEmpty) {
           print('DEBUG FIRST ITEM: ${data.first}');
        }
        return data.map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch receivables');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Dio Error');
    }
  }

  @override
  Future<void> markAsPaid(int id, String method) async {
    try {
      final response = await dio.patch('/transactions/$id/mark-as-paid', data: {'payment_method': method});
      if (response.statusCode != 200) {
        throw ServerFailure('Failed to mark as paid');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Dio Error');
    }
  }
}

class ReceivableLocalDataSourceImpl implements ReceivableLocalDataSource {
  final DatabaseHelper databaseHelper;
  ReceivableLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<TransactionModel>> getCachedReceivables() async {
    final db = await databaseHelper.database;
    // Query local transactions where payment_method is 'utang'
    // Note: We need to check both 'transactions' (synced) and 'pending_transactions' (offline)
    // But usually receivables are synced first? 
    // If we support offline receivables creation, we check pending.
    
    // 1. Cached Synced
    final cached = await db.query('transactions', where: "payment_method = ?", whereArgs: ['utang']);
    print('DEBUG RECEIVABLES LOCAL CACHED: Found ${cached.length} items');
    
    // 2. Pending (Offline created)
    // Pending transactions payload is string, need to decode to check payment_method
    final pending = await db.query('pending_transactions', where: "status = ?", whereArgs: ['waiting']);
    
    List<TransactionModel> results = [];
    results.addAll(cached.map((json) => TransactionModel.fromJson(json)));
    
    for (var p in pending) {
       final tx = TransactionModel.fromPending(p);
       if (tx.paymentMethod == 'utang') {
         results.add(tx);
       }
    }
    
    return results;
  }

  @override
  Future<void> cacheReceivables(List<TransactionModel> transactions) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      // We shouldn't delete all transactions, only update/insert receivables.
      // Or maybe we treat 'transactions' as a full cache of interesting data.
      // For now, let's upsert.
      for (var tx in transactions) {
        await txn.insert(
          'transactions',
          tx.toCachedMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> updateLocalTransactionStatus(int id, String method) async {
     final db = await databaseHelper.database;
     // Need to read payload, update payment_method, save back.
     // Or just update columns if we rely on columns. `transactions` has `payment_method` column.
     await db.update(
       'transactions',
       {'payment_method': method},
       where: 'id = ?',
       whereArgs: [id],
     );
  }
}

// --- Repository ---
abstract class ReceivableRepository {
  Future<Either<Failure, List<TransactionModel>>> getReceivables();
  Future<Either<Failure, void>> markAsPaid(int id, String method);
}

class ReceivableRepositoryImpl implements ReceivableRepository {
  final ReceivableRemoteDataSource remoteDataSource;
  final ReceivableLocalDataSource localDataSource;

  ReceivableRepositoryImpl({required this.remoteDataSource, required this.localDataSource});

  @override
  Future<Either<Failure, List<TransactionModel>>> getReceivables() async {
    try {
      final remote = await remoteDataSource.getReceivables();
      await localDataSource.cacheReceivables(remote);
      
      // Return combined/local
      final local = await localDataSource.getCachedReceivables();
      return Right(local);
    } catch (e) {
      try {
        final local = await localDataSource.getCachedReceivables();
        return Right(local);
      } catch (e2) {
        return Left(CacheFailure(e2.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, void>> markAsPaid(int id, String method) async {
    try {
      await remoteDataSource.markAsPaid(id, method);
      await localDataSource.updateLocalTransactionStatus(id, method);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
