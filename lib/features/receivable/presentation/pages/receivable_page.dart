import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../bloc/receivable_bloc.dart';
import 'package:mobile_app/features/history/data/models/transaction_model.dart';
import 'package:mobile_app/core/theme/app_colors.dart';

class ReceivablePage extends StatelessWidget {
  const ReceivablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReceivableBloc>()..add(LoadReceivables()),
      child: const ReceivableView(),
    );
  }
}

class ReceivableView extends StatefulWidget {
  const ReceivableView({super.key});

  @override
  State<ReceivableView> createState() => _ReceivableViewState();
}

class _ReceivableViewState extends State<ReceivableView> {
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocConsumer<ReceivableBloc, ReceivableState>(
        listener: (context, state) {
           if (state is PaymentSuccess) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran Berhasil Dicatat')));
           } else if (state is ReceivableError) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
           }
        },
        builder: (context, state) {
          double totalReceivable = 0;
          List<TransactionModel> transactions = [];

          if (state is ReceivableLoaded) {
            totalReceivable = state.totalReceivable;
            transactions = state.transactions;
            
            // Basic filtering if needed, though BLoC usually handles this better.
            // But since BLoC state structure might not have direct search support yet, 
            // we can filter visually here or add search event later.
            // For now, let's filter visually if search text exists.
             if (_searchController.text.isNotEmpty) {
                transactions = transactions.where((tx) => 
                  (tx.customerName ?? '').toLowerCase().contains(_searchController.text.toLowerCase()) ||
                  tx.transactionCode.toLowerCase().contains(_searchController.text.toLowerCase())
                ).toList();
             }

             // Apply Date Filter
             if (_selectedDateRange != null) {
               transactions = transactions.where((tx) {
                 final createdAt = DateTime.tryParse(tx.createdAt) ?? DateTime.now();
                 return createdAt.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
                        createdAt.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
               }).toList();
             }
          }

          return SafeArea(
            child: Column(
              children: [
                // Custom Header
                _buildHeader(context, currency, totalReceivable),
                
                // Content
                Expanded(
                  child: state is ReceivableLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : transactions.isEmpty 
                        ? Center(child: Text(state is ReceivableLoaded ? 'Tidak ada data piutang' : 'Memuat data...'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              return _buildReceivableCard(context, transactions[index], currency);
                            },
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, NumberFormat currency, double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Piutang', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Row(
                children: [
                  if (_selectedDateRange != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                      },
                    ),
                  IconButton(
                    onPressed: () async {
                       final picked = await showDateRangePicker(
                         context: context, 
                         firstDate: DateTime(2020), 
                         lastDate: DateTime.now().add(const Duration(days: 365)),
                         initialDateRange: _selectedDateRange,
                         builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                         },
                       );
                       if (picked != null) {
                         setState(() => _selectedDateRange = picked);
                       }
                    }, 
                    icon: Icon(Icons.date_range, color: _selectedDateRange != null ? AppColors.primary : AppColors.textGrey)
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Total Summary Card (Gradient)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF13EC6D), Color(0xFF0EBF57)], // From CSS: primary to primary-dark
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                 BoxShadow(color: const Color(0xFF13EC6D).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Piutang Belum Lunas', 
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.7), letterSpacing: 0.5)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currency.format(total),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.black87, size: 28),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) {
               setState(() {}); // Simple setState for local filtering
            },
            decoration: InputDecoration(
              hintText: 'Cari nama pelanggan atau no. faktur...',
              hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
              filled: true,
              fillColor: AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivableCard(BuildContext context, TransactionModel tx, NumberFormat currency) {
    // Determine status color
    // Determine status color
    // removed due date logic as requested
    /*
    final createdAt = DateTime.tryParse(tx.createdAt) ?? DateTime.now();
    final difference = DateTime.now().difference(createdAt).inDays;
    final isOverdue = difference > 30; 
    */

    final accentColor = AppColors.primary;
    const statusText = 'BELUM LUNAS';
    final statusBg = AppColors.primary.withOpacity(0.1);
    const statusFg = AppColors.primaryHover;


    return GestureDetector(
      onTap: () => _showDetailDialog(context, tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.hardEdge,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left Accent Bar
              Container(width: 4, color: accentColor),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Top Row: Invoice & Date + Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(tx.transactionCode, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textGrey)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('d MMM', 'id').format(DateTime.parse(tx.createdAt)),
                                style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusFg.withOpacity(0.2), width: 0.5),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusFg),
                            ),
                          )
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Content Row: Name & Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // User Info
                          Row(
                            children: [
                               CircleAvatar(
                                 radius: 16,
                                 backgroundColor: Colors.grey.shade200,
                                 child: Text(
                                   (tx.customerName?.isNotEmpty ?? false) ? tx.customerName![0].toUpperCase() : '?',
                                   style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                                 ),
                               ),
                               const SizedBox(width: 10),
                               Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                     tx.customerName ?? 'Umum',
                                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                   ),
                                   const SizedBox(height: 2),
                                   const Text('Pelanggan', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
                                 ],
                               ),
                            ],
                          ),
                          
                          // Amount
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Sisa Tagihan', style: TextStyle(fontSize: 10, color: AppColors.textGrey)), // Remaining logic needed?
                              const SizedBox(height: 2),
                              // Assuming totalAmount is remaining for now as we don't handle partial payments fully in frontend yet
                              Text(
                                currency.format((tx.totalAmount - tx.amountPaid).clamp(0, double.infinity)),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                            ],
                          )
                        ],
                      ),

                      // Actions (Optional - e.g., Pay Button directly on card?)
                       const SizedBox(height: 8),
                       Align(
                         alignment: Alignment.centerRight,
                         child: ElevatedButton(
                           onPressed: () => _showPaymentDialog(context, tx),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: const Color(0xFF1B9C5E), // Green
                             foregroundColor: Colors.white,
                             elevation: 0,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                             minimumSize: const Size(0, 32), // Compact
                           ),
                           child: const Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(Icons.check, size: 14),
                               SizedBox(width: 4),
                               Text('Tandai Lunas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                             ],
                           ),
                         ),
                       )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }



  void _showPaymentDialog(BuildContext context, TransactionModel tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pelunasan Piutang'),
        content: Text('Tandai transaksi ${tx.transactionCode} sebagai LUNAS?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ReceivableBloc>().add(MarkAsPaid(tx.id!, 'cash'));
            },
            child: const Text('Ya, Lunas (Tunai)'),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, TransactionModel tx) {
     final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
     final items = tx.payload['items'] as List;

     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Detail ${tx.transactionCode}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (ctx, i) {
               final item = items[i];
               final price = item['price'] is String ? double.tryParse(item['price']) ?? 0 : (item['price'] as num);
               final subtotal = item['subtotal'] is String ? double.tryParse(item['subtotal']) ?? 0 : (item['subtotal'] as num);
               
               // Access nested product.name if available, or product_name
               String productName = '-';
               if (item['product'] != null && item['product']['name'] != null) {
                  productName = item['product']['name'];
               } else if (item['product_name'] != null) {
                  productName = item['product_name'];
               }

               return ListTile(
                 title: Text(productName),
                 subtitle: Text('${item['quantity']}x @${currency.format(price)}'),
                 trailing: Text(currency.format(subtotal)),
               );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }
}
