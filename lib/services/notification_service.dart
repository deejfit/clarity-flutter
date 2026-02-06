import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const int _dailyNotificationId = 0;
const String _channelId = 'clarity_daily';
const String _channelName = 'Daily reminder';

abstract class NotificationService {
  Future<bool> get isSupported;
  Future<void> initialize();
  Future<void> requestPermission();
  Future<void> scheduleDailyAt(int hour, int minute);
  Future<void> cancelAll();
}

class NotificationServiceImpl implements NotificationService {
  NotificationServiceImpl() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<bool> get isSupported async {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Future<void> initialize() async {
    if (kIsWeb) return;
    if (!await isSupported) return;
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) {},
    );
    _initialized = true;

    try {
      tz.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.local);
    }
  }

  @override
  Future<void> requestPermission() async {
    if (kIsWeb || !await isSupported) return;
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  @override
  Future<void> scheduleDailyAt(int hour, int minute) async {
    if (kIsWeb || !await isSupported) return;
    await initialize();
    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily check-in reminder',
      importance: Importance.defaultImportance,
    );
    const darwin = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: darwin);

    await _plugin.zonedSchedule(
      id: _dailyNotificationId,
      title: 'Clarity',
      body: 'Time for your daily check-in.',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelAll() async {
    if (kIsWeb || !await isSupported) return;
    await _plugin.cancelAll();
  }
}
