import '../entidades/sesion.dart';

/// **Contrato del repositorio de sesión** (capa Domain, Semana 8).
///
/// La capa de presentación pide este contrato, nunca una implementación
/// concreta. Gracias a eso, el mismo código de pantalla funciona con:
///
/// | Implementación | Almacén | Uso |
/// |---|---|---|
/// | `SesionRepositorySeguro` | `flutter_secure_storage` (Keystore / Keychain) | aplicación real |
/// | `SesionRepositorySeguro` + `AlmacenSeguroEnMemoria` | diccionario en RAM | pruebas automáticas |
/// | `SesionRepositoryInseguro` | tabla `preferencias` de SQLite | **solo demostración del antipatrón** |
///
/// Esta es la misma estrategia que la Semana 10 aplicó con
/// `AuditoriaRepository` y `IndicadorRepository`: el dominio fija el
/// contrato, `data/` aporta las implementaciones y `presentation/di.dart`
/// decide cuál se inyecta.
abstract interface class SesionRepository {
  /// Guarda (o reemplaza) la sesión activa.
  ///
  /// Debe ser idempotente: guardar dos veces la misma sesión deja el mismo
  /// resultado y no duplica registros.
  Future<void> guardar(Sesion sesion);

  /// Devuelve la sesión guardada, o `null` si no hay ninguna.
  ///
  /// Si el contenido almacenado está corrupto, la implementación **no**
  /// propaga el error de formato: lo traduce a `FalloDeValidacion` para que
  /// la pantalla pueda ofrecer "cerrar sesión y volver a entrar".
  Future<Sesion?> leer();

  /// `true` si hay una sesión guardada y su token sigue vigente.
  Future<bool> haySesionActiva();

  /// Elimina por completo la sesión (botón "Cerrar sesión").
  Future<void> cerrar();
}
