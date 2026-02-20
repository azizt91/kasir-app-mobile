import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/expense_model.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, List<ExpenseModel>>> getExpenses();
  Future<Either<Failure, void>> createExpense(Map<String, dynamic> data);
  Future<Either<Failure, void>> updateExpense(int id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteExpense(int id);
  Future<void> syncPendingExpenses();
}
