import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_event.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;
  int _page = 1;

  NotificationBloc({required this.repository}) : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<RefreshNotifications>(_onRefreshNotifications);
    on<MarkAllRead>(_onMarkAllRead);
    on<ClearAllNotifications>(_onClearAll);
  }

  Future<void> _onLoadNotifications(LoadNotifications event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    _page = 1;
    final result = await repository.getNotifications(page: _page);
    final countResult = await repository.getUnreadCount();

    result.fold(
      (failure) => emit(NotificationError(failure.message)),
      (notifications) {
        int count = 0;
        countResult.fold((_) => null, (c) => count = c);
        emit(NotificationLoaded(notifications: notifications, unreadCount: count));
      },
    );
  }

  Future<void> _onRefreshNotifications(RefreshNotifications event, Emitter<NotificationState> emit) async {
     _page = 1;
     // Re-fetch without showing loading if possible, or show loading
     final result = await repository.getNotifications(page: _page);
     final countResult = await repository.getUnreadCount();
     
     if (state is NotificationLoaded) {
       final currentState = state as NotificationLoaded;
       result.fold(
         (f) => null, // Keep old state on error
         (notifications) {
            int count = 0;
            countResult.fold((_) => null, (c) => count = c);
            emit(currentState.copyWith(notifications: notifications, unreadCount: count));
         }
       );
     } else {
       add(LoadNotifications());
     }
  }

  Future<void> _onMarkAllRead(MarkAllRead event, Emitter<NotificationState> emit) async {
    await repository.markAllRead();
    if (state is NotificationLoaded) {
      final currentState = state as NotificationLoaded;
      // Optimistic update
      emit(currentState.copyWith(unreadCount: 0));
    }
    // Refresh to get updated read_at status
    add(RefreshNotifications()); 
  }

  Future<void> _onClearAll(ClearAllNotifications event, Emitter<NotificationState> emit) async {
    await repository.clearAll();
    emit(const NotificationLoaded(notifications: [], unreadCount: 0));
  }
}
