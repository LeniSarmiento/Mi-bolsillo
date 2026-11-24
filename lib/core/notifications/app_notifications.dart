import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract interface class AppNotifications {
  bool get supported;

  Future<void> initialize();

  Future<bool> requestPermission();

  Future<bool> syncDailyReminder(bool enabled);

  Future<bool> showBudgetAlert({
    required int id,
    required String category,
    required int percentUsed,
    required bool exhausted,
  });
}

class LocalAppNotifications implements AppNotifications {
  LocalAppNotifications({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const dailyReminderId = 1001;
  static const _dailyChannel = 'daily_review';
  static const _budgetChannel = 'budget_alerts';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> initialize() async {
    if (!supported || _initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Bogota'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_mi_bolsillo'),
      ),
    );
    _initialized = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<bool> _hasPermission() async {
    if (!supported) return false;
    await initialize();
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    if (!supported) return false;
    await initialize();
    if (await _hasPermission()) return true;
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<bool> syncDailyReminder(bool enabled) async {
    if (!supported) return false;
    await initialize();
    await _plugin.cancel(id: dailyReminderId);
    if (!enabled || !await _hasPermission()) return !enabled;

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: dailyReminderId,
      title: 'Revisa tus gastos de hoy',
      body: 'Confirma que tus movimientos estén completos y actualizados.',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannel,
          'Recordatorio diario',
          channelDescription: 'Recordatorio para revisar los gastos del día',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily-review',
    );
    return true;
  }

  @override
  Future<bool> showBudgetAlert({
    required int id,
    required String category,
    required int percentUsed,
    required bool exhausted,
  }) async {
    if (!supported || !await _hasPermission()) return false;

    await _plugin.show(
      id: id,
      title: exhausted
          ? 'Presupuesto de $category agotado'
          : 'Presupuesto de $category al $percentUsed %',
      body: exhausted
          ? 'Revisa tus gastos y ajusta tu plan para este periodo.'
          : 'Estás cerca del límite que configuraste para este periodo.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _budgetChannel,
          'Alertas de presupuesto',
          channelDescription: 'Avisos al acercarse o llegar a un límite',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: 'budgets',
    );
    return true;
  }
}

class DisabledAppNotifications implements AppNotifications {
  const DisabledAppNotifications();

  @override
  bool get supported => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> showBudgetAlert({
    required int id,
    required String category,
    required int percentUsed,
    required bool exhausted,
  }) async => false;

  @override
  Future<bool> syncDailyReminder(bool enabled) async => !enabled;
}
