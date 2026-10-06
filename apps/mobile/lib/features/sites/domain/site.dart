class SiteSummary {
  const SiteSummary({
    required this.units,
    required this.assetCount,
    required this.lastMovementAt,
    required this.topItems,
  });

  final int units;
  final int assetCount;
  final DateTime? lastMovementAt;
  final List<SiteTopItem> topItems;

  factory SiteSummary.fromJson(Map<String, dynamic> json) => SiteSummary(
    units: (json['units'] as num?)?.toInt() ?? 0,
    assetCount: (json['assetCount'] as num?)?.toInt() ?? 0,
    lastMovementAt: json['lastMovementAt'] == null
        ? null
        : DateTime.parse(json['lastMovementAt'] as String),
    topItems: (json['topItems'] as List<dynamic>? ?? const [])
        .map((item) => SiteTopItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class SiteTopItem {
  const SiteTopItem({required this.name, required this.quantity});

  final String name;
  final int quantity;

  factory SiteTopItem.fromJson(Map<String, dynamic> json) => SiteTopItem(
    name: json['name'] as String,
    quantity: (json['quantity'] as num).toInt(),
  );
}

class Site {
  const Site({
    required this.id,
    required this.type,
    required this.name,
    required this.ownerName,
    required this.address,
    required this.lat,
    required this.lng,
    required this.status,
    required this.summary,
  });

  final String id;
  final String type;
  final String name;
  final String? ownerName;
  final String? address;
  final double? lat;
  final double? lng;
  final String status;
  final SiteSummary summary;

  bool get isWarehouse => type == 'ALMACEN';
  bool get isClosed => status == 'CERRADA';

  factory Site.fromJson(Map<String, dynamic> json) => Site(
    id: json['id'] as String,
    type: json['type'] as String,
    name: json['name'] as String,
    ownerName: json['ownerName'] as String?,
    address: json['address'] as String?,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    status: json['status'] as String,
    summary: SiteSummary.fromJson(json['summary'] as Map<String, dynamic>),
  );
}

class SiteStockItem {
  const SiteStockItem({
    required this.id,
    required this.code,
    required this.type,
    required this.name,
    required this.status,
    required this.quantity,
  });

  final String id;
  final String code;
  final String type;
  final String name;
  final String status;
  final int quantity;

  factory SiteStockItem.fromJson(Map<String, dynamic> json) => SiteStockItem(
    id: json['id'] as String,
    code: json['code'] as String,
    type: json['type'] as String,
    name: json['name'] as String,
    status: json['status'] as String,
    quantity: (json['quantity'] as num).toInt(),
  );
}
