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

// States
abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool hasReachedMax;

  const NotificationLoaded({
    this.notifications = const [],
    this.unreadCount = 0,
    this.hasReachedMax = false,
  });

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? hasReachedMax,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount, hasReachedMax];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override
  List<Object?> get props => [message];
}
