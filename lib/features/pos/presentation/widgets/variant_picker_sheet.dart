import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/product/data/models/product_model.dart';

/// Bottom sheet that shows variant options for a product group.
/// When user taps a variant, it calls [onVariantSelected] with that product.
class VariantPickerSheet extends StatelessWidget {
  final String groupName;
  final String? groupImage;
  final List<ProductModel> variants;
  final void Function(ProductModel variant) onVariantSelected;

  const VariantPickerSheet({
    super.key,
    required this.groupName,
    required this.groupImage,
    required this.variants,
    required this.onVariantSelected,
  });

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
                // Product image
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: groupImage != null && groupImage!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            groupImage!,
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
                        groupName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${variants.length} varian tersedia',
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

          // Variant list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: variants.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
              itemBuilder: (context, index) {
                final variant = variants[index];
                final isOutOfStock = variant.stock <= 0;
                // Show only variant name if available, otherwise full name
                final displayName = variant.variantName ?? variant.name;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
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
                  title: Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Stok: ${variant.stock}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOutOfStock ? Colors.red : Colors.grey.shade600,
                      fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    currencyFormatter.format(variant.sellingPrice),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isOutOfStock ? Colors.grey : const Color(0xFF1B9C5E),
                    ),
                  ),
                  enabled: !isOutOfStock,
                  onTap: isOutOfStock
                      ? null
                      : () {
                          onVariantSelected(variant);
                          Navigator.pop(context);
                        },
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
}
