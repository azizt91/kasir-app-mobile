part of 'customer_bloc.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object> get props => [];
}

class GetCustomers extends CustomerEvent {}

class SearchCustomers extends CustomerEvent {
  final String query;
  const SearchCustomers(this.query);

  @override
  List<Object> get props => [query];
}

class CreateCustomerEvent extends CustomerEvent {
  final String name;
  final String? phone;
  final String? email;
  final String? address;

  const CreateCustomerEvent({required this.name, this.phone, this.email, this.address});

  @override
  List<Object> get props => [name, if (phone != null) phone!, if (email != null) email!, if (address != null) address!];
}

class UpdateCustomerEvent extends CustomerEvent {
  final CustomerModel customer;
  const UpdateCustomerEvent(this.customer);

  @override
  List<Object> get props => [customer];
}

class DeleteCustomerEvent extends CustomerEvent {
  final int id;
  const DeleteCustomerEvent(this.id);

  @override
  List<Object> get props => [id];
}
