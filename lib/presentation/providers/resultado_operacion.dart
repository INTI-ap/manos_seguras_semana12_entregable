/// **Resultado de una operación que la interfaz debe narrar** (Semana 12).
///
/// Antes de la Semana 12, `PantallaOportunidades` y `PantallaSesion` hacían
/// dos cosas a la vez dentro del widget:
///
///  1. llamaban al caso de uso (`guardar`, `iniciarSesion`, …);
///  2. decidían **cómo contarlo** (`ScaffoldMessenger`, `setState`, …).
///
/// Al mover la lógica a un `Notifier`, el notifier **no puede** tocar el
/// `BuildContext` (no lo tiene, y no debe tenerlo). La solución es que el
/// notifier devuelva este objeto pequeño y que el widget decida el mensaje.
///
/// Es un `sealed class`: el compilador obliga a que todo `switch` cubra los
/// tres casos. Ese es el motivo por el que el proyecto lo prefiere a un
/// `String?` con `null` significando "todo bien".
sealed class ResultadoOperacion {
  const ResultadoOperacion();
}

/// La operación terminó bien. [detalle] es opcional y nunca contiene datos
/// sensibles (ni tokens, ni claves).
final class OperacionOk extends ResultadoOperacion {
  const OperacionOk([this.detalle]);

  final String? detalle;
}

/// La operación no se pudo completar por una regla de negocio o por el
/// entorno (disco, almacén seguro, validación). [mensaje] está listo para
/// mostrarse al usuario.
final class OperacionFallida extends ResultadoOperacion {
  const OperacionFallida(this.mensaje);

  final String mensaje;
}

/// La operación era posible pero no había nada que hacer (por ejemplo,
/// guardar una auditoría sin oportunidades registradas).
final class OperacionSinDatos extends ResultadoOperacion {
  const OperacionSinDatos(this.mensaje);

  final String mensaje;
}
