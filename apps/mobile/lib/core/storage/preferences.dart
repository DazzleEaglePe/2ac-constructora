import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Se sobrescribe en `main()` con la instancia ya cargada.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider sin inicializar'),
);

/// RF-BIE-04: el onboarding se muestra una sola vez por dispositivo.
class OnboardingSeenNotifier extends Notifier<bool> {
  static const _key = 'a2c.onboarding_seen';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> markSeen() async {
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
    state = true;
  }
}

final onboardingSeenProvider = NotifierProvider<OnboardingSeenNotifier, bool>(
  OnboardingSeenNotifier.new,
);

/// "Recordar mi DNI en este equipo" (ingreso v2). El DNI identifica al usuario
/// y no es secreto; la contraseña nunca se guarda.
class RememberedDniNotifier extends Notifier<String?> {
  static const _key = 'a2c.remembered_dni';

  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(_key);

  Future<void> remember(String dni) async {
    await ref.read(sharedPreferencesProvider).setString(_key, dni);
    state = dni;
  }

  Future<void> forget() async {
    await ref.read(sharedPreferencesProvider).remove(_key);
    state = null;
  }
}

final rememberedDniProvider = NotifierProvider<RememberedDniNotifier, String?>(
  RememberedDniNotifier.new,
);
