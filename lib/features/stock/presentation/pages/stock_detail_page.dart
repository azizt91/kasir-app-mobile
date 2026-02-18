import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/features/product/data/models/product_model.dart';
import '../bloc/stock_bloc.dart';
import '../../../../injection_container.dart';
import 'package:intl/intl.dart';

class StockDetailPage extends StatelessWidget {
  final ProductModel product;

  const StockDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StockBloc>()..add(LoadStockDetail(product.id)),
      child: StockDetailView(product: product),
    );
  }
}

class StockDetailView extends StatelessWidget {
  final ProductModel product;

  const StockDetailView({super.key, required this.product});

  void _showAdjustmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<StockBloc>(), // Pass the same bloc
        child: AdjustmentDialog(productId: product.id),
      ),
    ).then((_) {
       // Refresh history after dialog close if adjustment made
       context.read<StockBloc>().add(LoadStockDetail(product.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdjustmentDialog(context),
        label: const Text('Update Stok'),
        icon: const Icon(Icons.edit),
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stok Saat Ini', style: TextStyle(color: Colors.grey[600])),
                    Text('${product.stock}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Minimum Stok', style: TextStyle(color: Colors.grey[600])),
                    Text('${product.minimumStock}', style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Riwayat Mutasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: BlocBuilder<StockBloc, StockState>(
              builder: (context, state) {
                if (state is StockLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is StockError) {
                  return Center(child: Text('Error: ${state.message}'));
                } else if (state is StockDetailLoaded) {
                  if (state.movements.isEmpty) {
                    return const Center(child: Text('Belum ada riwayat mutasi'));
                  }
                  
                  return ListView.builder(
                    itemCount: state.movements.length,
                    itemBuilder: (context, index) {
                       final move = state.movements[index];
                       final isIncoming = move.type == 'in' || move.type == 'add';
                       final isOutgoing = move.type == 'out' || move.type == 'subtract';
                       // adjustment can be either set or add/sub logic, but backend model saves 'type' field from table.
                       // stock_movements table 'type' is in/out/adjustment.
                       
                       Color color = Colors.grey;
                       IconData icon = Icons.info;
                       String sign = "";

                       if (move.type == 'in' || move.type == 'add') {
                          color = Colors.green;
                          icon = Icons.arrow_downward;
                          sign = "+";
                       } else if (move.type == 'out' || move.type == 'subtract') {
                          color = Colors.red;
                          icon = Icons.arrow_upward;
                          sign = "-";
                       } else {
                          color = Colors.blue;
                          icon = Icons.settings;
                       }

                       return ListTile(
                         leading: CircleAvatar(
                           backgroundColor: color.withAlpha(30),
                           child: Icon(icon, color: color, size: 20),
                         ),
                         title: Text(move.notes ?? 'Manual Adjustment'),
                         subtitle: Text(DateFormat('dd MMM yyyy HH:mm').format(move.createdAt)),
                         trailing: Text(
                           '$sign${move.quantity}',
                           style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                         ),
                       );
                    },
                  );
                }
                return const Center(child: Text('Memuat...'));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdjustmentDialog extends StatefulWidget {
  final int productId;
  const AdjustmentDialog({super.key, required this.productId});

  @override
  State<AdjustmentDialog> createState() => _AdjustmentDialogState();
}

class _AdjustmentDialogState extends State<AdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'add'; // add, subtract, set
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<StockBloc, StockState>(
      listener: (context, state) {
        if (state is StockAdjustmentSuccess) {
          Navigator.pop(context); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stok berhasil diperbarui')),
          );
        } else if (state is StockError) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: ${state.message}')),
          );
        }
      },
      child: AlertDialog(
        title: const Text('Penyesuaian Stok'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Tipe Penyesuaian'),
                  items: const [
                    DropdownMenuItem(value: 'add', child: Text('Tambah Stok (+)')),
                    DropdownMenuItem(value: 'subtract', child: Text('Kurangi Stok (-)')),
                    DropdownMenuItem(value: 'set', child: Text('Set Stok (Atur Ulang)')),
                  ],
                  onChanged: (val) => setState(() => _type = val!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _qtyController,
                  decoration: const InputDecoration(labelText: 'Jumlah'),
                  keyboardType: TextInputType.number,
                  validator: (val) => (val == null || val.isEmpty || int.tryParse(val) == null) ? 'Masukkan angka valid' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Keterangan (Opsional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
               if (_formKey.currentState!.validate()) {
                  context.read<StockBloc>().add(AdjustStock(
                    productId: widget.productId,
                    type: _type,
                    quantity: int.parse(_qtyController.text),
                    notes: _notesController.text,
                  ));
               }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
