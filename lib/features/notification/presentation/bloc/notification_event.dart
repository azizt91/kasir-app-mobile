import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {}

class LoadMoreNotifications extends NotificationEvent {}

class MarkAllRead extends NotificationEvent {}

class ClearAllNotifications extends NotificationEvent {}

class RefreshNotifications extends NotificationEvent {}

// States moved to notification_state.dart
