import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobile_app/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:mobile_app/features/dashboard/domain/repositories/dashboard_repository.dart';

// Events
abstract class DashboardEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadDashboardData extends DashboardEvent {}

// States
abstract class DashboardState extends Equatable {
  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final DashboardModel data;
  DashboardLoaded(this.data);
  @override
  List<Object> get props => [data];
}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;

  DashboardBloc({required this.repository}) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadData);
  }

  Future<void> _onLoadData(LoadDashboardData event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    final result = await repository.getDashboardData();
    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (data) => emit(DashboardLoaded(data)),
    );
  }
}
