import 'package:sembast_web/sembast_web.dart';

/// Opens KINTA's browser-local database backed by IndexedDB.
class KintaLocalDatabase {
  KintaLocalDatabase._();

  static Future<Database>? _databaseFuture;

  /// Opens the database once and reuses the same opening operation thereafter.
  static Future<Database> open() {
    return _databaseFuture ??=
        databaseFactoryWeb.openDatabase('kinta_local.db');
  }
}
