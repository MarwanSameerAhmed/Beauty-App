import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  // The URL of your Vercel serverless function
  // URL for sending to a specific device token
  // IMPORTANT: Replace 'your-vercel-app-name' with your actual Vercel project name.
  static const String _vercelAppName =
      'notification-sender-inky.vercel.app'; // <--- REPLACE THIS

  // URL for sending to a specific device token
  static const String _sendNotificationUrl =
      'https://$_vercelAppName/api/sendNotification';
  // URL for sending to a topic
  static const String _sendTopicNotificationUrl =
      'https://$_vercelAppName/api/sendTopicNotification';

  /// Sends a push notification using the backend service.
  ///https://notification-sender-inky.vercel.app/https://notification-sender-inky.vercel.app/
  /// [token] is the FCM device token of the recipient.
  /// [title] is the notification title.
  /// [body] is the notification body.
  static Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_sendNotificationUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'title': title, 'body': body}),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully.');
      } else {
        print(
          'Failed to send notification. Status code: ${response.statusCode}',
        );
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('An error occurred while sending the notification: $e');
    }
  }

  /// Sends a notification to a specific topic.
  /// Sends a notification to a specific topic. Returns an error message on failure.
  static Future<String?> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
  }) async {
    final url = Uri.parse(_sendTopicNotificationUrl);
    print('Attempting to send notification to topic: $topic at URL: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'topic': topic, 'title': title, 'body': body}),
      );

      if (response.statusCode == 200) {
        print('Topic notification request sent successfully to Vercel.');
        return null; // Success
      } else {
        final error =
            'Failed with status ${response.statusCode}: ${response.body}';
        print(error);
        return error; // Failure
      }
    } catch (e) {
      final error = 'CRITICAL ERROR sending topic notification: $e';
      print(error);
      return error; // Failure
    }
  }
}
