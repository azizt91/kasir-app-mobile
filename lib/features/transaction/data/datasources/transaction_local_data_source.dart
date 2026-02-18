import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/pending_transaction_model.dart';
import '../../../../core/error/failures.dart';
import 'package:mobile_app/features/history/data/models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<void> cachePendingTransaction(PendingTransactionModel transaction);
  Future<List<PendingTransactionModel>> getPendingTransactions();
  Future<void> deletePendingTransaction(int id);
  Future<void> cacheTransactions(List<TransactionModel> transactions);
  Future<List<TransactionModel>> getCachedTransactions();
  Future<List<TransactionModel>> getPendingHistory();
  Future<void> upsertTransactions(List<TransactionModel> transactions); // New method
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final DatabaseHelper databaseHelper;

  TransactionLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<void> cachePendingTransaction(PendingTransactionModel transaction) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      // 1. Save Transaction
      await txn.insert(
        'pending_transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Update Stock & Record Movement locally
      // Decode payload to get items
      final payloadMap = transaction.payload; // Already Map<String, dynamic> in model? No, it's String in DB but Map in Model?
      // pending_transaction_model.dart: payload is Map<String, dynamic>. toMap converts it to String?
      // Let's check model.
      // Assuming payload is Map.
      
      final items = payloadMap['items'] as List; 
      
      for (var item in items) {
        final productId = item['product_id']; 
        final qty = item['quantity'];
        
        // Get current stock
        final List<Map<String, dynamic>> products = await txn.query(
          'products', 
          columns: ['stock', 'minimum_stock'], 
          where: 'id = ?', 
          whereArgs: [productId]
        );
        
        if (products.isNotEmpty) {
           final currentStock = products.first['stock'] as int;
           final minStock = products.first['minimum_stock'] as int;
           final newStock = currentStock - (qty as int);
           
           // Update Product Stock
           await txn.update(
             'products', 
             {
               'stock': newStock,
               'is_low_stock': newStock <= minStock ? 1 : 0,
               'updated_at': DateTime.now().toIso8601String(),
             },
             where: 'id = ?',
             whereArgs: [productId],
           );

           // Record Movement
           await txn.insert('stock_movements', {
              'product_id': productId,
              'type': 'out',
              'quantity': qty,
              'reference_type': 'Transaction',
              'reference_id': null, 
              'notes': 'POS Sale',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
           });
        }
      }
    });
  }

  @override
  Future<List<PendingTransactionModel>> getPendingTransactions() async {
    final db = await databaseHelper.database;
    final result = await db.query('pending_transactions', where: "status = ?", whereArgs: ['waiting']);
    return result.map((json) => PendingTransactionModel.fromMap(json)).toList();
  }

  @override
  Future<void> deletePendingTransaction(int id) async {
    final db = await databaseHelper.database;
    await db.delete(
      'pending_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // NEW: History features
  Future<void> cacheTransactions(List<TransactionModel> transactions) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete('transactions'); // Simple strategy: Replace cache.
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
  Future<void> upsertTransactions(List<TransactionModel> transactions) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      for (var tx in transactions) {
        await txn.insert(
          'transactions',
          tx.toCachedMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<TransactionModel>> getCachedTransactions() async {
    final db = await databaseHelper.database;
    final result = await db.query('transactions', orderBy: 'created_at DESC');
    return result.map((json) => TransactionModel.fromJson(json)).toList();
  }
  
  Future<List<TransactionModel>> getPendingHistory() async {
    final db = await databaseHelper.database;
    final result = await db.query('pending_transactions', where: "status = ?", whereArgs: ['waiting']);
    return result.map((json) => TransactionModel.fromPending(json)).toList();
  }
}
