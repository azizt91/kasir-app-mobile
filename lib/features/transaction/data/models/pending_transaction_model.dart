import 'dart:convert';
import 'package:equatable/equatable.dart';

class PendingTransactionModel extends Equatable {
  final int? id;
  final Map<String, dynamic> payload;
  final String createdAt;
  final String status;
  final String? errorMessage;

  const PendingTransactionModel({
    this.id,
    required this.payload,
    required this.createdAt,
    this.status = 'waiting',
    this.errorMessage,
  });

  factory PendingTransactionModel.fromMap(Map<String, dynamic> map) {
    return PendingTransactionModel(
      id: map['id'],
      payload: jsonDecode(map['payload']),
      createdAt: map['created_at'],
      status: map['status'],
      errorMessage: map['error_message'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payload': jsonEncode(payload),
      'created_at': createdAt,
      'status': status,
      'error_message': errorMessage,
    };
  }

  @override
  List<Object?> get props => [id, payload, createdAt, status];
}
