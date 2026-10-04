// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'A2C Inventario';

  @override
  String get brandName => 'Constructora A2C';

  @override
  String get tagline => 'Tu visión — nuestra ejecución';

  @override
  String get statusOperational => 'Operativo';

  @override
  String get statusMaintenance => 'Mantenimiento';

  @override
  String get statusRetired => 'Baja';

  @override
  String get navSites => 'Obras';

  @override
  String get navInventory => 'Inventario';

  @override
  String get navUsers => 'Usuarios';

  @override
  String get apiOnline => 'API en línea';

  @override
  String get apiOffline => 'API sin conexión';
}
