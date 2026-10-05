class AssetDistribution {
  const AssetDistribution({
    required this.siteId,
    required this.siteName,
    required this.siteType,
    required this.quantity,
  });

  final String siteId;
  final String siteName;
  final String siteType;
  final int quantity;

  factory AssetDistribution.fromJson(Map<String, dynamic> json) =>
      AssetDistribution(
        siteId: json['siteId'] as String,
        siteName: json['siteName'] as String,
        siteType: json['siteType'] as String,
        quantity: (json['quantity'] as num).toInt(),
      );
}

class Asset {
  const Asset({
    required this.id,
    required this.code,
    required this.type,
    required this.name,
    required this.description,
    required this.status,
    required this.totalStock,
    required this.distribution,
    required this.notesCount,
  });

  final String id;
  final String code;
  final String type;
  final String name;
  final String? description;
  final String status;
  final int totalStock;
  final List<AssetDistribution> distribution;
  final int notesCount;

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
    id: json['id'] as String,
    code: json['code'] as String,
    type: json['type'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    status: json['status'] as String,
    totalStock: (json['totalStock'] as num).toInt(),
    distribution: (json['distribution'] as List<dynamic>? ?? const [])
        .map((row) => AssetDistribution.fromJson(row as Map<String, dynamic>))
        .toList(growable: false),
    notesCount: (json['notesCount'] as num?)?.toInt() ?? 0,
  );
}

class AssetNote {
  const AssetNote({
    required this.id,
    required this.body,
    required this.userName,
    required this.createdAt,
  });

  final String id;
  final String body;
  final String userName;
  final DateTime createdAt;

  factory AssetNote.fromJson(Map<String, dynamic> json) => AssetNote(
    id: json['id'] as String,
    body: json['body'] as String,
    userName: json['userName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
