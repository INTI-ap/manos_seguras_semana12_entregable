import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manos_seguras/domain/entidades/auditoria.dart';
import 'package:manos_seguras/domain/entidades/catalogos.dart';
import 'package:manos_seguras/domain/entidades/oportunidad_registro.dart';
import 'package:manos_seguras/presentation/providers/captura_provider.dart';
import 'package:manos_seguras/presentation/providers/dependencias_providers.dart';
import 'package:manos_seguras/presentation/providers/resultado_operacion.dart';
import '../dobles/preferencias_en_memoria.dart';
import '../dobles/repositorio_auditorias_en_memoria.dart';

class _AuditoriasLentas extends RepositorioAuditoriasEnMemoria {
  final completar = Completer<void>();
  @override
  Future<String> guardar(Auditoria auditoria) async {
    await completar.future;
    return super.guardar(auditoria);
  }
}

class _PreferenciasLentas extends PreferenciasEnMemoria {
  final lectura = Completer<String?>();
  @override
  Future<String?> leer(String clave) => lectura.future;
}

void main() {
  ProviderContainer crear(
    RepositorioAuditoriasEnMemoria a,
    PreferenciasEnMemoria p,
  ) => ProviderContainer.test(
    overrides: [
      auditoriaRepositoryProvider.overrideWithValue(a),
      preferenciasRepositoryProvider.overrideWithValue(p),
    ],
  );
  const oportunidad = OportunidadRegistro(
    auditoriaId: '',
    numero: 1,
    momento: Momento.antesDeTocarPaciente,
    accion: Accion.lavadoDeManos,
  );

  test('el estado copia la lista de entrada y prohíbe modificarla', () {
    final entrada = [oportunidad];
    final estado = EstadoCaptura(oportunidades: entrada);
    entrada.clear();
    expect(estado.oportunidades, hasLength(1));
    expect(() => estado.oportunidades.clear(), throwsUnsupportedError);
    final otra = [oportunidad];
    final siguiente = estado.copyWith(oportunidades: otra);
    otra.clear();
    expect(siguiente.oportunidades, hasLength(1));
  });
  test('compara oportunidades por contenido y mantiene el hash', () {
    final a = EstadoCaptura(oportunidades: [oportunidad]);
    final b = EstadoCaptura(oportunidades: [oportunidad.copyWith()]);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(
      a,
      isNot(b.copyWith(oportunidades: [oportunidad.copyWith(numero: 2)])),
    );
  });
  test('los estados anteriores no cambian al agregar o quitar', () {
    final c = crear(RepositorioAuditoriasEnMemoria(), PreferenciasEnMemoria());
    final n = c.read(capturaProvider.notifier)..agregar();
    final anterior = c.read(capturaProvider);
    n.agregar();
    n.quitar(1);
    expect(anterior.oportunidades.single.numero, 1);
    expect(c.read(capturaProvider).oportunidades.single.numero, 2);
  });
  test('quitar no reutiliza el correlativo y el momento sigue el ciclo', () {
    final c = crear(RepositorioAuditoriasEnMemoria(), PreferenciasEnMemoria());
    final n = c.read(capturaProvider.notifier)
      ..agregar()
      ..agregar();
    n.quitar(1);
    n.agregar();
    expect(c.read(capturaProvider).oportunidades.map((o) => o.numero), [2, 3]);
    expect(
      c.read(capturaProvider).oportunidades.last.momento,
      Momento.values[2],
    );
  });
  test(
    'guardar simultáneamente escribe una vez y bloquea cambios del borrador',
    () async {
      final a = _AuditoriasLentas();
      final c = crear(a, PreferenciasEnMemoria());
      final n = c.read(capturaProvider.notifier)..agregar();
      final primera = n.guardar();
      final segunda = await n.guardar();
      n.agregar();
      n.quitar(1);
      n.descartar();
      n.seleccionarAccion(Accion.omision);
      expect(segunda, isA<OperacionSinDatos>());
      expect(c.read(capturaProvider).oportunidades, hasLength(1));
      expect(c.read(capturaProvider).guardando, isTrue);
      expect(
        c.read(capturaProvider).accionSeleccionada,
        Accion.friccionDeManos,
      );
      a.completar.complete();
      expect(await primera, isA<OperacionOk>());
      expect(a.llamadasAGuardar, 1);
    },
  );
  test(
    'fallar la preferencia tras guardar no conserva un duplicado pendiente',
    () async {
      final a = RepositorioAuditoriasEnMemoria();
      final p = PreferenciasEnMemoria()..fallaAlGuardar = true;
      final c = crear(a, p);
      final n = c.read(capturaProvider.notifier)..agregar();
      expect(await n.guardar(), isA<OperacionOk>());
      expect(c.read(capturaProvider).hayDatos, isFalse);
      expect(await n.guardar(), isA<OperacionSinDatos>());
      expect(a.llamadasAGuardar, 1);
    },
  );
  test(
    'un fallo real conserva datos y permite reintentar sin perder la acción',
    () async {
      final a = RepositorioAuditoriasEnMemoria()..falla = true;
      final c = crear(a, PreferenciasEnMemoria());
      final n = c.read(capturaProvider.notifier)
        ..seleccionarAccion(Accion.omision)
        ..agregar();
      final anterior = c.read(capturaProvider);
      expect(await n.guardar(), isA<OperacionFallida>());
      expect(c.read(capturaProvider).oportunidades, anterior.oportunidades);
      expect(c.read(capturaProvider).accionSeleccionada, Accion.omision);
      a.falla = false;
      expect(await n.guardar(), isA<OperacionOk>());
      expect(await a.listarAuditorias(), hasLength(1));
    },
  );
  test(
    'una preferencia antigua tardía no pisa el establecimiento recién guardado',
    () async {
      final p = _PreferenciasLentas();
      final c = crear(RepositorioAuditoriasEnMemoria(), p);
      final n = c.read(capturaProvider.notifier)..agregar();
      await n.guardar();
      final codigo = c.read(capturaProvider).ultimoEstablecimiento;
      p.lectura.complete('antiguo');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(capturaProvider).ultimoEstablecimiento, codigo);
    },
  );
  test(
    'descartar reinicia el correlativo y la acción, conservando la preferencia',
    () async {
      final c = crear(
        RepositorioAuditoriasEnMemoria(),
        PreferenciasEnMemoria(
          iniciales: {Captura.claveUltimoEstablecimiento: 'establecimiento'},
        ),
      );
      final n = c.read(capturaProvider.notifier)
        ..seleccionarAccion(Accion.omision)
        ..agregar();
      await Future<void>.delayed(Duration.zero);
      n.descartar();
      final s = c.read(capturaProvider);
      expect(s.hayDatos, isFalse);
      expect(s.siguienteNumero, 1);
      expect(s.accionSeleccionada, Accion.friccionDeManos);
      expect(s.ultimoEstablecimiento, 'establecimiento');
    },
  );
}
