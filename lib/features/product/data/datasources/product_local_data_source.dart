import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ProductLocalDataSource {
  Future<void> cacheProducts(List<ProductModel> products);
  Future<void> cacheCategories(List<CategoryModel> categories);
  Future<List<ProductModel>> getCachedProducts();
  Future<List<CategoryModel>> getCachedCategories();
  Future<void> saveLastSyncTime(String timestamp);
  Future<String?> getLastSyncTime();
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final DatabaseHelper databaseHelper;
  final SharedPreferences sharedPreferences;

  ProductLocalDataSourceImpl({
    required this.databaseHelper,
    required this.sharedPreferences,
  });

  @override
  Future<void> cacheCategories(List<CategoryModel> categories) async {
    final db = await databaseHelper.database;
    final batch = db.batch();

    for (var category in categories) {
      batch.insert(
        'categories',
        category.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    final db = await databaseHelper.database;
    final batch = db.batch();

    for (var product in products) {
      // Upsert product group if needed? 
      // For now, focusing on flat product list or just products table as defined.
      // API returns flat products list? 
      // My ProductController returns 'products' and 'groups'.
      // I should also cache groups if I defined the table.
      // But let's stick to the requested task: "Implement ProductLocalDataSource for CRUD... products and categories".
      // The schema has product_groups. 
      // I will assume for now we just upsert products. 
      
      batch.insert(
        'products',
        product.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<CategoryModel>> getCachedCategories() async {
    final db = await databaseHelper.database;
    final result = await db.query('categories');
    return result.map((json) => CategoryModel.fromJson(json)).toList();
  }

  @override
  Future<List<ProductModel>> getCachedProducts() async {
    final db = await databaseHelper.database;
    final result = await db.query('products');
    return result.map((json) => ProductModel.fromJson(json)).toList();
  }

  @override
  Future<String?> getLastSyncTime() async {
    return sharedPreferences.getString('last_sync_timestamp');
  }

  @override
  Future<void> saveLastSyncTime(String timestamp) async {
    await sharedPreferences.setString('last_sync_timestamp', timestamp);
  }
}
