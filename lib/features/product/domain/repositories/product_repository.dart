import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import 'package:mobile_app/features/product/data/models/category_model.dart';
import 'package:mobile_app/features/product/data/models/product_model.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<ProductModel>>> getProducts();
  Future<Either<Failure, List<CategoryModel>>> getCategories();
}
