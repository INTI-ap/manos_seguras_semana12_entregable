import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/fallos.dart';
import 'almacen_seguro.dart';

/// **Adaptador de `flutter_secure_storage`** (Semana 11 — temática 2.2.4).
///
/// Es el **único** archivo del proyecto que importa el plugin. Si el día de
/// mañana se cambia de plugin o se añade una implementación propia, se
/// reemplaza este archivo y nada más.
///
/// ## Dónde acaba realmente el dato en cada plataforma
///
/// El plugin no inventa un cifrado propio: delega en el almacén de
/// credenciales del sistema operativo. Esta tabla es la que el estudiante
/// debe reproducir en el informe (ver README del plugin, 2026):
///
/// | Plataforma | Respaldo del secreto |
/// |---|---|
/// | Android | Android Keystore + cifrado AES-GCM con envoltura RSA-OAEP |
/// | iOS / macOS | Keychain (atributo `kSecAttrAccessible`) |
/// | Linux | libsecret (GNOME Keyring / KWallet) |
/// | Windows | Almacén cifrado del propio plugin |
/// | Web | WebCrypto sobre `localStorage` (solo HTTPS o localhost) |
///
/// ## Las decisiones de endurecimiento que aplica esta clase
///
///  1. **`resetOnError: false`.** El valor por omisión del plugin (v10+) es
///     `true`: ante un error de descifrado, borra el almacén completo. Para
///     una sesión eso equivale a "cerrar sesión sin avisar", que es
///     aceptable; para un almacén que además guardara otros secretos, sería
///     una pérdida silenciosa de datos. Se desactiva y se prefiere el error
///     explícito ([FalloSeguridad]) que la pérdida silenciosa.
///  2. **`preferencesKeyPrefix` y `storageNamespace`.** Aíslan las claves
///     de ManosSeguras de las de cualquier otra librería del dispositivo.
///  3. **`KeychainAccessibility.first_unlock_this_device`.** El token queda
///     accesible tras el primer desbloqueo del arranque (necesario para que
///     una sincronización en segundo plano funcione) pero **no** se
///     sincroniza con iCloud ni se restaura en otro dispositivo. Un token de
///     sesión no debe viajar entre dispositivos.
///  4. **`synchronizable: false`.** Refuerza lo anterior: nada de iCloud
///     Keychain.
class AlmacenSeguroSistema implements AlmacenSeguro {
  /// [almacen] se puede inyectar para las pruebas de integración; en
  /// producción se usa la instancia configurada de [opcionesEndurecidas].
  AlmacenSeguroSistema({FlutterSecureStorage? almacen})
      : _almacen = almacen ?? opcionesEndurecidas;

  /// Prefijo de las claves dentro de las preferencias de Android.
  static const String prefijoPreferencias = 'manos_seguras';

  /// Espacio de nombres que aísla por completo esta instancia del plugin.
  static const String espacioNombres = 'manos_seguras_sesion';

  /// Nombre del servicio en el Keychain de Apple (`kSecAttrService`).
  static const String servicioKeychain = 'pe.edu.uandina.manosseguras';

  /// Configuración endurecida, compartida por toda la aplicación.
  ///
  /// Es `const` porque el plugin lo exige: la instancia no guarda estado.
  static const FlutterSecureStorage opcionesEndurecidas = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // No borrar datos ante un error de descifrado: preferimos informarlo.
      resetOnError: false,
      preferencesKeyPrefix: prefijoPreferencias,
      storageNamespace: espacioNombres,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: servicioKeychain,
      synchronizable: false,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: servicioKeychain,
      synchronizable: false,
    ),
  );

  final FlutterSecureStorage _almacen;

  @override
  Future<void> escribir(String clave, String valor) {
    return _proteger(
      'No se pudo guardar el dato seguro "$clave".',
      () => _almacen.write(key: clave, value: valor),
    );
  }

  @override
  Future<String?> leer(String clave) {
    return _proteger(
      'No se pudo leer el dato seguro "$clave".',
      () => _almacen.read(key: clave),
    );
  }

  @override
  Future<bool> contiene(String clave) {
    return _proteger(
      'No se pudo comprobar el dato seguro "$clave".',
      () => _almacen.containsKey(key: clave),
    );
  }

  @override
  Future<void> eliminar(String clave) {
    return _proteger(
      'No se pudo eliminar el dato seguro "$clave".',
      () => _almacen.delete(key: clave),
    );
  }

  @override
  Future<Set<String>> claves() async {
    final Map<String, String> todo = await _proteger(
      'No se pudieron enumerar las claves del almacén seguro.',
      _almacen.readAll,
    );
    return todo.keys.toSet();
  }

  @override
  Future<void> limpiar() {
    return _proteger(
      'No se pudo vaciar el almacén seguro.',
      _almacen.deleteAll,
    );
  }

  @override
  String get mecanismo {
    if (kIsWeb) {
      return 'WebCrypto sobre localStorage (exige HTTPS o localhost)';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android Keystore + AES-GCM (clave envuelta con RSA-OAEP)';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 'Apple Keychain (kSecAttrAccessible: first_unlock_this_device)';
      case TargetPlatform.linux:
        return 'libsecret / Secret Service (GNOME Keyring o KWallet)';
      case TargetPlatform.windows:
        return 'Almacén cifrado del plugin (archivos protegidos por DPAPI)';
      case TargetPlatform.fuchsia:
        return 'Plataforma no soportada por el plugin';
    }
  }

  /// Traduce cualquier excepción del plugin a [FalloSeguridad].
  ///
  /// El dominio nunca debe ver un `PlatformException`: el mismo error
  /// técnico significa cosas distintas en cada plataforma y la capa de
  /// presentación necesita un mensaje único y accionable.
  Future<T> _proteger<T>(String mensaje, Future<T> Function() operacion) async {
    try {
      return await operacion();
    } on PlatformException catch (error) {
      throw FalloSeguridad(
        '$mensaje (${error.code}: ${error.message ?? 'sin detalle'})',
        causa: error,
      );
    } on MissingPluginException catch (error) {
      // Ocurre al ejecutar en una plataforma sin implementación registrada
      // (por ejemplo, pruebas de widget sin `FlutterSecureStorage` falso).
      throw FalloSeguridad(
        '$mensaje El almacén seguro no está disponible en esta plataforma.',
        causa: error,
      );
    }
  }
}
