class MovementSite {
  const MovementSite({required this.id, required this.name});
  final String id;
  final String name;

  factory MovementSite.fromJson(Map<String, dynamic> json) =>
      MovementSite(id: json['id'] as String, name: json['name'] as String);
}

class Movement {
  const Movement({
    required this.id,
    required this.kind,
    required this.quantity,
    required this.from,
    required this.to,
    required this.userName,
    required this.note,
    required this.createdAt,
    required this.observation,
  });

  final String id;
  final String kind;
  final int quantity;
  final MovementSite? from;
  final MovementSite? to;
  final String userName;
  final String? note;
  final DateTime createdAt;
  final Map<String, dynamic>? observation;

  factory Movement.fromJson(Map<String, dynamic> json) => Movement(
    id: json['id'] as String,
    kind: json['kind'] as String,
    quantity: (json['quantity'] as num).toInt(),
    from: json['fromSite'] == null
        ? null
        : MovementSite.fromJson(json['fromSite'] as Map<String, dynamic>),
    to: json['toSite'] == null
        ? null
        : MovementSite.fromJson(json['toSite'] as Map<String, dynamic>),
    userName: (json['user'] as Map<String, dynamic>)['fullName'] as String,
    note: json['note'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    observation: json['observation'] as Map<String, dynamic>?,
  );
}
