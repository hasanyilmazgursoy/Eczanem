import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../features/reminder/data/medication_reminder_repository.dart';
import '../utils/utils.dart';
import 'storage_service.dart';

/// Yerel bildirimleri başlatır ve ilaç hatırlatıcılarını cihaz takvimine göre
/// günlük tekrar edecek şekilde planlar.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _scheduledIdsKey = 'medication_reminder_notification_ids_v1';
  static const _androidChannelId = 'medication_reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  FutureEither<void> init() async {
    if (_initialized) {
      return runTask(() async {});
    }

    return runTask(() async {
      tz_data.initializeTimeZones();
      await _configureLocalTimezone();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      final initialized = await _plugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
          macOS: darwinSettings,
        ),
      );

      if (initialized != true) {
        throw Exception('Notification plugin could not be initialized.');
      }

      await _createAndroidChannel();
      _initialized = true;
      AppLogger.success('NotificationService initialized');
    });
  }

  FutureEither<bool> requestReminderPermissions() async {
    return runTask(() async {
      if (!_initialized) {
        final initResult = await init();
        if (initResult.isLeft()) {
          throw Exception('Notification service initialization failed.');
        }
      }

      var isGranted = true;

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final requested = await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
        isGranted = requested ?? true;
        isGranted =
            (await androidPlugin.areNotificationsEnabled()) ?? isGranted;
      }

      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final requested = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        isGranted = requested ?? isGranted;
      }

      final macosPlugin = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (macosPlugin != null) {
        final requested = await macosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        isGranted = requested ?? isGranted;
      }

      return isGranted;
    });
  }

  FutureEither<void> syncMedicationReminders(
    List<MedicationReminder> reminders,
  ) async {
    return runTask(() async {
      if (!_initialized) {
        final initResult = await init();
        if (initResult.isLeft()) {
          throw Exception('Notification service initialization failed.');
        }
      }

      final previousIds = _readStoredIds();
      for (final id in previousIds) {
        await _plugin.cancel(id);
      }

      final nextIds = <int>[];
      for (final reminder in reminders.where((item) => item.isActive)) {
        for (var slotIndex = 0;
            slotIndex < reminder.reminderTimes.length;
            slotIndex++) {
          final reminderTime = reminder.reminderTimes[slotIndex];
          final notificationId = _buildNotificationId(reminder.id, slotIndex);
          await _plugin.zonedSchedule(
            notificationId,
            _buildTitle(),
            _buildBody(reminder),
            _nextInstanceOf(reminderTime),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                _androidChannelId,
                'Medication reminders',
                channelDescription:
                    'Daily reminders for scheduled medication doses',
                importance: Importance.max,
                priority: Priority.high,
                category: AndroidNotificationCategory.reminder,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: '${reminder.id}:$slotIndex',
          );
          nextIds.add(notificationId);
        }
      }

      await StorageService.instance.setStringList(
        _scheduledIdsKey,
        nextIds.map((item) => item.toString()).toList(),
      );

      AppLogger.info(
        'Medication reminder notifications synced (${nextIds.length} scheduled)',
      );
    });
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (error, stackTrace) {
      // Yerel saat dilimi çözülemezse UTC'ye düşmek en güvenli yedek plandır.
      AppLogger.warning('Falling back to UTC timezone for notifications');
      if (kDebugMode) {
        AppLogger.error('Timezone resolution failed', error, stackTrace);
      }
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> _createAndroidChannel() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        'Medication reminders',
        description: 'Daily reminders for scheduled medication doses',
        importance: Importance.max,
      ),
    );
  }

  List<int> _readStoredIds() {
    final rawIds = StorageService.instance.getStringList(_scheduledIdsKey) ??
        const <String>[];
    return rawIds.map((value) => int.tryParse(value)).whereType<int>().toList();
  }

  int _buildNotificationId(String reminderId, int slotIndex) {
    final input = '$reminderId:$slotIndex';
    var hash = 0;

    for (final codeUnit in input.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }

    return hash;
  }

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  String _buildTitle() {
    return _currentLanguageCode == 'tr'
        ? 'İlaç hatırlatıcısı'
        : 'Medication reminder';
  }

  String _buildBody(MedicationReminder reminder) {
    if (_currentLanguageCode == 'tr') {
      return '${reminder.drugName} için ${reminder.unitsPerDose} tablet alma zamanı.';
    }

    return 'Time to take ${reminder.unitsPerDose} tablet(s) of ${reminder.drugName}.';
  }

  String get _currentLanguageCode {
    final locale = PlatformDispatcher.instance.locale;
    return locale.languageCode.toLowerCase();
  }
}
