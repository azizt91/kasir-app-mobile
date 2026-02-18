import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';
import 'dart:convert';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage secureStorage;
  final DatabaseHelper databaseHelper; // Add this

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
    required this.databaseHelper, // Add this
  });

  @override
  Future<Either<Failure, UserModel>> login(String email, String password) async {
    try {
      final userModel = await remoteDataSource.login(email, password);
      
      // Save Token & User Data
      if (userModel.accessToken != null) {
        await secureStorage.write(key: 'access_token', value: userModel.accessToken);
        await secureStorage.write(key: 'user_data', value: jsonEncode(userModel.toJson()));
      }
      
      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    await secureStorage.delete(key: 'access_token');
    await secureStorage.delete(key: 'user_data');
    await databaseHelper.clearAllData(); // Clear local DB
  }

  @override
  Future<Either<Failure, UserModel>> getCurrentUser() async {
    try {
      final jsonString = await secureStorage.read(key: 'user_data');
      if (jsonString != null) {
        final userModel = UserModel.fromJson(jsonDecode(jsonString));
        // Verify token validity with API? Or just return local for now (Offline First).
        // For splash screen, local check is faster.
        return Right(userModel);
      }
      return Left(CacheFailure('No user found'));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
