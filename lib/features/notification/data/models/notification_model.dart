import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return NotificationModel(
      id: json['id'],
      title: data['title'] ?? 'Notification',
      body: data['body'] ?? '',
      data: data,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']).toLocal() : null,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }

  @override
  List<Object?> get props => [id, title, body, data, readAt, createdAt];
}
