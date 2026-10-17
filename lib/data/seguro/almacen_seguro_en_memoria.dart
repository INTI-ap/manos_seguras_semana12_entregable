import 'dart:collection';

import '../../core/fallos.dart';
import 'almacen_seguro.dart';

/// **Almacén seguro en memoria** (doble de prueba).
///
/// Semana 11. Cumple el contrato [AlmacenSeguro] sin tocar el sistema
/// operativo. Tiene dos usos legítimos:
///
///  1. **Pruebas automáticas.** `flutter test` se ejecuta en una máquina de
///     escritorio o en CI, donde no hay Keystore ni Keychain. Sin este doble,
///     toda prueba que toque la sesión tendría que lanzar un emulador.
///  2. **Modo demostración.** Permite enseñar el flujo completo en el
///     laboratorio sin depender del llavero del equipo.
///
/// **Advertencia que el informe debe registrar:** este almacén guarda los
/// valores en texto plano en la RAM del proceso. Su nombre dice "en memoria",
/// no "seguro": nunca debe registrarse como implementación en producción.
class AlmacenSeguroEnMemoria implements AlmacenSeguro {
  AlmacenSeguroEnMemoria({Map<String, String>? datosIniciales})
      : _datos = <String, String>{...?datosIniciales};

  final Map<String, String> _datos;

  /// Cuántas operaciones de escritura se hicieron. Las pruebas lo usan para
  /// comprobar que no se escribió de más (por ejemplo, que reabrir la
  /// aplicación con una sesión vigente no vuelve a guardarla).
  int escriturasRealizadas = 0;

  @override
  Future<void> escribir(String clave, String valor) async {
    escriturasRealizadas++;
    _datos[clave] = valor;
  }

  @override
  Future<String?> leer(String clave) async => _datos[clave];

  @override
  Future<bool> contiene(String clave) async => _datos.containsKey(clave);

  @override
  Future<void> eliminar(String clave) async {
    _datos.remove(clave);
  }

  @override
  Future<Set<String>> claves() async => UnmodifiableSetView<String>(
        _datos.keys.toSet(),
      );

  @override
  Future<void> limpiar() async {
    _datos.clear();
  }

  @override
  String get mecanismo => 'Memoria del proceso (doble de prueba, NO usar en '
      'producción)';

  /// Volcado de los valores en claro. Existe **solo** para que las pruebas
  /// comprueben qué se escribió; por eso no forma parte de [AlmacenSeguro].
  Map<String, String> volcadoParaPruebas() =>
      UnmodifiableMapView<String, String>(_datos);

  /// Simula un fallo del almacén del sistema (llavero bloqueado, Keystore
  /// inaccesible) para probar el camino de error de la pantalla.
  static AlmacenSeguroEnMemoria queFalla(String mensaje) =>
      _AlmacenSeguroQueFalla(mensaje);
}

class _AlmacenSeguroQueFalla extends AlmacenSeguroEnMemoria {
  _AlmacenSeguroQueFalla(this._mensaje);

  final String _mensaje;

  Never _fallar() => throw FalloSeguridad(_mensaje);

  @override
  Future<void> escribir(String clave, String valor) async => _fallar();

  @override
  Future<String?> leer(String clave) async => _fallar();

  @override
  Future<bool> contiene(String clave) async => _fallar();

  @override
  Future<void> eliminar(String clave) async => _fallar();

  @override
  Future<Set<String>> claves() async => _fallar();

  @override
  Future<void> limpiar() async => _fallar();
}
