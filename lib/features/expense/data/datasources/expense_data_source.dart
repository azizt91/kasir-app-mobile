import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../models/expense_model.dart';
import '../../../../core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

// --- Interfaces ---
abstract class ExpenseRemoteDataSource {
  Future<List<ExpenseModel>> getExpenses();
  Future<void> createExpense(Map<String, dynamic> data);
  Future<void> updateExpense(int id, Map<String, dynamic> data);
  Future<void> deleteExpense(int id);
}

abstract class ExpenseLocalDataSource {
  Future<List<ExpenseModel>> getCachedExpenses();
  Future<List<ExpenseModel>> getPendingExpenses();
  Future<void> cacheExpenses(List<ExpenseModel> expenses);
  Future<void> cachePendingExpense(Map<String, dynamic> data);
  Future<void> deletePendingExpense(int id);
  Future<List<Map<String, dynamic>>> getPendingExpensesRaw();
}

// --- Implementations ---
class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final Dio dio;
  ExpenseRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final response = await dio.get('/expenses');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => ExpenseModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch expenses');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Dio Error');
    }
  }

  @override
  Future<void> createExpense(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/expenses', data: data);
      if (response.statusCode != 201) {
        throw ServerFailure('Failed to create expense');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Dio Error');
    }
  }

  Future<void> updateExpense(int id, Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/expenses/$id', data: data);
      if (response.statusCode != 200) {
        throw ServerFailure('Failed to update expense');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Dio Error');
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      final response = await dio.delete('/expenses/$id');
      if (response.statusCode != 200) {
        throw ServerFailure('Failed to delete expense');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Dio Error');
    }
  }
}

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  final DatabaseHelper databaseHelper;
  ExpenseLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<ExpenseModel>> getCachedExpenses() async {
    final db = await databaseHelper.database;
    final result = await db.query('expenses', orderBy: 'expense_date DESC');
    return result.map((json) => ExpenseModel.fromJson(json)).toList();
  }

  @override
  Future<List<ExpenseModel>> getPendingExpenses() async {
    final db = await databaseHelper.database;
    final result = await db.query('pending_expenses', where: "status = ?", whereArgs: ['waiting']);
    return result.map((json) => ExpenseModel.fromPending(json)).toList();
  }
  
  @override
  Future<List<Map<String, dynamic>>> getPendingExpensesRaw() async {
    final db = await databaseHelper.database;
    return await db.query('pending_expenses', where: "status = ?", whereArgs: ['waiting']);
  }

  @override
  Future<void> cacheExpenses(List<ExpenseModel> expenses) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete('expenses');
      for (var ex in expenses) {
        if (ex.id != null) {
          await txn.insert(
            'expenses',
            ex.toCachedMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  @override
  Future<void> cachePendingExpense(Map<String, dynamic> data) async {
    final db = await databaseHelper.database;
    await db.insert('pending_expenses', {
      'payload': jsonEncode(data),
      'expense_date': data['expense_date'],
      'status': 'waiting',
    });
  }

  @override
  Future<void> deletePendingExpense(int id) async {
    final db = await databaseHelper.database;
    await db.delete('pending_expenses', where: 'id = ?', whereArgs: [id]);
  }
}
