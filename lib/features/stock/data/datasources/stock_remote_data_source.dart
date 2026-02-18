import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../models/pending_stock_adjustment_model.dart';
import '../../../../features/product/data/models/product_model.dart';

abstract class StockRemoteDataSource {
  Future<void> syncStockAdjustment(PendingStockAdjustmentModel adjustment);
  // Future<List<StockMovementModel>> getStockHistory(int productId); // Optional if API exists
}

class StockRemoteDataSourceImpl implements StockRemoteDataSource {
  final Dio dio;

  StockRemoteDataSourceImpl({required this.dio});

  @override
  Future<void> syncStockAdjustment(PendingStockAdjustmentModel adjustment) async {
    try {
      final response = await dio.post(
        '/products/${adjustment.productId}/adjust',
        data: {
          'type': adjustment.type,
          'quantity': adjustment.quantity,
          'notes': adjustment.notes,
          'created_at': adjustment.createdAt.toIso8601String(),
        },
      );

      if (response.statusCode != 200) {
        throw ServerFailure('Failed to sync stock adjustment');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.message ?? 'Dio Error');
    }
  }
}
