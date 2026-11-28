import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_security.dart';

/// Mounted outside the financial startup, so locked cold starts read no money.
class SecurityGate extends ConsumerStatefulWidget {
  const SecurityGate({
    super.key,
    required this.child,
    this.idleTimeout = const Duration(minutes: 5),
  });
  final Widget child;
  final Duration idleTimeout;
  @override
  ConsumerState<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends ConsumerState<SecurityGate>
    with WidgetsBindingObserver {
  bool _busy = false;
  bool _needsSetup = false;
  bool _openedOnce = false;
  bool _obscured = false;
  Timer? _idle;
  void _touch() {
    _idle?.cancel();
    if (ref.read(securitySessionProvider)) {
      _idle = Timer(
        widget.idleTimeout,
        () => ref.read(securitySessionProvider.notifier).lock(),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _idle?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _obscured = state != AppLifecycleState.resumed);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _idle?.cancel();
      ref.read(securitySessionProvider.notifier).background();
    }
    if (state == AppLifecycleState.resumed) _touch();
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final configured = await ref.read(deviceSecurityProvider).configured();
      if (!mounted) return;
      setState(() => _needsSetup = !configured);
      if (configured) await ref.read(securitySessionProvider.notifier).unlock();
    } catch (_) {
      // Fail closed; no financial detail or platform exception is displayed.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supported = ref.watch(deviceSecurityProvider).supported;
    if (!supported) return widget.child;
    final unlocked = ref.watch(securitySessionProvider);
    ref.listen(securitySessionProvider, (_, next) {
      if (next) {
        _touch();
      } else {
        _idle?.cancel();
      }
    });
    if (unlocked) _openedOnce = true;
    return Listener(
      onPointerDown: (_) => _touch(),
      onPointerMove: (_) => _touch(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            if (_openedOnce)
              Offstage(
                offstage: !unlocked || _obscured,
                child: ExcludeFocus(
                  excluding: !unlocked || _obscured,
                  child: widget.child,
                ),
              ),
            if (!unlocked || _obscured)
              MaterialApp(
                debugShowCheckedModeBanner: false,
                home: PopScope(
                  canPop: false,
                  child: Scaffold(
                    body: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_outline, size: 48),
                                const SizedBox(height: 16),
                                const Text('Mi Bolsillo está protegido'),
                                const SizedBox(height: 12),
                                Text(
                                  _needsSetup
                                      ? 'Configura un PIN, patrón o contraseña de Android para proteger tus finanzas.'
                                      : 'Confirma tu identidad con el bloqueo de tu dispositivo.',
                                ),
                                const SizedBox(height: 20),
                                if (_needsSetup)
                                  TextButton(
                                    onPressed: () => ref
                                        .read(deviceSecurityProvider)
                                        .openSettings(),
                                    child: const Text('Configurar bloqueo'),
                                  ),
                                FilledButton(
                                  onPressed: _busy || _obscured
                                      ? null
                                      : _unlock,
                                  child: Text(
                                    _busy ? 'Verificando…' : 'Desbloquear',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
