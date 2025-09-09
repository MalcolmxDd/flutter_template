/// Servicio simplificado para migración
/// Como SQLite fue removido, este servicio ahora solo maneja la inicialización
class MigrationService {
  /// Verificar si existen datos para migrar (siempre false ahora)
  static Future<bool> hasDataToMigrate() async {
    return false;
  }

  /// Proceso completo de migración (no hace nada ahora)
  static Future<void> performFullMigration() async {
    // No hay datos SQLite para migrar
    print('No hay datos locales para migrar');
  }
}
