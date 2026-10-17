/// Fallos de la capa de datos traducidos al lenguaje del dominio.
///
/// **Principio de Inversión de Dependencias (DIP, Semana 9):** el dominio
/// no puede depender de `drift`, de `sqlite3` ni de `http`. Por eso las
/// implementaciones de los repositorios atrapan las excepciones técnicas
/// y las vuelven a lanzar como un [Fallo] con un mensaje comprensible en
/// español, tal como se hizo con `ApiException` en la Sesión 16.
library;

/// Clase base de todos los fallos controlados del proyecto.
sealed class Fallo implements Exception {
  const Fallo(this.mensaje, {this.causa});

  /// Mensaje listo para mostrar al usuario final.
  final String mensaje;

  /// Excepción técnica original, útil para depurar con `debugPrint`.
  final Object? causa;

  @override
  String toString() => '$runtimeType: $mensaje';
}

/// No se pudo leer o escribir en la base de datos local.
class FalloLocal extends Fallo {
  const FalloLocal(super.mensaje, {super.causa});
}

/// El servicio remoto falló (red, timeout, código HTTP distinto de 200).
class FalloRemoto extends Fallo {
  const FalloRemoto(super.mensaje, {super.causa});
}

/// Los datos recibidos no cumplen las reglas del dominio (por ejemplo,
/// una auditoría sin ninguna oportunidad registrada).
class FalloDeValidacion extends Fallo {
  const FalloDeValidacion(super.mensaje, {super.causa});
}

/// No existe el registro solicitado.
class FalloNoEncontrado extends Fallo {
  const FalloNoEncontrado(super.mensaje, {super.causa});
}

/// **Semana 11.** Falló el almacén seguro del sistema operativo: el llavero
/// está bloqueado (Linux), el Keystore rechazó la clave (Android) o el
/// usuario canceló la autenticación biométrica.
///
/// Es un fallo **distinto** de [FalloLocal]: no se arregla reintentando
/// contra SQLite, sino que exige otra acción (desbloquear el llavero, pedir
/// de nuevo la biometría o, en el peor caso, cerrar sesión y volver a
/// autenticarse).
class FalloSeguridad extends Fallo {
  const FalloSeguridad(super.mensaje, {super.causa});
}

/// Las credenciales no coinciden con ningún usuario del directorio.
///
/// El mensaje es **neutro** a propósito: distinguir "el usuario no existe"
/// de "la clave es incorrecta" permite enumerar cuentas válidas.
class FalloDeAutenticacion extends Fallo {
  const FalloDeAutenticacion([super.mensaje = 'Documento o clave incorrectos.']);
}
