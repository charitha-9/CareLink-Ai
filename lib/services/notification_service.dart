import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging;

  NotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  Future<NotificationSettings> requestPermission() async {
    return await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<String?> getDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  StreamSubscription<RemoteMessage> setupForegroundListener({
    required void Function(RemoteMessage message) onMessageReceived,
  }) {
    return FirebaseMessaging.onMessage.listen(onMessageReceived);
  }

  StreamSubscription<RemoteMessage> setupMessageOpenedAppListener({
    required void Function(RemoteMessage message) onMessageOpenedApp,
  }) {
    return FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
  }

  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }
}