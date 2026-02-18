import 'package:dartz/dartz.dart';
import '../../data/models/user_model.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserModel>> login(String email, String password);
  Future<void> logout();
  Future<Either<Failure, UserModel>> getCurrentUser();
}
