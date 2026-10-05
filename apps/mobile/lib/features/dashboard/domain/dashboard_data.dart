import '../../sites/domain/site.dart';

class DashboardTotals {
  const DashboardTotals({
    required this.unitsOnSites,
    required this.assetsInMaintenance,
    required this.activeSites,
    required this.warehouseUnits,
    required this.openObservations,
  });

  final int unitsOnSites;
  final int assetsInMaintenance;
  final int activeSites;
  final int warehouseUnits;
  final int openObservations;

  factory DashboardTotals.fromJson(Map<String, dynamic> json) =>
      DashboardTotals(
        unitsOnSites: (json['unitsOnSites'] as num?)?.toInt() ?? 0,
        assetsInMaintenance:
            (json['assetsInMaintenance'] as num?)?.toInt() ?? 0,
        activeSites: (json['activeSites'] as num?)?.toInt() ?? 0,
        warehouseUnits: (json['warehouseUnits'] as num?)?.toInt() ?? 0,
        openObservations: (json['openObservations'] as num?)?.toInt() ?? 0,
      );
}

class DashboardData {
  const DashboardData({
    required this.generatedAt,
    required this.totals,
    required this.sites,
    required this.warehouse,
    required this.changedSince,
  });

  final DateTime generatedAt;
  final DashboardTotals totals;
  final List<Site> sites;
  final Site? warehouse;
  final bool changedSince;

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
    generatedAt: DateTime.parse(json['generatedAt'] as String),
    totals: DashboardTotals.fromJson(json['totals'] as Map<String, dynamic>),
    sites: (json['sites'] as List<dynamic>? ?? const [])
        .map((site) => Site.fromJson(site as Map<String, dynamic>))
        .toList(growable: false),
    warehouse: json['warehouse'] == null
        ? null
        : Site.fromJson(json['warehouse'] as Map<String, dynamic>),
    changedSince: json['changedSince'] as bool? ?? true,
  );
}
