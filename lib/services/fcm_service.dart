import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  static FCMService get instance => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }

      // Get the token
      String? token = await _messaging.getToken();
      debugPrint('FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle message when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was opened from a notification when it was terminated
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Handle the message based on data
    _processNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message clicked: ${message.messageId}');
    debugPrint('Data: ${message.data}');

    // Navigate to appropriate screen based on notification data
    _processNotification(message);
  }

  void _processNotification(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'application_status_updated':
        // Navigate to applications screen
        debugPrint('Navigate to applications screen');
        break;
      case 'new_application':
        // Navigate to applicants screen
        debugPrint('Navigate to applicants screen');
        break;
      case 'company_approved':
        // Navigate to dashboard
        debugPrint('Navigate to company dashboard');
        break;
      case 'new_internship':
        // Navigate to internship detail
        debugPrint('Navigate to internship detail');
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  Future<void> saveTokenToDatabase(String userId) async {
    try {
      final token = await getToken();
      if (token != null) {
        // Save token to Firestore user document
        // This would be implemented with your Firestore service
        debugPrint('Save token $token for user $userId');
      }
    } catch (e) {
      debugPrint('Error saving token to database: $e');
    }
  }

  Future<void> deleteTokenFromDatabase(String userId) async {
    try {
      // Remove token from Firestore user document
      // This would be implemented with your Firestore service
      debugPrint('Delete token for user $userId');
    } catch (e) {
      debugPrint('Error deleting token from database: $e');
    }
  }
}

// Top-level function for background message handling
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}
