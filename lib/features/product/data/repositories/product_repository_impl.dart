import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../datasources/product_local_data_source.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource localDataSource;

  ProductRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<CategoryModel>>> getCategories() async {
    try {
      final categories = await localDataSource.getCachedCategories();
      return Right(categories);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductModel>>> getProducts() async {
    try {
      final products = await localDataSource.getCachedProducts();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
