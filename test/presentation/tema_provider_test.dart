import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manos_seguras/presentation/providers/dependencias_providers.dart';
import 'package:manos_seguras/presentation/providers/resultado_operacion.dart';
import 'package:manos_seguras/presentation/providers/tema_provider.dart';

import '../dobles/preferencias_en_memoria.dart';

/// **Pruebas del provider de tema** (Semana 12).
///
/// Reemplazan a `tema_app_test.dart` de la Semana 10, que instanciaba
/// `TemaApp(prefs)` a mano. Aquí hay tres cambios que vale la pena mirar:
///
///  1. **Ya no hay `getIt`.** El repositorio se sustituye con
///     `preferenciasRepositoryProvider.overrideWithValue(prefs)`, la técnica
///     de *override* de providers. Es la razón por la que la documentación
///     oficial afirma: *"All providers can be mocked by default, without any
///     additional setup"*.
///  2. **El contenedor se crea con `ProviderContainer.test()`**, que lo
///     destruye solo al terminar la prueba. La documentación oficial es
///     explícita: *"Inside tests, do not use ProviderContainer directly. Use
///     ProviderContainer.test instead."*
///  3. **Se prueba el notifier, no el widget.** Sin `pumpWidget`, sin
///     `WidgetTester`: la lógica de estado dejó de estar atada a la interfaz.
void main() {
  /// Contenedor de prueba con el almacén de preferencias sustituido.
  ProviderContainer contenedorCon(PreferenciasEnMemoria prefs) {
    return ProviderContainer.test(
      overrides: [
        preferenciasRepositoryProvider.overrideWithValue(prefs),
      ],
    );
  }

  group('temaProvider', () {
    test('sin preferencia guardada arranca en ThemeMode.system', () async {
      final PreferenciasEnMemoria prefs = PreferenciasEnMemoria();
      final ProviderContainer contenedor = contenedorCon(prefs);

      expect(contenedor.read(temaProvider), ThemeMode.system);

      await contenedor.read(temaProvider.notifier).cargarDesdeDisco();

      expect(contenedor.read(temaProvider), ThemeMode.system);
      expect(prefs.escrituras, 0);
    });

    test('cargarDesdeDisco restaura el modo guardado', () async {
      final PreferenciasEnMemoria prefs = PreferenciasEnMemoria(
        iniciales: <String, String>{Tema.clave: 'oscuro'},
      );
      final ProviderContainer contenedor = contenedorCon(prefs);

      await contenedor.read(temaProvider.notifier).cargarDesdeDisco();

      expect(contenedor.read(temaProvider), ThemeMode.dark);
    });

    test('cambiarYGuardar persiste y notifica a los escuchas', () async {
      final PreferenciasEnMemoria prefs = PreferenciasEnMemoria();
      final ProviderContainer contenedor = contenedorCon(prefs);

      // `listen` es la versión «de contenedor» de `ref.watch`: registra las
      // notificaciones sin reconstruir ningún widget.
      final List<ThemeMode> observados = <ThemeMode>[];
      contenedor.listen<ThemeMode>(
        temaProvider,
        (ThemeMode? anterior, ThemeMode nuevo) => observados.add(nuevo),
      );

      await contenedor.read(temaProvider.notifier).cambiarYGuardar(
            ThemeMode.light,
          );

      expect(contenedor.read(temaProvider), ThemeMode.light);
      expect(observados, <ThemeMode>[ThemeMode.light]);
      expect(await prefs.leer(Tema.clave), 'claro');
    });

    test('una preferencia desconocida no rompe: degrada a system', () async {
      final PreferenciasEnMemoria prefs = PreferenciasEnMemoria(
        iniciales: <String, String>{Tema.clave: 'modo-inventado'},
      );
      final ProviderContainer contenedor = contenedorCon(prefs);

      await contenedor.read(temaProvider.notifier).cargarDesdeDisco();

      expect(contenedor.read(temaProvider), ThemeMode.system);
    });

    test(
        'si el almacén falla al escribir, devuelve OperacionFallida y mantiene el modo en memoria',
        () async {
      final PreferenciasEnMemoria prefs = PreferenciasEnMemoria()
        ..fallaAlGuardar = true;
      final ProviderContainer contenedor = contenedorCon(prefs);

      final ResultadoOperacion res =
          await contenedor.read(temaProvider.notifier).cambiarYGuardar(
                ThemeMode.dark,
              );

      // Reto 1b: la preferencia no se pudo guardar en disco, pero la sesión actual
      // sí cambió y se informa el fallo mediante ResultadoOperacion.
      expect(res, isA<OperacionFallida>());
      expect(contenedor.read(temaProvider), ThemeMode.dark);
    });

    test('si la lectura falla, huboFalloLectura es true y degrada a system',
        () async {
      final PreferenciasEnMemoria prefs = PreferenciasEnMemoria()
        ..fallaAlLeer = true;
      final ProviderContainer contenedor = contenedorCon(prefs);
      final Tema notifier = contenedor.read(temaProvider.notifier);

      expect(notifier.huboFalloLectura, isFalse);
      await notifier.cargarDesdeDisco();

      // Reto 1c: se expone el estado de fallo para diagnóstico sin interrumpir
      // el arranque de la app, degradando a ThemeMode.system.
      expect(notifier.huboFalloLectura, isTrue);
      expect(contenedor.read(temaProvider), ThemeMode.system);
    });

    test('alternar() pasa de claro a oscuro y vuelve', () async {
      final PreferenciasEnMemoria prefs = PreferenciasEnMemoria();
      final ProviderContainer contenedor = contenedorCon(prefs);
      final Tema notifier = contenedor.read(temaProvider.notifier);

      await notifier.alternar();
      expect(contenedor.read(temaProvider), ThemeMode.dark);

      await notifier.alternar();
      expect(contenedor.read(temaProvider), ThemeMode.light);
    });

    test('es keepAlive: el estado sobrevive a la pérdida de escuchas',
        () async {
      final PreferenciasEnMemoria prefs = PreferenciasEnMemoria();
      final ProviderContainer contenedor = contenedorCon(prefs);

      // Se registra un oyente y se cancela: un provider autoDispose
      // destruiría su estado en el siguiente fotograma.
      final ProviderSubscription<ThemeMode> sub =
          contenedor.listen<ThemeMode>(temaProvider, (_, _) {});
      await contenedor.read(temaProvider.notifier).cambiarYGuardar(
            ThemeMode.dark,
          );
      sub.close();
      await Future<void>.delayed(Duration.zero);

      expect(contenedor.read(temaProvider), ThemeMode.dark);
    });
  });

  group('dependencias_providers (Reto 1)', () {
    test('providers del grafo tienen sus nombres declarados correctamente', () {
      expect(auditoriaRepositoryProvider.name, 'auditoriaRepository');
      expect(indicadorRepositoryProvider.name, 'indicadorRepository');
      expect(preferenciasRepositoryProvider.name, 'preferenciasRepository');
      expect(sesionRepositoryProvider.name, 'sesionRepository');
      expect(almacenSeguroProvider.name, 'almacenSeguro');
      expect(generadorTokenProvider.name, 'generadorToken');
      expect(directorioUsuariosProvider.name, 'directorioUsuarios');
      expect(preferenciasDaoProvider.name, 'preferenciasDao');
      expect(manosSegurasDbProvider.name, 'manosSegurasDb');
      expect(sembradorDatosProvider.name, 'sembradorDatos');
      expect(auditoriasDaoProvider.name, 'auditoriasDao');
      expect(indicadoresDaoProvider.name, 'indicadoresDao');
    });
  });
}
