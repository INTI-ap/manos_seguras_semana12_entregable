import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manos_seguras/data/repositorios/sesion_repository_seguro.dart';
import 'package:manos_seguras/data/seguro/almacen_seguro_en_memoria.dart';
import 'package:manos_seguras/domain/entidades/sesion.dart';
import 'package:manos_seguras/domain/repositorios/sesion_repository.dart';
import 'package:manos_seguras/domain/servicios/generador_token.dart';
import 'package:manos_seguras/presentation/providers/dependencias_providers.dart';
import 'package:manos_seguras/presentation/providers/resultado_operacion.dart';
import 'package:manos_seguras/presentation/providers/sesion_provider.dart';

/// **Pruebas del `Notifier` de sesión** (Semana 12).
///
/// En la Semana 11 este comportamiento se probaba montando la pantalla
/// (`pantalla_sesion_test.dart`) porque `GestorSesion` era un
/// `ValueNotifier` que solo existía dentro del árbol. Aquí se prueba **el
/// estado**, sin `pumpWidget` y **sin `getIt`**: las tres dependencias se
/// sustituyen con `overrideWithValue`.
///
/// La prueba de widget de `pantalla_sesion_test.dart` se conserva, pero ahora
/// verifica la **interfaz** (que el token no se muestre), no el ciclo de vida.
void main() {
  late AlmacenSeguroEnMemoria almacen;
  late SesionRepository repositorio;

  setUp(() {
    almacen = AlmacenSeguroEnMemoria();
    repositorio = SesionRepositorySeguro(almacen);
  });

  ProviderContainer contenedor() {
    return ProviderContainer.test(
      overrides: [
        sesionRepositoryProvider.overrideWithValue(repositorio),
        generadorTokenProvider.overrideWithValue(GeneradorTokenSimulado()),
        directorioUsuariosProvider.overrideWithValue(
          DirectorioUsuariosSimulado(),
        ),
      ],
    );
  }

  group('SesionCtrl', () {
    test('arranca sin sesión y sin operación en curso', () {
      final ProviderContainer c = contenedor();
      final EstadoSesion estado = c.read(sesionCtrlProvider);

      expect(estado.sesion, isNull);
      expect(estado.haySesion, isFalse);
      expect(estado.procesando, isFalse);
      expect(estado.ultimoFallo, isNull);
    });

    test('iniciar() con credenciales correctas emite y guarda el token',
        () async {
      final ProviderContainer c = contenedor();

      final ResultadoOperacion resultado =
          await c.read(sesionCtrlProvider.notifier).iniciar(
                documento: '40123456',
                clave: 'higiene2026',
              );

      expect(resultado, isA<OperacionOk>());
      final EstadoSesion estado = c.read(sesionCtrlProvider);
      expect(estado.sesion, isNotNull);
      expect(estado.sesion!.nombre, 'Rosa Quispe Huamán');
      expect(estado.procesando, isFalse);
      // El token quedó en el almacén seguro, no en memoria suelta.
      expect(
        await almacen.claves(),
        contains(SesionRepositorySeguro.claveSesion),
      );
      expect(await repositorio.leer(), isNotNull);
    });

    test('iniciar() con credenciales incorrectas no crea sesión', () async {
      final ProviderContainer c = contenedor();

      final ResultadoOperacion resultado =
          await c.read(sesionCtrlProvider.notifier).iniciar(
                documento: '40123456',
                clave: 'clave-equivocada',
              );

      expect(resultado, isA<OperacionFallida>());
      final EstadoSesion estado = c.read(sesionCtrlProvider);
      expect(estado.sesion, isNull);
      expect(estado.ultimoFallo, 'Documento o clave incorrectos.');
      expect(await almacen.claves(), isEmpty);
    });

    test('el valor del token nunca vive en el estado de forma legible',
        () async {
      final ProviderContainer c = contenedor();
      await c.read(sesionCtrlProvider.notifier).iniciar(
            documento: '40123456',
            clave: 'higiene2026',
          );

      final EstadoSesion estado = c.read(sesionCtrlProvider);
      final Sesion sesion = estado.sesion!;

      // El estado SÍ contiene la sesión (la necesita para saber el rol), pero
      // la descripción que se publica hacia la interfaz solo lleva la huella.
      final String? descripcion = c.read(sesionCtrlProvider.notifier)
          .descripcionToken;
      expect(descripcion, isNotNull);
      expect(descripcion, contains(sesion.token.huella));
      expect(descripcion, isNot(contains(sesion.token.valor)));
      // `toString()` también está escrito a mano para no volcar el token.
      expect(estado.toString(), isNot(contains(sesion.token.valor)));
    });

    test('cerrar() borra el almacén y el estado', () async {
      final ProviderContainer c = contenedor();
      final SesionCtrl notifier = c.read(sesionCtrlProvider.notifier);
      await notifier.iniciar(documento: '40123456', clave: 'higiene2026');

      final ResultadoOperacion resultado = await notifier.cerrar();

      expect(resultado, isA<OperacionOk>());
      expect(c.read(sesionCtrlProvider).sesion, isNull);
      expect(await almacen.claves(), isEmpty);
    });

    test('restaurar() recupera una sesión guardada y vigente', () async {
      // Primera "ejecución": se inicia sesión y se guarda el token.
      final ProviderContainer primera = contenedor();
      await primera.read(sesionCtrlProvider.notifier).iniciar(
            documento: '40123456',
            clave: 'higiene2026',
          );

      // Segunda "ejecución": contenedor nuevo sobre el MISMO almacén seguro.
      final ProviderContainer segunda = contenedor();
      await segunda.read(sesionCtrlProvider.notifier).restaurar();

      expect(segunda.read(sesionCtrlProvider).sesion, isNotNull);
      expect(segunda.read(sesionCtrlProvider).sesion!.documento, '40123456');
    });

    test('restaurar() descarta un token vencido y limpia el almacén',
        () async {
      final ProviderContainer c = contenedor();
      // Token emitido hace mucho tiempo: la vigencia por defecto es corta.
      final Sesion vencida = Sesion(
        documento: '40123456',
        nombre: 'Rosa Quispe Huamán',
        rol: RolUsuario.observador,
        token: GeneradorTokenSimulado(
          vigencia: const Duration(minutes: 1),
        ).emitir(ahora: DateTime(2020)),
      );
      await repositorio.guardar(vencida);

      await c.read(sesionCtrlProvider.notifier).restaurar();

      expect(c.read(sesionCtrlProvider).sesion, isNull);
      expect(await repositorio.leer(), isNull);
    });

    test('iniciar() es reentrante-seguro: la segunda llamada no emite token',
        () async {
      final ProviderContainer c = contenedor();
      final SesionCtrl notifier = c.read(sesionCtrlProvider.notifier);

      // Dos pulsaciones simultáneas del botón: la primera deja `procesando`
      // en true de forma síncrona, así que la segunda se rechaza.
      final Future<ResultadoOperacion> primera =
          notifier.iniciar(documento: '40123456', clave: 'higiene2026');
      final ResultadoOperacion segunda = await notifier.iniciar(
        documento: '40123456',
        clave: 'higiene2026',
      );
      await primera;

      expect(segunda, isA<OperacionSinDatos>());
      expect(c.read(sesionCtrlProvider).sesion, isNotNull);
    });

    test('mecanismoDeProteccion describe el almacén en uso', () {
      final ProviderContainer c = contenedor();
      expect(
        c.read(sesionCtrlProvider.notifier).mecanismoDeProteccion,
        contains('Memoria del proceso'),
      );
    });
  });
}
