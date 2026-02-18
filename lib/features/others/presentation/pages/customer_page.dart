import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/features/others/presentation/bloc/customer_bloc.dart';
import 'package:mobile_app/features/others/presentation/widgets/customer_form_dialog.dart';
import 'package:mobile_app/features/pos/data/models/customer_model.dart';
import '../../../../injection_container.dart' as di;

class CustomerPage extends StatelessWidget {
  const CustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<CustomerBloc>()..add(GetCustomers()),
      child: const CustomerPageView(),
    );
  }
}

class CustomerPageView extends StatefulWidget {
  const CustomerPageView({super.key});

  @override
  State<CustomerPageView> createState() => _CustomerPageViewState();
}

class _CustomerPageViewState extends State<CustomerPageView> {
  final TextEditingController _searchController = TextEditingController();

  void _showFormDialog(BuildContext context, {CustomerModel? customer}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return CustomerFormDialog(
          customer: customer,
          onSubmit: (name, phone, email, address) {
            if (customer == null) {
              context.read<CustomerBloc>().add(CreateCustomerEvent(
                    name: name,
                    phone: phone,
                    email: email,
                    address: address,
                  ));
            } else {
              context.read<CustomerBloc>().add(UpdateCustomerEvent(CustomerModel(
                    id: customer.id,
                    name: name,
                    phone: phone,
                    email: email,
                    address: address,
                  )));
            }
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: Text('Apakah Anda yakin ingin menghapus ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<CustomerBloc>().add(DeleteCustomerEvent(customer.id));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          } else if (state is CustomerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is CustomerLoading && state is! CustomerLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          List<CustomerModel> displayList = [];
          if (state is CustomerLoaded) {
             displayList = state.filteredCustomers;
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => context.read<CustomerBloc>().add(SearchCustomers(value)),
                  decoration: InputDecoration(
                    hintText: 'Cari pelanggan...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),

              // List
              Expanded(
                child: displayList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              state is CustomerLoading ? 'Memuat...' : 'Tidak ada data pelanggan',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: displayList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final customer = displayList[index];
                          final colors = [
                            Colors.blue.shade100,
                            Colors.green.shade100,
                            Colors.orange.shade100,
                            Colors.purple.shade100,
                            Colors.teal.shade100,
                          ];
                          final color = colors[customer.id % colors.length];
                          final textColor = [
                            Colors.blue.shade900,
                            Colors.green.shade900,
                            Colors.orange.shade900,
                            Colors.purple.shade900,
                            Colors.teal.shade900,
                          ][customer.id % colors.length];

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (customer.phone != null && customer.phone!.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(Icons.phone, size: 14, color: Colors.grey.shade500),
                                              const SizedBox(width: 4),
                                              Text(
                                                customer.phone!,
                                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          )
                                        else
                                          Text('-', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showFormDialog(context, customer: customer),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(8),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.blue.withOpacity(0.1),
                                          shape: const CircleBorder(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _confirmDelete(context, customer),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(8),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.red.withOpacity(0.1),
                                          shape: const CircleBorder(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context),
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
