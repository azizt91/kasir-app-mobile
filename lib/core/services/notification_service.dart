
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
    // 1. Initialize Firebase App (Must be called before using Firebase services)
    // Note: ensure WidgetsFlutterBinding.ensureInitialized() is called in main.dart
    await Firebase.initializeApp();

    // 2. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 3. Initialize Local Notifications (for foreground)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Ensure icon exists
    
    // final DarwinInitializationSettings initializationSettingsDarwin =
    //     DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(initializationSettings);

    // Create Channel for Android 8.0+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // 5. Get Token (to send to server)
    String? token = await _firebaseMessaging.getToken();
    debugPrint("FCM Token: $token");
    // TODO: Send this token to backend via API
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
