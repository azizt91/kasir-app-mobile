import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/stock_bloc.dart';
import 'stock_detail_page.dart';
import '../../../../injection_container.dart';
import 'package:intl/intl.dart'; // Add intl
import 'package:mobile_app/features/product/data/models/product_model.dart';
import 'package:mobile_app/core/theme/app_colors.dart';


class StockPage extends StatelessWidget {
  const StockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StockBloc>()..add(LoadStockProducts()),
      child: const StockView(),
    );
  }
}

class StockView extends StatefulWidget {
  const StockView({super.key});

  @override
  State<StockView> createState() => _StockViewState();
}

class _StockViewState extends State<StockView> {
  // We can treat "Low Stock" as a pseudo-category ID = -1 for UI logic if needed,
  // or just use a separate boolean logic.
  // For the UI request "All Items | Low Stock | Groceries", let's fake the pills visually first.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: const Text('Stok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textDark)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        // actions: [
        //   IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none))
        // ],
      ),
      body: BlocBuilder<StockBloc, StockState>(
        builder: (context, state) {
          if (state is StockLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is StockError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is StockLoaded) {
            final products = state.filteredProducts;

            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search product or SKU...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                         suffixIcon: Icon(Icons.tune, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) {
                         context.read<StockBloc>().add(FilterStock(query: value));
                      },
                    ),
                  ),
                ),

                // Pill Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Filters: All Items, Aman, Menipis, Habis
                      _buildPill(context, 'Semua', state.currentFilter == 'all'),
                      _buildPill(context, 'Aman', state.currentFilter == 'safe'),
                      _buildPill(context, 'Menipis', state.currentFilter == 'low'),
                      _buildPill(context, 'Habis', state.currentFilter == 'empty'),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<StockBloc>().add(LoadStockProducts());
                      // Access to ProductBloc to trigger sync if needed?
                      // context.read<ProductBloc>().add(SyncProducts());
                      // But let's just reload local for now as Sync runs in background.
                    },
                    child: products.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('Belum ada data stok')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _buildStockCard(context, product);
                          },
                        ),
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text('Memuat...'));
        },
      ),
    );
  }

  Widget _buildPill(BuildContext context, String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          final bloc = context.read<StockBloc>();
          String filterType = 'all';

          if (label == 'Semua') filterType = 'all';
          else if (label == 'Aman') filterType = 'safe';
          else if (label == 'Menipis') filterType = 'low';
          else if (label == 'Habis') filterType = 'empty';

          bloc.add(FilterStock(filterType: filterType));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1B9C5E) : Colors.white, // Green
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? const Color(0xFF1B9C5E) : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}


  Widget _buildStockCard(BuildContext context, dynamic product) {
    // Determine status
    bool isEmpty = product.stock <= 0;
    bool isLow = !isEmpty && (product.stock <= product.minimumStock);

    // Status Badge & Text
    // Aman (Safe) -> Green
    // Menipis (Low) -> Orange
    // Habis (Empty) -> Red

    Color statusColor;
    Color statusTextColor;
    String statusText;

    if (isEmpty) {
      statusColor = Colors.red.shade100;
      statusTextColor = Colors.red;
      statusText = 'Habis';
    } else if (isLow) {
      statusColor = Colors.orange.shade100;
      statusTextColor = Colors.orange;
      statusText = 'Menipis';
    } else {
      statusColor = Colors.green.shade100;
      statusTextColor = Colors.green; // Or Color(0xFF1B9C5E)
      statusText = 'Aman';
    }

    // Stock Number Color
    // User Req: "jika stok barang menipis bagusnya angkanya ikut orange", "hijau untuk angka yang aman"
    Color stockNumColor;
    if (isEmpty) {
        stockNumColor = Colors.red;
    } else if (isLow) {
        stockNumColor = Colors.orange;
    } else {
        stockNumColor = const Color(0xFF1B9C5E);
    }

    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockDetailPage(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
        children: [
          // Image
          Container(
             width: 48, height: 48,
             decoration: BoxDecoration(
               color: Colors.grey[100],
               borderRadius: BorderRadius.circular(10),
             ),
             child: product.image != null
                 ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(product.image!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.inventory_2, color: Colors.grey, size: 20)))
                 : const Icon(Icons.inventory_2, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(statusText, style: TextStyle(color: statusTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                   ],
                ),
                const SizedBox(height: 2),
                Text('SKU: ${product.barcode ?? "-"}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                         'Price: ${currencyFormatter.format(product.sellingPrice)}',
                         style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text('${product.stock}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: stockNumColor)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
