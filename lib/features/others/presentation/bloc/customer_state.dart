part of 'customer_bloc.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();
  
  @override
  List<Object> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<CustomerModel> customers;
  final List<CustomerModel> filteredCustomers;

  const CustomerLoaded(this.customers, {List<CustomerModel>? filteredCustomers}) 
      : filteredCustomers = filteredCustomers ?? customers;

  @override
  List<Object> get props => [customers, filteredCustomers];

  CustomerLoaded copyWith({List<CustomerModel>? customers, List<CustomerModel>? filteredCustomers}) {
    return CustomerLoaded(
      customers ?? this.customers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
    );
  }
}

class CustomerOperationSuccess extends CustomerState {
  final String message;
  const CustomerOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class CustomerError extends CustomerState {
  final String message;
  const CustomerError(this.message);

  @override
  List<Object> get props => [message];
}
