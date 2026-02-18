import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import 'package:mobile_app/features/history/data/models/transaction_model.dart';
import 'package:mobile_app/features/transaction/data/models/pending_transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<TransactionModel> sendTransaction(Map<String, dynamic> transactionData);
  // NEW: Fetch and Void
  Future<List<TransactionModel>> getTransactions();
  Future<void> voidTransaction(int id);
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final Dio dio;

  TransactionRemoteDataSourceImpl({required this.dio});

  @override
  Future<TransactionModel> sendTransaction(Map<String, dynamic> transactionData) async {
    try {
      final response = await dio.post('/pos/transaction', data: transactionData);
      if (response.statusCode == 200 || response.statusCode == 201) {
          // Backend PosController returns {success: true, transaction: {...}}
          final data = response.data['transaction'] ?? response.data['data'];
          if (data == null) {
            throw ServerFailure('Invalid server response: no transaction data');
          }
          return TransactionModel.fromJson(data);
      } else {
         throw ServerFailure('Failed to sync transaction: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Dio Error');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await dio.get('/transactions');
      if (response.statusCode == 200) {
        List<dynamic> data;
        if (response.data is List) {
          data = response.data;
        } else if (response.data is Map && response.data.containsKey('data')) {
           data = response.data['data'] as List;
        } else {
           return [];
        }
        return data.map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        throw ServerFailure('Failed to fetch transactions');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Dio Error');
    }
  }

  @override
  Future<void> voidTransaction(int id) async {
    try {
      final response = await dio.delete('/transactions/$id');
      if (response.statusCode != 200) {
        throw ServerFailure('Failed to void transaction');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Dio Error');
    }
  }
}
