import 'package:equatable/equatable.dart';

class PendingStockAdjustmentModel extends Equatable {
  final int? id;
  final int productId;
  final String type; // add, subtract, set
  final int quantity;
  final String? notes;
  final DateTime createdAt;

  const PendingStockAdjustmentModel({
    this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'status': 'waiting',
    };
  }

  factory PendingStockAdjustmentModel.fromMap(Map<String, dynamic> map) {
    return PendingStockAdjustmentModel(
      id: map['id'],
      productId: map['product_id'],
      type: map['type'],
      quantity: map['quantity'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, productId, type, quantity, notes, createdAt];
}
