import 'package:manos_seguras/domain/repositorios/indicador_repository.dart';

/// **Doble de prueba del almacén de preferencias.**
///
/// Guarda los valores en un `Map` en memoria. Se usa en las pruebas de widget
/// y en la prueba de `temaProvider`, donde abrir SQLite solo agregaría ruido.
class PreferenciasEnMemoria implements PreferenciasRepository {
  PreferenciasEnMemoria({Map<String, String>? iniciales})
      : _valores = <String, String>{...?iniciales};

  final Map<String, String> _valores;

  /// Cuando es `true`, [guardar] lanza una excepción: sirve para comprobar que
  /// la preferencia de tema no bloquea la aplicación si el disco falla.
  bool fallaAlGuardar = false;

  /// Cuando es `true`, [leer] lanza una excepción para probar la robustez
  /// ante fallos de lectura de preferencias (Reto 1c).
  bool fallaAlLeer = false;

  /// Número de escrituras realizadas, para verificar que no se guarda de más.
  int escrituras = 0;

  @override
  Future<String?> leer(String clave) async {
    if (fallaAlLeer) {
      throw StateError('Fallo simulado de lectura (prueba).');
    }
    return _valores[clave];
  }

  @override
  Future<void> guardar(String clave, String valor) async {
    escrituras++;
    if (fallaAlGuardar) {
      throw StateError('Fallo simulado de escritura (prueba).');
    }
    _valores[clave] = valor;
  }

  @override
  Future<void> eliminar(String clave) async {
    _valores.remove(clave);
  }

  @override
  Future<Map<String, String>> leerTodo() async =>
      Map<String, String>.unmodifiable(_valores);
}
