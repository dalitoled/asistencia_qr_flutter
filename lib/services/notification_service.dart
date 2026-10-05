import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialization might be needed here if accessing plugins
  print('Handling a background message: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _requestPermissions();
    await _initializeLocalNotifications();
    await _setupForegroundHandler();
    await _setupBackgroundHandler();
  }

  Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
  }

  Future<void> _setupForegroundHandler() async {
    FirebaseMessaging.onMessage.listen((message) {
      _showNotification(
        title: message.notification?.title ?? 'Notificación',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    });
  }

  Future<void> _setupBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }



  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'asistencia_channel',
      'Notificaciones de Asistencia',
      channelDescription: 'Canal de notificaciones del sistema de asistencia',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<String?> getToken() async {
    return _firebaseMessaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  Future<void> sendNotification({
    required String title,
    required String body,
    String? topic,
    String? token,
  }) async {
    final Map<String, dynamic> data = {
      'notification': {
        'title': title,
        'body': body,
      },
    };

    if (topic != null) {
      data['topic'] = topic;
    } else if (token != null) {
      data['token'] = token;
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await _showNotification(title: title, body: body);
  }
}