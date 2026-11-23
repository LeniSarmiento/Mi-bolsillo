import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/routing/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO');
  runApp(const ProviderScope(child: FinanceStartup()));
}

class FinanceStartup extends ConsumerStatefulWidget {
  const FinanceStartup({super.key});
  @override
  ConsumerState<FinanceStartup> createState() => _StartupState();
}

class _StartupState extends ConsumerState<FinanceStartup> {
  late Future<bool> opening = _open();
  Future<bool> _open() async {
    await ref.read(ledgerProvider).generateDue();
    return (await ref.read(settingsRepositoryProvider).getSettings())
        .onboardingCompleted;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: opening,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return MiBolsilloApp(
          initialLocation: snapshot.data!
              ? AppRoutes.dashboard
              : AppRoutes.welcome,
        );
      }
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: snapshot.hasError
                ? FilledButton(
                    onPressed: () {
                      ref.invalidate(databaseProvider);
                      setState(() => opening = _open());
                    },
                    child: const Text(
                      'No se pudieron abrir los datos. Reintentar',
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}
