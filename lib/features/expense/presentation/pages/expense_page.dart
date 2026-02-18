import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../bloc/expense_bloc.dart';
import '../../data/models/expense_model.dart';
import 'package:intl/intl.dart';
import '../widgets/expense_form_dialog.dart';
import 'package:mobile_app/core/theme/app_colors.dart';

class ExpensePage extends StatelessWidget {
  const ExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExpenseBloc>()..add(LoadExpenses()),
      child: const ExpenseView(),
    );
  }
}

class ExpenseView extends StatelessWidget {
  const ExpenseView({super.key});

  void _showFormDialog(BuildContext context, {ExpenseModel? expense}) {
    showDialog(
      context: context,
      builder: (ctx) => ExpenseFormDialog(
        expense: expense,
        onSubmit: (name, amount, date, description) {
          if (expense == null) {
            context.read<ExpenseBloc>().add(CreateExpense({
                  'name': name,
                  'amount': amount,
                  'expense_date': date,
                  'description': description,
                }));
          } else {
             context.read<ExpenseBloc>().add(UpdateExpense(expense.id!, {
                  'name': name,
                  'amount': amount,
                  'expense_date': date,
                  'description': description,
                }));
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengeluaran'),
        content: Text('Hapus ${expense.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ExpenseBloc>().add(DeleteExpense(expense.id!));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.black),
            onPressed: () => context.read<ExpenseBloc>().add(SyncExpenses()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocConsumer<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
           if (state is ExpenseOperationSuccess) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
           } else if (state is ExpenseError) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
           }
        },
        builder: (context, state) {
          if (state is ExpenseLoading && state is! ExpenseLoaded) {
            return const Center(child: CircularProgressIndicator());
          } 
          
          List<ExpenseModel> expenses = [];
          double total = 0;
          Map<String, List<ExpenseModel>> grouped = {};

          if (state is ExpenseLoaded) {
            expenses = state.expenses;
            total = state.totalExpense;
            grouped = state.groupedByMonth;
          }

          if (expenses.isEmpty && state is! ExpenseLoading) {
             return const Center(child: Text('Belum ada pengeluaran'));
          }

          final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
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
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL PENGELUARAN',
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.grey.shade400,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currency.format(total),
                          style: const TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.w900, 
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.trending_down, color: Colors.red),
                    ),
                  ],
                ),
              ),

              // Grouped List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final monthKey = sortedKeys[index];
                    final monthExpenses = grouped[monthKey]!;
                    
                    // Parse month key YYYY-MM to readable
                    final dateObj = DateTime.tryParse('$monthKey-01');
                    final monthName = dateObj != null 
                        ? DateFormat('MMMM yyyy', 'id').format(dateObj) 
                        : monthKey;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Text(
                            monthName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        ...monthExpenses.map((expense) => _buildExpenseCard(context, expense, currency)).toList(),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, ExpenseModel expense, NumberFormat currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _updateOrDelete(context, expense),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                     color: Colors.orange.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, color: Colors.orange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expense.description ?? expense.expenseDate,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '- ${currency.format(expense.amount).replaceAll('Rp ', '')}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                    ),
                    const SizedBox(height: 4),
                    if (!expense.isSynced)
                      const Row(
                        children: [
                          Icon(Icons.cloud_upload, size: 12, color: Colors.orange),
                          SizedBox(width: 4),
                          Text('Pending', style: TextStyle(fontSize: 10, color: Colors.orange)),
                        ],
                      )
                    else 
                       Text(
                         expense.expenseDate,
                         style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                       ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateOrDelete(BuildContext context, ExpenseModel expense) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 ListTile(
                    leading: const Icon(Icons.edit, color: Colors.blue),
                    title: const Text('Edit Pengeluaran'),
                    onTap: () {
                       Navigator.pop(ctx);
                       _showFormDialog(context, expense: expense);
                    },
                 ),
                 ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Hapus Pengeluaran', style: TextStyle(color: Colors.red)),
                    onTap: () {
                       Navigator.pop(ctx);
                       _confirmDelete(context, expense);
                    },
                 ),
              ],
            ),
          ),
        ),
      );
  }
}
