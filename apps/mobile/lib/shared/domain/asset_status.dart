/// Estado de un activo (docs/01 §5). Coincide con el enum `AssetStatus` de la API.
enum AssetStatus {
  operativo,
  mantenimiento,
  baja;

  static AssetStatus fromApi(String value) =>
      AssetStatus.values.firstWhere((s) => s.name == value.toLowerCase());

  String get apiValue => name.toUpperCase();
}
