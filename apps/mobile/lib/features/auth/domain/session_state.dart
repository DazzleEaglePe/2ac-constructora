import 'app_user.dart';

/// Estado de la sesión que decide la navegación (docs/08 §2).
sealed class SessionState {
  const SessionState();
}

/// Aún se está verificando si hay una sesión guardada (durante el splash).
class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class SessionSignedOut extends SessionState {
  const SessionSignedOut({this.reason});

  /// Motivo opcional para mostrar en el ingreso (p. ej., sesión vencida).
  final String? reason;
}

class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.user);

  final AppUser user;
}
