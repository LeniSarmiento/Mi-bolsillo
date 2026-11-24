import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_bolsillo/app/providers.dart';
import 'package:mi_bolsillo/core/notifications/app_notifications.dart';
import 'package:mi_bolsillo/data/finance_database.dart';
import 'package:mi_bolsillo/features/profile/application/settings_controller.dart';

class PermissionNotifications implements AppNotifications {
  bool permissionGranted = false;
  bool throwOnSchedule = false;
  int permissionRequests = 0;
  final scheduledValues = <bool>[];

  @override
  bool get supported => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<bool> showBudgetAlert({
    required int id,
    required String category,
    required int percentUsed,
    required bool exhausted,
  }) async => true;

  @override
  Future<bool> syncDailyReminder(bool enabled) async {
    if (throwOnSchedule) throw StateError('scheduler unavailable');
    scheduledValues.add(enabled);
    return true;
  }
}

void main() {
  late FinanceDatabase database;
  late PermissionNotifications notifications;
  late ProviderContainer container;

  setUp(() {
    database = FinanceDatabase(NativeDatabase.memory());
    notifications = PermissionNotifications();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        appNotificationsProvider.overrideWithValue(notifications),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  test('no activa recordatorio cuando el permiso es rechazado', () async {
    final controller = container.read(settingsControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    expect(await controller.toggleDailyReminder(true), isFalse);
    expect(
      container.read(settingsControllerProvider).dailyReminderEnabled,
      isFalse,
    );
    expect(notifications.permissionRequests, 1);
    expect(notifications.scheduledValues, isEmpty);
  });

  test('activa y desactiva el recordatorio tras sincronizar Android', () async {
    notifications.permissionGranted = true;
    final controller = container.read(settingsControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    expect(await controller.toggleDailyReminder(true), isTrue);
    expect(
      container.read(settingsControllerProvider).dailyReminderEnabled,
      isTrue,
    );
    expect(await controller.toggleDailyReminder(false), isTrue);
    expect(
      container.read(settingsControllerProvider).dailyReminderEnabled,
      isFalse,
    );
    expect(notifications.scheduledValues, [true, false]);
  });

  test('una falla del programador no persiste una preferencia falsa', () async {
    notifications.permissionGranted = true;
    notifications.throwOnSchedule = true;
    final controller = container.read(settingsControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    expect(await controller.toggleDailyReminder(true), isFalse);
    expect(
      container.read(settingsControllerProvider).dailyReminderEnabled,
      isFalse,
    );
  });
}
