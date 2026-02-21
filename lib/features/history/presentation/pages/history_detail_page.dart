import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../../../injection_container.dart';
import '../../../../core/services/printer_service.dart';
import '../../../../core/utils/receipt_builder.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/history_bloc.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/features/auth/presentation/bloc/auth_bloc.dart';

class HistoryDetailModal extends StatelessWidget {
  final TransactionModel transaction;

  const HistoryDetailModal({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<HistoryBloc>(),
      child: HistoryDetailView(transaction: transaction),
    );
  }
}

class HistoryDetailView extends StatefulWidget {
  final TransactionModel transaction;
  const HistoryDetailView({super.key, required this.transaction});

  @override
  State<HistoryDetailView> createState() => _HistoryDetailViewState();
}

class _HistoryDetailViewState extends State<HistoryDetailView> {
  final PrinterService _printerService = sl<PrinterService>();
  bool _isPrinting = false;

  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);
    
    try {
       final receiptBuilder = ReceiptBuilder();
       
       // Get settings from AuthBloc (database)
       final authState = context.read<AuthBloc>().state;
       Map<String, dynamic> settings = {};
       if (authState is AuthAuthenticated) {
         settings = authState.user.settings;
       }

       final itemList = widget.transaction.payload['items'] as List;
       
       final bytes = await receiptBuilder.buildReceipt(
         widget.transaction.payload,
         settings,
         itemList,
       );

       await _printerService.printReceipt(bytes);
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Struk dikirim ke printer')));
       }

    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal cetak: $e')));
       }
    } finally {
       if (mounted) setState(() => _isPrinting = false);
    }
  }
  
  void _confirmVoid(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Transaksi?'),
        content: const Text('Stok akan dikembalikan. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tidak')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<HistoryBloc>().add(VoidTransaction(widget.transaction.id!));
            },
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final items = widget.transaction.payload['items'] as List;
    final date = DateTime.parse(widget.transaction.createdAt).toLocal();

    // Color Theme based on status
    String statusText = 'Berhasil';
    Color statusBg = Colors.green.shade100;
    Color statusTxtColor = Colors.green.shade800;

    if (widget.transaction.status == 'void') {
       statusText = 'Dibatalkan';
       statusBg = Colors.red.shade100;
       statusTxtColor = Colors.red.shade800;
    } else if (widget.transaction.paymentMethod == 'utang') {
       statusText = 'Menunggu';
       statusBg = Colors.orange.shade100;
       statusTxtColor = Colors.orange.shade800;
    }

    return BlocListener<HistoryBloc, HistoryState>(
      listener: (context, state) {
        if (state is VoidSuccess) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi Berhasil Dibatalkan')));
           Navigator.pop(context); 
        } else if (state is HistoryError) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${state.message}')));
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85, // 85% height
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text(
                    'Detail Transaksi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge & Code
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusText.toUpperCase(),
                              style: TextStyle(color: statusTxtColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currency.format(widget.transaction.totalAmount),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textBlack),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.transaction.transactionCode,
                            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(date),
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Items List
                    const Text('Daftar Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    ...items.map((item) {
                      final name = item['product_name'] ?? (item['product']?['name'] ?? 'Unknown');
                      
                      double parseDouble(dynamic value) {
                        if (value is num) return value.toDouble();
                        if (value is String) return double.tryParse(value) ?? 0.0;
                        return 0.0;
                      }

                      final qty = parseDouble(item['quantity']);
                      final price = parseDouble(item['price']);
                      final subtotal = parseDouble(item['subtotal'] ?? (price * qty));
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2_outlined, size: 20, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('$qty x ${currency.format(price)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(currency.format(subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }).toList(),
                    
                    const Divider(height: 32),
                    
                    // Payment Details
                    const Text('Rincian Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Subtotal', currency.format(widget.transaction.subtotal)),
                    if ((widget.transaction.discount) > 0)
                      _buildSummaryRow('Diskon', '-${currency.format(widget.transaction.discount)}'),
                    if ((widget.transaction.tax) > 0)
                      _buildSummaryRow('Pajak', currency.format(widget.transaction.tax)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(currency.format(widget.transaction.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Metode Bayar', widget.transaction.paymentMethod.toUpperCase()),
                    _buildSummaryRow('Bayar', currency.format(widget.transaction.amountPaid)),
                    if (widget.transaction.paymentMethod == 'utang')
                       _buildSummaryRow('Sisa Tagihan', currency.format((widget.transaction.totalAmount - widget.transaction.amountPaid).clamp(0, double.infinity)))
                    else
                       _buildSummaryRow('Kembali', currency.format((widget.transaction.changeAmount < 0) ? 0 : widget.transaction.changeAmount)),
                    
                    // Location Link
                    if (widget.transaction.payload['latitude'] != null && widget.transaction.payload['longitude'] != null) ...[
                      const Divider(height: 32),
                      InkWell(
                        onTap: () async {
                          final lat = widget.transaction.payload['latitude'];
                          final lng = widget.transaction.payload['longitude'];
                          final url = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Lihat Lokasi Transaksi',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                              Icon(Icons.open_in_new, size: 16, color: Colors.blue.shade400),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (widget.transaction.isSynced && widget.transaction.status != 'void')
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () => _confirmVoid(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.red.shade50,
                            side: BorderSide.none, // Removed border
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                              const SizedBox(width: 8),
                              Text('Batalkan Transaksi', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    if (widget.transaction.isSynced) const SizedBox(width: 16),
                    Expanded(
                      flex: 1, // Equal width buttons
                      child: ElevatedButton(
                        onPressed: _isPrinting ? null : _printReceipt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success, // Green button
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isPrinting 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.print, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Cetak Struk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}
