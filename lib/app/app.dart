import 'dart:async';

import '../data/local_detection.dart';
import '../features/income/application/income_controller.dart';
import '../features/transactions/application/transactions_controller.dart';
import '../features/automatic_detection/application/automatic_detection_controller.dart';
import 'providers.dart';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_bolsillo/core/routing/app_router.dart';
import 'package:mi_bolsillo/core/routing/app_routes.dart';
import 'package:mi_bolsillo/core/theme/app_theme.dart';
import 'package:mi_bolsillo/features/profile/application/settings_controller.dart';

/// Root MaterialApp.router configured with Emerald Warmth light/dark themes.
class MiBolsilloApp extends ConsumerStatefulWidget {
  const MiBolsilloApp({super.key, this.initialLocation = AppRoutes.welcome});

  final String initialLocation;

  @override
  ConsumerState<MiBolsilloApp> createState() => _MiBolsilloAppState();
}

class _MiBolsilloAppState extends ConsumerState<MiBolsilloApp>
    with WidgetsBindingObserver {
  Timer? _midnight;
  late final bool _hasBridge = ref.read(bridgeProvider).supported;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_hasBridge) {
      NotificationBridge.channel.setMethodCallHandler((call) async {
        if (call.method == 'arrival' && mounted) {
          await ref.read(automaticDetectionControllerProvider.notifier).load();
        }
      });
    }
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    _midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      _refresh,
    );
  }

  void _refresh() {
    if (!mounted) return;
    _scheduleMidnight();
    ref.invalidate(transactionsControllerProvider);
    ref.invalidate(incomeControllerProvider);
    ref.invalidate(automaticDetectionControllerProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  late final GoRouter _router = createAppRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_hasBridge) NotificationBridge.channel.setMethodCallHandler(null);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(
      settingsControllerProvider.select((s) => s.themeMode),
    );

    return MaterialApp.router(
      title: 'Mi Bolsillo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
