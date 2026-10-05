/// Roles de A2C (docs/07 §4): el operador ejecuta los traslados; el
/// administrador administra y supervisa.
enum Role {
  admin('ADMIN', 'Administrador'),
  operador('OPERADOR', 'Operador');

  const Role(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static Role fromApi(String value) =>
      Role.values.firstWhere((r) => r.apiValue == value);
}

class AppUser {
  const AppUser({
    required this.id,
    required this.dni,
    required this.fullName,
    required this.role,
    required this.active,
    required this.mustChangePassword,
    this.lastMovementAt,
  });

  final String id;
  final String dni;
  final String fullName;
  final Role role;
  final bool active;
  final bool mustChangePassword;
  final DateTime? lastMovementAt;

  bool get isAdmin => role == Role.admin;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    dni: json['dni'] as String,
    fullName: json['fullName'] as String,
    role: Role.fromApi(json['role'] as String),
    active: json['active'] as bool? ?? true,
    mustChangePassword: json['mustChangePassword'] as bool? ?? false,
    lastMovementAt: json['lastMovementAt'] == null
        ? null
        : DateTime.parse(json['lastMovementAt'] as String),
  );

  AppUser copyWith({bool? mustChangePassword}) => AppUser(
    id: id,
    dni: dni,
    fullName: fullName,
    role: role,
    active: active,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    lastMovementAt: lastMovementAt,
  );
}

class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
  );
}
