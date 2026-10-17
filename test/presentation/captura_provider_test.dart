import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manos_seguras/domain/entidades/catalogos.dart';
import 'package:manos_seguras/domain/entidades/oportunidad_registro.dart';
import 'package:manos_seguras/presentation/providers/captura_provider.dart';
import 'package:manos_seguras/presentation/providers/dependencias_providers.dart';
import 'package:manos_seguras/presentation/providers/resultado_operacion.dart';

import '../dobles/preferencias_en_memoria.dart';
import '../dobles/repositorio_auditorias_en_memoria.dart';

/// **Pruebas del `Notifier` de la captura** (Semana 12).
///
/// Son las pruebas que en la Semana 10 no existían porque el estado vivía
/// dentro de un `State`: para probar `_agregar()` había que montar la pantalla
/// completa con `pumpWidget`. Ahora el estado es un objeto y el notifier se
/// prueba **sin árbol de widgets**.
///
/// Fíjese en que **no se toca `getIt`**: los dos repositorios se sustituyen
/// con `overrideWithValue`, que es la forma idiomática en Riverpod y la que
/// evita el estado global compartido entre pruebas.
void main() {
  late RepositorioAuditoriasEnMemoria auditorias;
  late PreferenciasEnMemoria preferencias;

  setUp(() {
    auditorias = RepositorioAuditoriasEnMemoria();
    preferencias = PreferenciasEnMemoria();
  });

  ProviderContainer contenedor() {
    return ProviderContainer.test(
      overrides: [
        auditoriaRepositoryProvider.overrideWithValue(auditorias),
        preferenciasRepositoryProvider.overrideWithValue(preferencias),
      ],
    );
  }

  group('EstadoCaptura (valor inmutable)', () {
    test('dos estados iguales son == y comparten hashCode', () {
      final OportunidadRegistro o = OportunidadRegistro(
        auditoriaId: '',
        numero: 1,
        momento: Momento.antesDeTocarPaciente,
        accion: Accion.lavadoDeManos,
      );
      final EstadoCaptura a = EstadoCaptura(
        oportunidades: <OportunidadRegistro>[o],
        ultimoEstablecimiento: '00006405',
      );
      final EstadoCaptura b = EstadoCaptura(
        oportunidades: <OportunidadRegistro>[o],
        ultimoEstablecimiento: '00006405',
      );

      // Riverpod 3 filtra las notificaciones con ==. Si esta prueba fallara,
      // la interfaz se reconstruiría en cada `state = ...` aunque nada cambie.
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('un estado distinto NO es igual', () {
      final EstadoCaptura a = EstadoCaptura(siguienteNumero: 1);
      final EstadoCaptura b = EstadoCaptura(siguienteNumero: 2);
      expect(a, isNot(equals(b)));
    });

    test('calcula cumplidas y porcentaje', () {
      final EstadoCaptura estado = EstadoCaptura(
        oportunidades: <OportunidadRegistro>[
          OportunidadRegistro(
            auditoriaId: '',
            numero: 1,
            momento: Momento.antesDeTocarPaciente,
            accion: Accion.lavadoDeManos,
          ),
          OportunidadRegistro(
            auditoriaId: '',
            numero: 2,
            momento: Momento.antesDeTocarPaciente,
            accion: Accion.omision,
          ),
        ],
      );

      expect(estado.cumplidas, 1);
      expect(estado.porcentaje, 50);
    });

    test('sin oportunidades el porcentaje es 0 y no hay datos', () {
      final EstadoCaptura estado = EstadoCaptura();
      expect(estado.porcentaje, 0);
      expect(estado.hayDatos, isFalse);
    });
  });

  group('Captura (Notifier)', () {
    test('agregar() añade la oportunidad con el número correlativo', () async {
      final ProviderContainer c = contenedor();
      final Captura notifier = c.read(capturaProvider.notifier);

      notifier.agregar();
      notifier.agregar();

      final EstadoCaptura estado = c.read(capturaProvider);
      expect(estado.oportunidades, hasLength(2));
      expect(estado.siguienteNumero, 3);
      expect(estado.oportunidades.first.numero, 1);
      expect(estado.oportunidades.last.numero, 2);
    });

    test(
      'seleccionarAccion() cambia la acción de la próxima oportunidad',
      () async {
        final ProviderContainer c = contenedor();
        final Captura notifier = c.read(capturaProvider.notifier);

        notifier.seleccionarAccion(Accion.omision);
        notifier.agregar();

        expect(
          c.read(capturaProvider).oportunidades.single.accion,
          Accion.omision,
        );
      },
    );

    test('quitar() elimina por número sin renumerar el resto', () {
      final ProviderContainer c = contenedor();
      final Captura notifier = c.read(capturaProvider.notifier);

      notifier.agregar();
      notifier.agregar();
      notifier.agregar();
      notifier.quitar(2);

      final List<int> numeros = c
          .read(capturaProvider)
          .oportunidades
          .map((OportunidadRegistro o) => o.numero)
          .toList();
      expect(numeros, <int>[1, 3]);
    });

    test(
      'build() recupera el último establecimiento de las preferencias',
      () async {
        preferencias = PreferenciasEnMemoria(
          iniciales: <String, String>{
            Captura.claveUltimoEstablecimiento: '00006405',
          },
        );
        final ProviderContainer c = contenedor();

        // La lectura es asíncrona y arranca dentro de build(): hay que dejar
        // correr el microtask antes de comprobar.
        c.read(capturaProvider);
        await Future<void>.delayed(Duration.zero);

        final EstadoCaptura estado = c.read(capturaProvider);
        expect(estado.ultimoEstablecimiento, '00006405');
        expect(estado.cargandoPreferencia, isFalse);
      },
    );

    test('guardar() sin oportunidades no llama al repositorio', () async {
      final ProviderContainer c = contenedor();

      final ResultadoOperacion resultado = await c
          .read(capturaProvider.notifier)
          .guardar();

      expect(resultado, isA<OperacionSinDatos>());
      expect(auditorias.llamadasAGuardar, 0);
    });

    test('guardar() persiste la auditoría y vacía el borrador', () async {
      final ProviderContainer c = contenedor();
      final Captura notifier = c.read(capturaProvider.notifier);

      notifier.agregar();
      final ResultadoOperacion resultado = await notifier.guardar();

      expect(resultado, isA<OperacionOk>());
      expect(auditorias.llamadasAGuardar, 1);
      expect(await auditorias.listarAuditorias(), hasLength(1));

      final EstadoCaptura estado = c.read(capturaProvider);
      expect(estado.oportunidades, isEmpty);
      expect(estado.siguienteNumero, 1);
      expect(estado.guardando, isFalse);
      // El último establecimiento se guardó como preferencia…
      expect(
        await preferencias.leer(Captura.claveUltimoEstablecimiento),
        isNotEmpty,
      );
      // …y quedó en el estado, sin volver a leer el disco.
      expect(estado.ultimoEstablecimiento, isNotEmpty);
    });

    test('guardar() informa el fallo y conserva el borrador', () async {
      final ProviderContainer c = contenedor();
      final Captura notifier = c.read(capturaProvider.notifier);
      notifier.agregar();
      auditorias.falla = true;

      final ResultadoOperacion resultado = await notifier.guardar();

      expect(resultado, isA<OperacionFallida>());
      final EstadoCaptura estado = c.read(capturaProvider);
      // El borrador NO se pierde si el guardado falla: el usuario puede
      // reintentar. Es una decisión de diseño, no un accidente.
      expect(estado.oportunidades, hasLength(1));
      expect(estado.guardando, isFalse);
    });

    test('descartar() vuelve al estado inicial', () {
      final ProviderContainer c = contenedor();
      final Captura notifier = c.read(capturaProvider.notifier);
      notifier.agregar();
      notifier.agregar();

      notifier.descartar();

      final EstadoCaptura estado = c.read(capturaProvider);
      expect(estado.oportunidades, isEmpty);
      expect(estado.siguienteNumero, 1);
    });

    test('es keepAlive: sin oyentes el borrador sigue ahí', () async {
      final ProviderContainer c = contenedor();
      final ProviderSubscription<EstadoCaptura> sub = c.listen<EstadoCaptura>(
        capturaProvider,
        (_, _) {},
      );
      c.read(capturaProvider.notifier).agregar();
      sub.close();
      await Future<void>.delayed(Duration.zero);

      // Si el provider fuera autoDispose (el valor por defecto de @riverpod),
      // el borrador se habría destruido al cerrar la suscripción.
      expect(c.read(capturaProvider).oportunidades, hasLength(1));
    });
  });
}
