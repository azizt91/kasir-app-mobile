import 'package:equatable/equatable.dart';

class StockMovementModel extends Equatable {
  final int id;
  final int productId;
  final String type; // in, out, adjustment
  final int quantity;
  final String? referenceType;
  final int? referenceId;
  final String? notes;
  final DateTime createdAt;

  const StockMovementModel({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    this.referenceType,
    this.referenceId,
    this.notes,
    required this.createdAt,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'],
      productId: json['product_id'],
      type: json['type'],
      quantity: json['quantity'],
      referenceType: json['reference_type'],
      referenceId: json['reference_id'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, productId, type, quantity, createdAt];
}
