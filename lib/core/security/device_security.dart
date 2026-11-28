import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceSecurity {
  static const channel = MethodChannel('com.mibolsillo.app/security');
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<bool> configured() async =>
      !supported || (await channel.invokeMethod<bool>('configured') ?? false);
  Future<bool> authenticate(String reason) async =>
      !supported ||
      (await channel.invokeMethod<bool>('authenticate', reason) ?? false);
  Future<void> openSettings() async {
    if (supported) await channel.invokeMethod<void>('settings');
  }
}

final deviceSecurityProvider = Provider((ref) => DeviceSecurity());

/// Shared state also covers OS authentication started by sensitive actions.
class SecuritySession extends Notifier<bool> {
  bool authenticating = false;
  bool _backgroundDuringPrompt = false;
  @override
  bool build() => !ref.read(deviceSecurityProvider).supported;

  void lock() {
    if (ref.read(deviceSecurityProvider).supported) state = false;
  }

  void background() {
    if (!ref.read(deviceSecurityProvider).supported) return;
    if (authenticating) {
      _backgroundDuringPrompt = true;
      return;
    }
    state = false;
  }

  Future<bool> unlock([String reason = 'Desbloquear Mi Bolsillo']) async {
    if (authenticating) return false;
    authenticating = true;
    _backgroundDuringPrompt = false;
    try {
      final accepted = await ref
          .read(deviceSecurityProvider)
          .authenticate(reason);
      if (accepted) state = true;
      if (!accepted && _backgroundDuringPrompt) state = false;
      return accepted;
    } catch (_) {
      state = false;
      return false;
    } finally {
      authenticating = false;
      _backgroundDuringPrompt = false;
    }
  }
}

final securitySessionProvider = NotifierProvider<SecuritySession, bool>(
  SecuritySession.new,
);
