import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/sync_repository_impl.dart';
import '../../domain/repositories/product_repository.dart';

// Events
abstract class ProductEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadProducts extends ProductEvent {}
class SyncProducts extends ProductEvent {}

// States
abstract class ProductState extends Equatable {
  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final List<ProductModel> products;
  ProductLoaded(this.products);
    @override
  List<Object> get props => [products];
}
class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
    @override
  List<Object> get props => [message];
}

// Bloc
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository productRepository;
  final SyncRepository syncRepository;

  ProductBloc({
    required this.productRepository,
    required this.syncRepository,
  }) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<SyncProducts>(_onSyncProducts);
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    final result = await productRepository.getProducts();
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductLoaded(products)),
    );
  }

  Future<void> _onSyncProducts(SyncProducts event, Emitter<ProductState> emit) async {
    // Show loading? Or just sync in background?
    // If explicit sync, show loading.
    emit(ProductLoading());
    final result = await syncRepository.syncProducts();
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) => add(LoadProducts()), // Reload after sync
    );
  }
}
