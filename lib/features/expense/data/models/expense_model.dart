import 'dart:convert';

class ExpenseModel {
  final int? id;
  final String name;
  final double amount;
  final String expenseDate;
  final String? description;
  final String? createdAt;
  final bool isSynced;

  ExpenseModel({
    this.id,
    required this.name,
    required this.amount,
    required this.expenseDate,
    this.description,
    this.createdAt,
    this.isSynced = true,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      name: json['name'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      expenseDate: json['expense_date'],
      description: json['description'],
      createdAt: json['created_at'],
      isSynced: true,
    );
  }

  factory ExpenseModel.fromPending(Map<String, dynamic> json) {
    final payload = jsonDecode(json['payload']);
    return ExpenseModel(
      id: json['id'], // Local ID
      name: payload['name'],
      amount: double.tryParse(payload['amount'].toString()) ?? 0.0,
      expenseDate: payload['expense_date'],
      description: payload['description'],
      createdAt: json['created_at'], // Local creation time? Or maybe use expense_date
      isSynced: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'expense_date': expenseDate,
      'description': description,
    };
  }

  Map<String, dynamic> toCachedMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'expense_date': expenseDate,
      'description': description,
      'created_at': createdAt,
    };
  }
}
