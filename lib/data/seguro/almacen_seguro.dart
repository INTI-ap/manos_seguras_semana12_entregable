/// **Abstracción del almacén cifrado del sistema operativo.**
///
/// Semana 11 — temática 2.2.4 del sílabo: *almacenamiento seguro*. Este
/// archivo define el **puerto** (en el sentido de la arquitectura hexagonal)
/// que la capa de datos ofrece al resto de la aplicación. El plugin
/// `flutter_secure_storage` es un detalle de infraestructura que queda
/// detrás de esta interfaz, exactamente como `drift` quedó detrás de
/// `AuditoriaRepository` en la Semana 10.
///
/// Ventajas concretas de la indirección, que el informe debe justificar:
///
///  1. **Pruebas sin plugin.** Las pruebas automáticas usan
///     `AlmacenSeguroEnMemoria`; no necesitan ni emulador ni llavero del
///     sistema.
///  2. **Sustitución de tecnología.** Cambiar de plugin (o añadir cifrado
///     propio) no toca ni el dominio ni la presentación.
///  3. **Contraste didáctico.** Permite tener, en el mismo proyecto, un
///     almacén seguro y otro deliberadamente inseguro
///     (`AlmacenSesionTextoPlano`) para demostrar la diferencia con
///     evidencia y no solo con teoría.
abstract interface class AlmacenSeguro {
  /// Escribe [valor] bajo la [clave] indicada.
  ///
  /// Si la clave ya existía, el valor se reemplaza. Lanza `FalloSeguridad`
  /// si el almacén del sistema no está disponible.
  Future<void> escribir(String clave, String valor);

  /// Devuelve el valor guardado, o `null` si la clave no existe.
  Future<String?> leer(String clave);

  /// `true` si la clave existe en el almacén.
  Future<bool> contiene(String clave);

  /// Elimina una clave. No falla si la clave no existía.
  Future<void> eliminar(String clave);

  /// Claves presentes en el almacén (sin sus valores).
  ///
  /// Es lo que la pantalla de diagnóstico muestra: los **nombres** de las
  /// claves son metadatos útiles; los valores cifrados no aportan nada y no
  /// deben volcarse a la interfaz.
  Future<Set<String>> claves();

  /// Elimina todas las claves del almacén.
  ///
  /// Debe usarse **solo** en el cierre de sesión del propio almacén o en
  /// pruebas: en una aplicación real con varios datos sensibles, borrar todo
  /// el almacén puede destruir información que no corresponde a la sesión.
  Future<void> limpiar();

  /// Descripción legible del mecanismo de protección que hay debajo
  /// (`Keystore`, `Keychain`, `libsecret`…). La usa la pantalla de
  /// diagnóstico para que el estudiante **vea** qué respalda al plugin en
  /// cada plataforma.
  String get mecanismo;
}
