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
    required this.revertsId,
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
  final String? revertsId;
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
    revertsId: json['revertsId'] as String?,
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

class OpenObservation {
  const OpenObservation({
    required this.id,
    required this.assetId,
    required this.assetName,
    required this.type,
    required this.description,
    required this.fromName,
    required this.toName,
    required this.createdAt,
  });

  final String id;
  final String assetId;
  final String assetName;
  final String type;
  final String description;
  final String? fromName;
  final String? toName;
  final DateTime createdAt;

  factory OpenObservation.fromJson(Map<String, dynamic> json) {
    final asset = json['asset'] as Map<String, dynamic>;
    final movement = json['movement'] as Map<String, dynamic>;
    final from = movement['fromSite'] as Map<String, dynamic>?;
    final to = movement['toSite'] as Map<String, dynamic>?;
    return OpenObservation(
      id: json['id'] as String,
      assetId: asset['id'] as String,
      assetName: asset['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      fromName: from?['name'] as String?,
      toName: to?['name'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
