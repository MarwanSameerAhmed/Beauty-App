import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void initialize() {
    // Initialization settings for Android and iOS
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings("@drawable/ic_notification"),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: false,
      ),
    );

    _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );
  }

  static void display(RemoteMessage message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      const NotificationDetails notificationDetails = NotificationDetails(
        android: const AndroidNotificationDetails(
          "beauty_app_channel", // Channel ID
          "Beauty App Channel", // Channel Name
          channelDescription: "This is our channel for notifications",
          importance: Importance.max,
          priority: Priority.high,
          icon: "@drawable/ic_notification", // Custom notification icon
          color: Color(0xFF52002C), // Brand color
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          badgeNumber: 1,
        ),
      );

      await _notificationsPlugin.show(
        id,
        message.notification!.title,
        message.notification!.body,
        notificationDetails,
      );
    } catch (e) {
      print('Error displaying notification: $e');
    }
  }
}
