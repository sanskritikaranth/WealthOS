import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';

class NotificationNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    return [
      {
        'id': 'seed_sip_1',
        'title': '💰 Monthly SIP Action Required',
        'body': 'Your recurring monthly investment target date is active. Tap to allocate.',
        'type': 'reminder',
      },
      {
        'id': 'seed_portfolio_1',
        'title': '📈 Portfolio Wealth Milestone 🎉',
        'body': 'Outstanding moves! Your total asset valuation has officially crossed the threshold.',
        'type': 'milestone',
      }
    ];
  }

  void triggerCombinedAlert({
    required String title,
    required String body,
    required String type,
    required int nativeId,
  }) {
    // Avoid double logging identical alerts
    if (state.any((alert) => alert['title'] == title && alert['body'] == body)) return;

    state = [
      ...state,
      {
        // ✅ FIX: Append nativeId to guarantee a completely unique key, 
        // even if 5 alerts fire in the exact same millisecond.
        'id': '${DateTime.now().millisecondsSinceEpoch}_$nativeId',
        'title': title,
        'body': body,
        'type': type,
      }
    ];

    NotificationService.showNativeNotification(
      id: nativeId,
      title: title,
      body: body,
      payload: type,
    );
  }

  void dismissAlert(String id) {
    state = state.where((alert) => alert['id']?.toString() != id).toList();
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, List<Map<String, dynamic>>>(() {
  return NotificationNotifier();
});