import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobile_app/features/pos/data/models/customer_model.dart';
import 'package:mobile_app/features/pos/data/repositories/customer_repository.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository repository;

  CustomerBloc({required this.repository}) : super(CustomerInitial()) {
    on<GetCustomers>(_onGetCustomers);
    on<SearchCustomers>(_onSearchCustomers);
    on<CreateCustomerEvent>(_onCreateCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
  }

  Future<void> _onGetCustomers(GetCustomers event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    final result = await repository.getCustomers();
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customers) => emit(CustomerLoaded(customers)),
    );
  }

  void _onSearchCustomers(SearchCustomers event, Emitter<CustomerState> emit) {
    if (state is CustomerLoaded) {
      final currentState = state as CustomerLoaded;
      final query = event.query.toLowerCase();
      final filtered = currentState.customers.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
               (customer.phone != null && customer.phone!.contains(query));
      }).toList();
      emit(currentState.copyWith(filteredCustomers: filtered));
    }
  }

  Future<void> _onCreateCustomer(CreateCustomerEvent event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    final result = await repository.createCustomer(
      event.name,
      event.phone,
      email: event.email,
      address: event.address,
    );
    
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customer) {
        emit(const CustomerOperationSuccess('Pelanggan berhasil ditambahkan'));
        add(GetCustomers()); // Refresh list
      },
    );
  }

  Future<void> _onUpdateCustomer(UpdateCustomerEvent event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    final result = await repository.updateCustomer(event.customer);
    
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customer) {
        emit(const CustomerOperationSuccess('Pelanggan berhasil diperbarui'));
        add(GetCustomers()); // Refresh list
      },
    );
  }

  Future<void> _onDeleteCustomer(DeleteCustomerEvent event, Emitter<CustomerState> emit) async {
    emit(CustomerLoading());
    final result = await repository.deleteCustomer(event.id);
    
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (_) {
        emit(const CustomerOperationSuccess('Pelanggan berhasil dihapus'));
        add(GetCustomers()); // Refresh list
      },
    );
  }
}
