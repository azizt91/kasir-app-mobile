import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../injection_container.dart' as di;
import '../../features/auth/domain/repositories/auth_repository.dart';

// Top-level function required for background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.data}');
  // Note: You can show a local notification here if needed
  // But FCM automatically displays the notification if it has a 'notification' payload
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Local Notifications for foreground display
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Note: Firebase.initializeApp() is called in main.dart, no need to call again here.

    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM: User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('FCM: User granted provisional permission');
    } else {
      debugPrint('FCM: User declined or has not accepted permission');
    }

    // CRITICAL: Allow FCM to show notifications even when app is in foreground
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Initialize Local Notifications (for foreground)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(initializationSettings);

    // Create Channel for Android 8.0+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Set Background Message Handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 4. Handle Foreground Messages — show local notification with sound
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM: Got a message whilst in the foreground!');
      debugPrint('FCM: Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('FCM: Notification title: ${message.notification!.title}');
        _showLocalNotification(message);
      } else if (message.data.isNotEmpty) {
        // Handle data-only messages too
        debugPrint('FCM: Data-only message, showing local notification');
        _showDataNotification(message);
      }
    });

    // 5. Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM: Notification tapped (from background): ${message.data}');
      // Could navigate to specific page based on message.data
    });

    // Check if app was opened from a terminated state via notification
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM: App opened from terminated state via notification: ${initialMessage.data}');
    }

    // 6. Get Token (to send to server)
    String? token = await _firebaseMessaging.getToken();
    debugPrint("FCM Token: $token");
    
    if (token != null) {
      try {
        final authRepository = di.sl<AuthRepository>(); 
        await authRepository.updateFcmToken(token);
        debugPrint("FCM Token sent to backend successfully");
      } catch (e) {
        debugPrint("Failed to sync FCM token: $e");
      }
    }
    
    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
       debugPrint("FCM Token Refreshed: $newToken");
       try {
          final authRepository = di.sl<AuthRepository>();
          await authRepository.updateFcmToken(newToken);
          debugPrint("Refreshed FCM Token sent to backend");
       } catch (e) {
          debugPrint("Failed to sync new FCM token: $e");
       }
    });

  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }

  void _showDataNotification(RemoteMessage message) {
    final data = message.data;
    final title = data['title'] ?? 'Notifikasi Baru';
    final body = data['body'] ?? '';

    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
