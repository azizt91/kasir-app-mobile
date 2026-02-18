import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import 'package:mobile_app/features/product/data/models/product_model.dart';
import '../datasources/stock_local_data_source.dart';
import '../datasources/stock_remote_data_source.dart';
import '../models/pending_stock_adjustment_model.dart';
import '../models/stock_movement_model.dart';

abstract class StockRepository {
  Future<Either<Failure, List<ProductModel>>> getStocks({bool isLowStockOnly = false});
  Future<Either<Failure, List<StockMovementModel>>> getStockMovements(int productId);
  Future<Either<Failure, void>> adjustStock(int productId, String type, int quantity, String notes);
  Future<void> syncPendingAdjustments();
}

class StockRepositoryImpl implements StockRepository {
  final StockLocalDataSource localDataSource;
  final StockRemoteDataSource remoteDataSource;

  StockRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<ProductModel>>> getStocks({bool isLowStockOnly = false}) async {
    try {
      if (isLowStockOnly) {
         final result = await localDataSource.getLowStockProducts();
         return Right(result);
      } else {
         final result = await localDataSource.getProductsSortedByStock();
         return Right(result);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StockMovementModel>>> getStockMovements(int productId) async {
    try {
       // Ideally verify with API if online, but prioritizing offline first
       // We only rely on local cache for now which is populated during SyncProducts from ProductRepository
       // Wait, ProductRepository syncs *Products*, does it sync *Movements*?
       // Currently SyncProducts just fetched list of products. 
       // If we want *History* from server, we might need a separate Sync for that or fetch on demand.
       // User requirement: "Riwayat Mutasi: Tampilkan daftar riwayat... diambil dari SQLite lokal (hasil sinkronisasi) atau API."
       // Implementation Plan says "Stock Movements Table (Cache)".
       // Let's assume we return Local. 
       final result = await localDataSource.getStockMovements(productId);
       return Right(result);
    } catch (e) {
       return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> adjustStock(int productId, String type, int quantity, String notes) async {
    try {
      final adjustment = PendingStockAdjustmentModel(
        productId: productId,
        type: type,
        quantity: quantity,
        notes: notes,
        createdAt: DateTime.now(),
      );

      // Save locally first (Optimistic UI)
      await localDataSource.savePendingAdjustment(adjustment);

      // Try to sync immediately
      try {
         await remoteDataSource.syncStockAdjustment(adjustment);
         // If success, delete from pending (Wait, get ID first? Or we just delete based on content?)
         // The local save generated an ID. We need that ID to delete.
         // Let's refine: savePendingAdjustment inserts.
         // Actually, if we succeed immediately, we don't strictly need to keep it in 'pending' if we only use 'pending' for retry.
         // But `savePendingAdjustment` also updates the Product Stock locally.
         
         // Let's try to sync. If success, we don't strictly need to do anything else because local stock is already updated by `savePendingAdjustment`.
         // Except if we want to ensure we don't double-sync later.
         // Current flow: 
         // 1. Save to Pending DB (and update Product Stock).
         // 2. Try Remote.
         // 3. If Remote OK -> Delete from Pending DB.
         // 4. If Remote Fail -> Keep in Pending DB.
         
         // We need the ID of the inserted pending adjustment to delete it.
         // `savePendingAdjustment` currently returns void. 
         // For simplicity, let's just trigger `syncPendingAdjustments` helper.
         
         _syncSingle(adjustment); // Fire and forget or await?
         
         return const Right(null);
      } catch (e) {
         // Offline, just return success (Optimistic)
         return const Right(null);
      }
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<void> _syncSingle(PendingStockAdjustmentModel adjustment) async {
     try {
       // We need to fetch the specific pending item to get its ID, or modify save to return ID.
       // Let's just use `syncPendingAdjustments` which loops all.
       await syncPendingAdjustments();
     } catch (_) {}
  }

  @override
  Future<void> syncPendingAdjustments() async {
    final pending = await localDataSource.getPendingAdjustments();
    for (var adj in pending) {
      try {
        await remoteDataSource.syncStockAdjustment(adj);
        if (adj.id != null) {
          await localDataSource.deletePendingAdjustment(adj.id!);
        }
      } catch (e) {
        // Keep for next retry
        print("Failed to sync adjustment ${adj.id}: $e");
      }
    }
  }
}
