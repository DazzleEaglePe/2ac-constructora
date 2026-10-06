class AuditLog {
  const AuditLog({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    required this.userName,
    required this.dni,
    this.before,
    this.after,
  });

  final String id;
  final String action;
  final String entityType;
  final String entityId;
  final DateTime createdAt;
  final String? userName;
  final String? dni;
  final Object? before;
  final Object? after;

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AuditLog(
      id: json['id'] as String,
      action: json['action'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      userName: user?['fullName'] as String?,
      dni: user?['dni'] as String?,
      before: json['before'],
      after: json['after'],
    );
  }
}

class AuditLogPage {
  const AuditLogPage({required this.items, this.nextCursor});

  final List<AuditLog> items;
  final String? nextCursor;

  factory AuditLogPage.fromJson(Map<String, dynamic> json) => AuditLogPage(
    items: (json['data'] as List<dynamic>)
        .map((item) => AuditLog.fromJson(item as Map<String, dynamic>))
        .toList(),
    nextCursor: json['nextCursor'] as String?,
  );
}
