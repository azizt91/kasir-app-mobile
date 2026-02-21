import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/product/data/models/product_model.dart';

/// Bottom sheet that shows variant options with quantity +/- controls.
/// Users can add, increase, or decrease quantity for each variant directly.
class VariantPickerSheet extends StatefulWidget {
  final String groupName;
  final String? groupImage;
  final List<ProductModel> variants;
  /// Map of product.id -> current cart quantity
  final Map<int, int> cartQuantities;
  final void Function(ProductModel variant, int newQty) onQuantityChanged;

  const VariantPickerSheet({
    super.key,
    required this.groupName,
    required this.groupImage,
    required this.variants,
    required this.cartQuantities,
    required this.onQuantityChanged,
  });

  @override
  State<VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends State<VariantPickerSheet> {
  late Map<int, int> _quantities;

  @override
  void initState() {
    super.initState();
    // Copy cart quantities to local state for immediate UI feedback
    _quantities = Map.from(widget.cartQuantities);
  }

  void _updateQty(ProductModel variant, int delta) {
    final currentQty = _quantities[variant.id] ?? 0;
    final newQty = (currentQty + delta).clamp(0, variant.stock);
    setState(() {
      _quantities[variant.id] = newQty;
    });
    widget.onQuantityChanged(variant, newQty);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: widget.groupImage != null && widget.groupImage!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.groupImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.inventory_2, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.groupName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.variants.length} varian tersedia',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Variant list with quantity controls
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.variants.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
              itemBuilder: (context, index) {
                final variant = widget.variants[index];
                final isOutOfStock = variant.stock <= 0;
                final qty = _quantities[variant.id] ?? 0;
                final displayName = variant.variantName ?? variant.name;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      // Variant image
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: variant.image != null && variant.image!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  variant.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.style, size: 20, color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.style, size: 20, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),

                      // Name, stock, price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  'Stok: ${variant.stock}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOutOfStock ? Colors.red : Colors.grey.shade600,
                                    fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currencyFormatter.format(variant.sellingPrice),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isOutOfStock ? Colors.grey : const Color(0xFF1B9C5E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Quantity controls or "Habis" label
                      if (isOutOfStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Habis',
                            style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        _buildQtyControls(variant, qty),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildQtyControls(ProductModel variant, int qty) {
    if (qty == 0) {
      // Show "Tambah" button when qty is 0
      return SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: () => _updateQty(variant, 1),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B9C5E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const Text('+ Tambah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      );
    }

    // Show -/qty/+ controls when qty > 0
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus
          InkWell(
            onTap: () => _updateQty(variant, -1),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Icon(Icons.remove, size: 16, color: Colors.red.shade600),
            ),
          ),
          // Quantity
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.symmetric(vertical: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              '$qty',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          // Plus
          InkWell(
            onTap: qty < variant.stock ? () => _updateQty(variant, 1) : null,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Icon(Icons.add, size: 16, color: qty < variant.stock ? const Color(0xFF1B9C5E) : Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}
