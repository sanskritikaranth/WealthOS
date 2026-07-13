import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _androidChannel = MethodChannel('wealth_os/native_notifications');

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _androidChannel.invokeMethod('initializeNativeChannel');
      }
    } catch (e) {
      debugPrint('Native channel initialization handled: $e');
    }
  }

  static Future<void> showNativeNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _androidChannel.invokeMethod('dispatchSystemPush', {
          'id': id,
          'title': title,
          'body': body,
          'payload': payload ?? '',
        });
      }
    } catch (e) {
      debugPrint('Native push dispatch handled: $e');
    }
  }
}