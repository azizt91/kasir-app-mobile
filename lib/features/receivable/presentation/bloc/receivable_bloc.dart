import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/receivable_repository_impl.dart';
import 'package:mobile_app/features/history/data/models/transaction_model.dart';
import '../../../../injection_container.dart';

// Events
abstract class ReceivableEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadReceivables extends ReceivableEvent {}

class MarkAsPaid extends ReceivableEvent {
  final int id;
  final String method; // 'cash', 'transfer'
  MarkAsPaid(this.id, this.method);
}

// States
abstract class ReceivableState extends Equatable {
  @override
  List<Object> get props => [];
}

class ReceivableInitial extends ReceivableState {}
class ReceivableLoading extends ReceivableState {}
class ReceivableLoaded extends ReceivableState {
  final List<TransactionModel> transactions;
  final Map<String, List<TransactionModel>> groupedByCustomer;
  final double totalReceivable;

  ReceivableLoaded(this.transactions) 
      : groupedByCustomer = _groupByCustomer(transactions),
        totalReceivable = transactions.fold(0, (sum, tx) => sum + tx.totalAmount);

  static Map<String, List<TransactionModel>> _groupByCustomer(List<TransactionModel> list) {
    final Map<String, List<TransactionModel>> groups = {};
    for (var tx in list) {
       // Extract customer name from payload
       final name = tx.payload['customer_name'] ?? 'Umum';
       if (!groups.containsKey(name)) {
         groups[name] = [];
       }
       groups[name]!.add(tx);
    }
    return groups;
  }
  
  @override
  List<Object> get props => [transactions];
}

class ReceivableError extends ReceivableState {
  final String message;
  ReceivableError(this.message);
  @override
  List<Object> get props => [message];
}

class PaymentSuccess extends ReceivableState {}

// Bloc
class ReceivableBloc extends Bloc<ReceivableEvent, ReceivableState> {
  final ReceivableRepositoryImpl repository;

  ReceivableBloc({required this.repository}) : super(ReceivableInitial()) {
    on<LoadReceivables>(_onLoadReceivables);
    on<MarkAsPaid>(_onMarkAsPaid);
  }

  Future<void> _onLoadReceivables(LoadReceivables event, Emitter<ReceivableState> emit) async {
    emit(ReceivableLoading());
    final result = await repository.getReceivables();
    result.fold(
      (failure) => emit(ReceivableError(failure.message)),
      (data) => emit(ReceivableLoaded(data)),
    );
  }

  Future<void> _onMarkAsPaid(MarkAsPaid event, Emitter<ReceivableState> emit) async {
    emit(ReceivableLoading());
    final result = await repository.markAsPaid(event.id, event.method);
    result.fold(
      (failure) => emit(ReceivableError(failure.message)),
      (_) {
        emit(PaymentSuccess());
        add(LoadReceivables()); // Reload
      },
    );
  }
}
