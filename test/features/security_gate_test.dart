import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_bolsillo/core/security/device_security.dart';
import 'package:mi_bolsillo/core/security/security_gate.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/finance_fixture.dart';

class _Device extends DeviceSecurity {
  bool allowed = true;
  bool setup = true;
  int prompts = 0;
  Completer<bool>? pending;
  @override
  bool get supported => true;
  @override
  Future<bool> configured() async => setup;
  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return pending?.future ?? allowed;
  }
}

class _CancelledPicker extends FilePickerPlatform {
  _CancelledPicker(this.fail);
  final bool fail;
  int cleanups = 0;
  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    if (fail) throw StateError('synthetic picker failure');
    return [];
  }

  @override
  Future<void> clearTemporaryFiles() async {
    cleanups++;
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));
  for (final fail in [false, true]) {
    testWidgets('import cleans picker cache after cancellation/failure=$fail', (
      tester,
    ) async {
      final previous = FilePickerPlatform.instance;
      final picker = _CancelledPicker(fail);
      FilePickerPlatform.instance = picker;
      addTearDown(() => FilePickerPlatform.instance = previous);
      final db = await pumpFinance(tester, AppRoutes.profile);
      final before = await tester.runAsync(() => db.select(db.movements).get());
      await tester.ensureVisible(find.text('Restaurar copia local'));
      await tester.tap(find.text('Restaurar copia local'));
      await tester.pumpAndSettle();
      expect(picker.cleanups, 1);
      expect(find.text('Procesando copia local…'), findsNothing);
      expect(
        await tester.runAsync(() => db.select(db.movements).get()),
        before,
      );
    });
  }
  testWidgets(
    'cancelled step-up preserves financial data and prevents backup export',
    (tester) async {
      final device = _Device()..allowed = false;
      final db = await pumpFinance(tester, AppRoutes.profile, security: device);
      final before = await tester.runAsync(() => db.select(db.movements).get());
      await tester.ensureVisible(find.text('Borrar datos locales'));
      await tester.tap(find.text('Borrar datos locales'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Borrar todo'));
      await tester.pumpAndSettle();
      final after = await tester.runAsync(() => db.select(db.movements).get());
      expect(after, before);
      expect(device.prompts, 1);
      await tester.ensureVisible(find.text('Exportar copia local'));
      await tester.tap(find.text('Exportar copia local'));
      await tester.pumpAndSettle();
      expect(device.prompts, 2);
      expect(find.text('Proteger copia de seguridad'), findsNothing);
      expect(find.text('Procesando copia local…'), findsNothing);
    },
  );

  testWidgets('hidden finance forms cannot retain keyboard focus', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [deviceSecurityProvider.overrideWithValue(_Device())],
        child: SecurityGate(
          child: MaterialApp(
            home: Scaffold(body: TextField(focusNode: focus)),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Desbloquear'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isFalse);
    expect(find.byType(TextField), findsNothing);
  });
  testWidgets('idle timeout locks the financial view', (tester) async {
    final device = _Device();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [deviceSecurityProvider.overrideWithValue(device)],
        child: const SecurityGate(
          idleTimeout: Duration(seconds: 2),
          child: MaterialApp(home: Text('SYNTHETIC FINANCES')),
        ),
      ),
    );
    await tester.tap(find.text('Desbloquear'));
    await tester.pumpAndSettle();
    expect(find.text('SYNTHETIC FINANCES'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('SYNTHETIC FINANCES'), findsNothing);
  });
  testWidgets(
    'cold start is locked; cancel cannot show finances; background relocks',
    (tester) async {
      final device = _Device()..allowed = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [deviceSecurityProvider.overrideWithValue(device)],
          child: const SecurityGate(
            child: MaterialApp(
              home: Scaffold(body: Text('SYNTHETIC FINANCES')),
            ),
          ),
        ),
      );
      expect(find.text('SYNTHETIC FINANCES'), findsNothing);
      await tester.tap(find.text('Desbloquear'));
      await tester.pumpAndSettle();
      expect(find.text('SYNTHETIC FINANCES'), findsNothing);
      device.allowed = true;
      await tester.tap(find.text('Desbloquear'));
      await tester.pumpAndSettle();
      expect(find.text('SYNTHETIC FINANCES'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('SYNTHETIC FINANCES'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('SYNTHETIC FINANCES'), findsNothing);
      expect(find.text('Desbloquear'), findsOneWidget);
    },
  );

  testWidgets(
    'no device credential fails closed and directs to Android settings',
    (tester) async {
      final device = _Device()..setup = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [deviceSecurityProvider.overrideWithValue(device)],
          child: const SecurityGate(child: Text('SYNTHETIC FINANCES')),
        ),
      );
      await tester.tap(find.text('Desbloquear'));
      await tester.pumpAndSettle();
      expect(find.text('Configurar bloqueo'), findsOneWidget);
      expect(device.prompts, 0);
      expect(find.text('SYNTHETIC FINANCES'), findsNothing);
    },
  );

  test(
    'sensitive operations always prompt; overlapping prompts are rejected',
    () async {
      final device = _Device();
      final container = ProviderContainer(
        overrides: [deviceSecurityProvider.overrideWithValue(device)],
      );
      addTearDown(container.dispose);
      final session = container.read(securitySessionProvider.notifier);
      expect(await session.unlock(), isTrue);
      expect(await session.unlock('Exportar'), isTrue);
      expect(device.prompts, 2);
      device.pending = Completer<bool>();
      final first = session.unlock('Borrar');
      expect(await session.unlock('Borrar'), isFalse);
      session.background();
      device.pending!.complete(false);
      expect(await first, isFalse);
      expect(container.read(securitySessionProvider), isFalse);
    },
  );
}
