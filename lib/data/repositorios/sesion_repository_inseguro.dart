import '../../domain/entidades/sesion.dart';
import '../../domain/repositorios/sesion_repository.dart';
import '../local/daos/preferencias_dao.dart';

/// **ANTIPATRÓN DELIBERADO — solo para el laboratorio de la Semana 11.**
///
/// Este repositorio guarda la sesión completa (token incluido) en la tabla
/// `preferencias` de SQLite, es decir, **en texto plano** dentro del archivo
/// `manos_seguras.sqlite`.
///
/// No es un descuido: es el punto de partida del Reto 5 y el objeto de la
/// demostración forense de la guía. Existe para que el estudiante compruebe
/// con sus propios ojos que:
///
/// ```sql
/// sqlite> SELECT clave, valor FROM preferencias;
/// sesion.activa.texto_plano|{"v":1,"documento":"40123456","token":{...}}
/// ```
///
/// cualquiera con acceso al sistema de archivos de la aplicación —un
/// dispositivo con root, un emulador, una copia de seguridad en la nube o un
/// `adb backup`— lee el token y suplanta al usuario.
///
/// Corresponde a las debilidades **MASWE-0001** (*Sensitive Data Stored
/// Unencrypted in Private Storage*) y **MASWE-0002** (*Sensitive Data Stored
/// Unencrypted Outside of Private Storage*) del catálogo OWASP MAS, y viola
/// el control **MASVS-STORAGE-1**: *"The app securely stores sensitive
/// data"*.
///
/// **Regla de la guía:** al terminar la Semana 11 este archivo debe quedar
/// fuera de la ruta de ejecución (no registrado en `presentation/di.dart`).
/// Se conserva en el repositorio únicamente como evidencia del "antes" del
/// informe técnico.
class SesionRepositoryInseguro implements SesionRepository {
  SesionRepositoryInseguro(this._preferencias);

  /// Clave distinta de la que usa [SesionRepositorySeguro] para que ambas
  /// implementaciones puedan coexistir durante la demostración comparativa.
  static const String claveSesion = 'sesion.activa.texto_plano';

  final PreferenciasDao _preferencias;

  @override
  Future<void> guardar(Sesion sesion) {
    return _preferencias.guardar(claveSesion, sesion.serializar());
  }

  @override
  Future<Sesion?> leer() async {
    final String? crudo = await _preferencias.leer(claveSesion);
    if (crudo == null || crudo.isEmpty) return null;
    // Un dato corrupto en texto plano no se puede distinguir de un dato
    // manipulado: aquí no hay autenticación de integridad que lo delate.
    return Sesion.desdeAlmacen(crudo);
  }

  @override
  Future<bool> haySesionActiva() async {
    final Sesion? sesion = await leer();
    return sesion != null && sesion.activaEn(DateTime.now());
  }

  @override
  Future<void> cerrar() => _preferencias.eliminar(claveSesion);
}
