import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:manos_seguras/core/id.dart';
import 'package:manos_seguras/domain/entidades/auditoria.dart';
import 'package:manos_seguras/domain/entidades/catalogos.dart';
import 'package:manos_seguras/domain/entidades/establecimiento.dart';
import 'package:manos_seguras/domain/entidades/oportunidad_registro.dart';
import 'package:manos_seguras/domain/entidades/personal.dart';
import 'package:manos_seguras/presentation/providers/captura_provider.dart';
import 'package:manos_seguras/presentation/providers/dependencias_providers.dart';
import 'package:manos_seguras/presentation/providers/resultado_operacion.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'captura_temporal.g.dart';

/// Copia de laboratorio: auto-dispose permite demostrar la pérdida al salir.
/// No se usa en la aplicación; sus operaciones coinciden con Captura.
@riverpod
class CapturaTemporal extends _$CapturaTemporal {
  static const String claveUltimoEstablecimiento = 'establecimiento.ultimo';
  int _versionPreferencia = 0;

  @override
  EstadoCaptura build() {
    unawaited(_recuperarUltimoEstablecimiento());
    return const EstadoCaptura.inicial();
  }

  Future<void> _recuperarUltimoEstablecimiento() async {
    final version = _versionPreferencia;
    try {
      final codigo = await ref
          .read(preferenciasRepositoryProvider)
          .leer(claveUltimoEstablecimiento);
      if (!ref.mounted || version != _versionPreferencia) return;
      state = state.copyWith(
        ultimoEstablecimiento: codigo,
        cargandoPreferencia: false,
      );
    } catch (_) {
      if (!ref.mounted || version != _versionPreferencia) return;
      state = state.copyWith(cargandoPreferencia: false);
    }
  }

  void seleccionarAccion(Accion accion) {
    if (state.guardando || accion == state.accionSeleccionada) return;
    state = state.copyWith(accionSeleccionada: accion);
  }

  void agregar() {
    if (state.guardando) return;
    state = state.copyWith(
      oportunidades: [
        ...state.oportunidades,
        OportunidadRegistro(
          auditoriaId: '',
          numero: state.siguienteNumero,
          momento: Momento
              .values[(state.siguienteNumero - 1) % Momento.values.length],
          accion: state.accionSeleccionada,
        ),
      ],
      siguienteNumero: state.siguienteNumero + 1,
    );
  }

  void quitar(int numero) {
    if (state.guardando ||
        !state.oportunidades.any((o) => o.numero == numero)) {
      return;
    }
    state = state.copyWith(
      oportunidades: state.oportunidades
          .where((o) => o.numero != numero)
          .toList(),
    );
  }

  void descartar() {
    if (state.guardando) return;
    state = state.copyWith(
      oportunidades: [],
      siguienteNumero: 1,
      accionSeleccionada: Accion.friccionDeManos,
    );
  }

  Future<ResultadoOperacion> guardar() async {
    // La guarda también protege llamadas directas, no solo el botón.
    if (state.guardando) {
      return const OperacionSinDatos('Ya se está guardando.');
    }
    if (!state.hayDatos) {
      return const OperacionSinDatos(
        'Registre al menos una oportunidad antes de guardar.',
      );
    }
    state = state.copyWith(guardando: true);
    final establecimiento = Establecimiento.ejemplo();
    final observador = Observador.ejemplo();
    final observado = Observado.ejemplo();
    final auditoria = Auditoria(
      id: generarUuidV4(),
      establecimientoId: establecimiento.codigoUnico,
      establecimientoNombre: establecimiento.nombre,
      observadorDni: observador.dni,
      observadorNombre: observador.nombresApellidos,
      observadoDni: observado.dni,
      observadoNombre: observado.nombresApellidos,
      fecha: DateTime.now(),
      estado: EstadoAuditoria.borrador,
      oportunidades: List.of(state.oportunidades),
    );
    final String id;
    try {
      id = await ref.read(auditoriaRepositoryProvider).guardar(auditoria);
    } catch (_) {
      if (ref.mounted) state = state.copyWith(guardando: false);
      return const OperacionFallida(
        'No se pudo guardar la auditoría en el dispositivo. El borrador se conserva.',
      );
    }
    if (!ref.mounted) return OperacionOk(id);

    // SQLite ya confirmó: una preferencia fallida no debe invitar a duplicar.
    _versionPreferencia++;
    state = state.copyWith(
      oportunidades: [],
      siguienteNumero: 1,
      guardando: false,
      cargandoPreferencia: false,
      ultimoEstablecimiento: establecimiento.codigoUnico,
    );
    try {
      await ref
          .read(preferenciasRepositoryProvider)
          .guardar(claveUltimoEstablecimiento, establecimiento.codigoUnico);
    } catch (_) {
      debugPrint('Auditoría guardada; no se pudo actualizar la preferencia.');
    }
    return OperacionOk(id);
  }
}
