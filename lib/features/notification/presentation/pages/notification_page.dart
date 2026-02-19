import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart'; // Import State

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_read') {
                context.read<NotificationBloc>().add(MarkAllRead());
              } else if (value == 'clear_all') {
                // Show confirmation dialog?
                context.read<NotificationBloc>().add(ClearAllNotifications());
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'mark_read',
                  child: Text('Tandai Semua Dibaca'),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Text('Hapus Semua', style: TextStyle(color: Colors.red)),
                ),
              ];
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotificationError) {
            return Center(child: Text(state.message));
          } else if (state is NotificationLoaded) {
             if (state.notifications.isEmpty) {
               return const Center(child: Text("Belum ada notifikasi"));
             }
             return RefreshIndicator(
               onRefresh: () async {
                 context.read<NotificationBloc>().add(RefreshNotifications());
               },
               child: ListView.builder(
                 itemCount: state.notifications.length,
                 itemBuilder: (context, index) {
                   final notification = state.notifications[index];
                   final isRead = notification.readAt != null;
                   return Container(
                     color: isRead ? Colors.transparent : Colors.blue.withOpacity(0.05),
                     child: ListTile(
                       leading: CircleAvatar(
                         backgroundColor: isRead ? Colors.grey[300] : AppColors.primary,
                         child: Icon(Icons.notifications, color: isRead ? Colors.grey : Colors.white),
                       ),
                       title: Text(
                         notification.title, 
                         style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                       ),
                       subtitle: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(notification.body),
                           const SizedBox(height: 4),
                           Text(
                             "${notification.createdAt.day}/${notification.createdAt.month} ${notification.createdAt.hour}:${notification.createdAt.minute}",
                             style: const TextStyle(fontSize: 10, color: Colors.grey),
                           ),
                         ],
                       ),
                       onTap: () {
                         // Mark as read if not already? OR navigate?
                         // For now, maybe just expand.
                       },
                     ),
                   );
                 },
               ),
             );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
