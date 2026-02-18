import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/features/transaction/data/repositories/transaction_repository_impl.dart'; // Contains interface and impl
// Actually we should inject interface. But sticking to pattern used in StockBloc.
import 'package:mobile_app/features/history/data/models/transaction_model.dart';

// Events
abstract class HistoryEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadHistory extends HistoryEvent {}

class VoidTransaction extends HistoryEvent {
  final int id;
  VoidTransaction(this.id);
}

// States
abstract class HistoryState extends Equatable {
  @override
  List<Object> get props => [];
}

class HistoryInitial extends HistoryState {}
class HistoryLoading extends HistoryState {}
class HistoryLoaded extends HistoryState {
  final List<TransactionModel> transactions;
  final Map<String, List<TransactionModel>> groupedTransactions; // Helper for UI

  HistoryLoaded(this.transactions) 
      : groupedTransactions = groupTransactions(transactions);

  static Map<String, List<TransactionModel>> groupTransactions(List<TransactionModel> list) {
    // Group by Date text (e.g. "YYYY-MM-DD")
    final Map<String, List<TransactionModel>> groups = {};
    for (var tx in list) {
       // Extract date part
       final date = tx.createdAt.substring(0, 10); // Simple substring
       if (!groups.containsKey(date)) {
         groups[date] = [];
       }
       groups[date]!.add(tx);
    }
    return groups;
  }
  
  @override
  List<Object> get props => [transactions];
}

class HistoryError extends HistoryState {
  final String message;
  HistoryError(this.message);
  @override
  List<Object> get props => [message];
}

class VoidSuccess extends HistoryState {}

// Bloc
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final TransactionRepository repository;

  HistoryBloc({required this.repository}) : super(HistoryInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<VoidTransaction>(_onVoidTransaction);
  }

  Future<void> _onLoadHistory(LoadHistory event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    final result = await repository.getTransactions();
    result.fold(
      (failure) => emit(HistoryError(failure.message)),
      (data) => emit(HistoryLoaded(data)),
    );
  }

  Future<void> _onVoidTransaction(VoidTransaction event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    final result = await repository.voidTransaction(event.id);
    result.fold(
      (failure) => emit(HistoryError(failure.message)),
      (_) {
        emit(VoidSuccess());
        add(LoadHistory()); // Reload after void
      },
    );
  }
}
