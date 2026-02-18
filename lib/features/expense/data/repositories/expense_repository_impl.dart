import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../datasources/expense_data_source.dart';
import '../models/expense_model.dart';
import 'dart:convert';

abstract class ExpenseRepository {
  Future<Either<Failure, List<ExpenseModel>>> getExpenses();
  Future<Either<Failure, void>> createExpense(Map<String, dynamic> data);
  Future<Either<Failure, void>> updateExpense(int id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteExpense(int id);
  Future<void> syncPendingExpenses();
}

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;
  final ExpenseLocalDataSource localDataSource;

  ExpenseRepositoryImpl({required this.remoteDataSource, required this.localDataSource});

  @override
  Future<Either<Failure, List<ExpenseModel>>> getExpenses() async {
    try {
      // 1. Fetch Remote
      final remote = await remoteDataSource.getExpenses();
      await localDataSource.cacheExpenses(remote);
      
      // 2. Fetch Pending
      final pending = await localDataSource.getPendingExpenses();
      
      // 3. Return Combined
      // Note: We might want to sort them differently, but for now simple concat
      return Right([...pending, ...remote]);
      
    } catch (e) {
      try {
        final cached = await localDataSource.getCachedExpenses();
        final pending = await localDataSource.getPendingExpenses();
        return Right([...pending, ...cached]);
      } catch (e2) {
        return Left(CacheFailure(e2.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, void>> createExpense(Map<String, dynamic> data) async {
    try {
       // 1. Try Online
       // Ideally: Cache valid Pending -> Sync -> Cache Remote.
       // User requirement: Support Offline. So Always Cache Pending first or try remote then fallback?
       // Let's try: Cache Pending -> Background Sync attempt.
       
       await localDataSource.cachePendingExpense(data);
       await syncPendingExpenses();
       return const Right(null);
       
    } catch (e) {
       // Should not fail if we cached it.
       return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateExpense(int id, Map<String, dynamic> data) async {
    try {
      // For now, assuming online-first for updates/deletes OR handled by sync if complex
      // Simple approach: Try remote, if success refresh list. If fail, show error.
      // Offline support for update/delete is complex (conflicts), saving for later if requested.
      await remoteDataSource.updateExpense(id, data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(int id) async {
    try {
      await remoteDataSource.deleteExpense(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> syncPendingExpenses() async {
    final pending = await localDataSource.getPendingExpensesRaw();
    for (var p in pending) {
       try {
         final payload = jsonDecode(p['payload']);
         await remoteDataSource.createExpense(payload);
         await localDataSource.deletePendingExpense(p['id']);
       } catch (e) {
         // Keep waiting
         print('Expense Sync Failed: $e');
       }
    }
  }
}
