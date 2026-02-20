import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/models/expense_model.dart';

// Events
abstract class ExpenseEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadExpenses extends ExpenseEvent {}

class CreateExpense extends ExpenseEvent {
  final Map<String, dynamic> data;
  CreateExpense(this.data);
}

class UpdateExpense extends ExpenseEvent {
  final int id;
  final Map<String, dynamic> data;
  UpdateExpense(this.id, this.data);
}

class DeleteExpense extends ExpenseEvent {
  final int id;
  DeleteExpense(this.id);
}

class SyncExpenses extends ExpenseEvent {}

// States
abstract class ExpenseState extends Equatable {
  @override
  List<Object> get props => [];
}

class ExpenseInitial extends ExpenseState {}
class ExpenseLoading extends ExpenseState {}
class ExpenseLoaded extends ExpenseState {
  final List<ExpenseModel> expenses;
  final Map<String, List<ExpenseModel>> groupedByMonth;
  final double totalExpense;

  ExpenseLoaded(this.expenses) 
      : groupedByMonth = _groupByMonth(expenses),
        totalExpense = expenses.fold(0, (sum, ex) => sum + ex.amount);

  static Map<String, List<ExpenseModel>> _groupByMonth(List<ExpenseModel> list) {
    // Basic grouping by Month YYYY-MM
    final Map<String, List<ExpenseModel>> groups = {};
    for (var ex in list) {
       final date = ex.expenseDate.length >= 7 ? ex.expenseDate.substring(0, 7) : 'Unknown';
       if (!groups.containsKey(date)) {
         groups[date] = [];
       }
       groups[date]!.add(ex);
    }
    return groups;
  }
  
  @override
  List<Object> get props => [expenses];
}

class ExpenseError extends ExpenseState {
  final String message;
  ExpenseError(this.message);
  @override
  List<Object> get props => [message];
}

class ExpenseOperationSuccess extends ExpenseState {
    final String message;
    ExpenseOperationSuccess(this.message);
}

// Bloc
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository repository; // Change to Interface

  ExpenseBloc({required this.repository}) : super(ExpenseInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<CreateExpense>(_onCreateExpense);
    on<UpdateExpense>(_onUpdateExpense);
    on<DeleteExpense>(_onDeleteExpense);
    on<SyncExpenses>(_onSyncExpenses);
  }

  Future<void> _onLoadExpenses(LoadExpenses event, Emitter<ExpenseState> emit) async {
    emit(ExpenseLoading());
    final result = await repository.getExpenses();
    result.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (data) => emit(ExpenseLoaded(data)),
    );
  }

  Future<void> _onCreateExpense(CreateExpense event, Emitter<ExpenseState> emit) async {
    // Show Loading? Or Optimistic?
    // Let's show loading then reload
    emit(ExpenseLoading());
    final result = await repository.createExpense(event.data);
    result.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (_) {
        emit(ExpenseOperationSuccess("Pengeluaran berhasil disimpan"));
        add(LoadExpenses());
      },
    );
  }

  Future<void> _onUpdateExpense(UpdateExpense event, Emitter<ExpenseState> emit) async {
    emit(ExpenseLoading());
    final result = await repository.updateExpense(event.id, event.data);
    result.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (_) {
        emit(ExpenseOperationSuccess("Pengeluaran berhasil diperbarui"));
        add(LoadExpenses());
      },
    );
  }

  Future<void> _onDeleteExpense(DeleteExpense event, Emitter<ExpenseState> emit) async {
    emit(ExpenseLoading());
    final result = await repository.deleteExpense(event.id);
    result.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (_) {
        emit(ExpenseOperationSuccess("Pengeluaran berhasil dihapus"));
        add(LoadExpenses());
      },
    );
  }
  
  Future<void> _onSyncExpenses(SyncExpenses event, Emitter<ExpenseState> emit) async {
      await repository.syncPendingExpenses();
      add(LoadExpenses());
  }
}
