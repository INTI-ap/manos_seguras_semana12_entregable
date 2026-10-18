import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/id.dart';
import '../../domain/entidades/auditoria.dart';
import '../../domain/entidades/catalogos.dart';
import '../../domain/entidades/establecimiento.dart';
import '../../domain/entidades/oportunidad_registro.dart';
import '../../domain/entidades/personal.dart';
import 'dependencias_providers.dart';
import 'resultado_operacion.dart';

part 'captura_provider.g.dart';

/// Borrador compartido. La lista se copia para que nadie pueda modificar
/// un estado ya publicado, ni siquiera conservando la lista del constructor.
@immutable
class EstadoCaptura {
  EstadoCaptura({
    List<OportunidadRegistro> oportunidades = const [],
    this.accionSeleccionada = Accion.friccionDeManos,
    this.siguienteNumero = 1,
    this.guardando = false,
    this.cargandoPreferencia = true,
    this.ultimoEstablecimiento,
  }) : oportunidades = List.unmodifiable(oportunidades);

  /// El estado inicial es const; los estados con listas externas las copian.
  const EstadoCaptura.inicial()
    : oportunidades = const [],
      accionSeleccionada = Accion.friccionDeManos,
      siguienteNumero = 1,
      guardando = false,
      cargandoPreferencia = true,
      ultimoEstablecimiento = null;

  final List<OportunidadRegistro> oportunidades;
  final Accion accionSeleccionada;
  final int siguienteNumero;
  final bool guardando;
  final bool cargandoPreferencia;
  final String? ultimoEstablecimiento;

  int get cumplidas => oportunidades.where((o) => o.cumplio).length;
  int get porcentaje => oportunidades.isEmpty
      ? 0
      : ((cumplidas / oportunidades.length) * 100).round();
  bool get hayDatos => oportunidades.isNotEmpty;

  EstadoCaptura copyWith({
    List<OportunidadRegistro>? oportunidades,
    Accion? accionSeleccionada,
    int? siguienteNumero,
    bool? guardando,
    bool? cargandoPreferencia,
    String? ultimoEstablecimiento,
  }) => EstadoCaptura(
    oportunidades: oportunidades ?? this.oportunidades,
    accionSeleccionada: accionSeleccionada ?? this.accionSeleccionada,
    siguienteNumero: siguienteNumero ?? this.siguienteNumero,
    guardando: guardando ?? this.guardando,
    cargandoPreferencia: cargandoPreferencia ?? this.cargandoPreferencia,
    ultimoEstablecimiento: ultimoEstablecimiento ?? this.ultimoEstablecimiento,
  );

  // Compara contenido, aunque dos lecturas creen instancias distintas.
  static Object _valor(OportunidadRegistro o) =>
      (o.id, o.auditoriaId, o.numero, o.momento, o.accion, o.observacion);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstadoCaptura &&
          listEquals(
            oportunidades.map(_valor).toList(),
            other.oportunidades.map(_valor).toList(),
          ) &&
          accionSeleccionada == other.accionSeleccionada &&
          siguienteNumero == other.siguienteNumero &&
          guardando == other.guardando &&
          cargandoPreferencia == other.cargandoPreferencia &&
          ultimoEstablecimiento == other.ultimoEstablecimiento;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(oportunidades.map(_valor)),
    accionSeleccionada,
    siguienteNumero,
    guardando,
    cargandoPreferencia,
    ultimoEstablecimiento,
  );

  @override
  String toString() =>
      'EstadoCaptura(${oportunidades.length} oportunidades, '
      'siguiente O-$siguienteNumero, guardando: $guardando)';
}

/// Conserva el borrador al navegar, no al cerrar el proceso de la aplicación.
/// Se libera explícitamente al guardar con éxito o al confirmar el descarte.
@Riverpod(keepAlive: true)
class Captura extends _$Captura {
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
