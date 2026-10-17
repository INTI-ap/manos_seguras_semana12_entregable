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

/// **Estado de la captura de oportunidades** (Semana 12).
///
/// Es el mismo estado que en la Semana 10 vivía repartido en seis campos de
/// `_PantallaOportunidadesState` (`_oportunidades`, `_siguienteNumero`,
/// `_accionSeleccionada`, `_guardando`, `_ultimoEstablecimiento`,
/// `_cargandoPreferencia`) y que se actualizaba con `setState`.
///
/// ## Por qué esta clase es inmutable
///
/// Un `Notifier` no muta su estado: lo **reemplaza** (`state = nuevoEstado`).
/// Eso obliga a que el estado sea un valor inmutable y comparable. La ventaja
/// no es teórica: Riverpod 3 filtra las notificaciones con `==`
/// (*"Starting 3.0, all providers use `==` to filter notifications"*), así que
/// un estado que no implementa `==` haría que la interfaz se reconstruya
/// incluso cuando nada cambió.
///
/// Por eso esta clase implementa [==] y [hashCode], y usa [listEquals] para
/// comparar la lista de oportunidades elemento por elemento.
@immutable
class EstadoCaptura {
  const EstadoCaptura({
    this.oportunidades = const <OportunidadRegistro>[],
    this.accionSeleccionada = Accion.friccionDeManos,
    this.siguienteNumero = 1,
    this.guardando = false,
    this.cargandoPreferencia = true,
    this.ultimoEstablecimiento,
  });

  /// Oportunidades capturadas y aún no guardadas.
  final List<OportunidadRegistro> oportunidades;

  /// Acción del catálogo que se aplicará a la próxima oportunidad.
  final Accion accionSeleccionada;

  /// Número correlativo de la próxima oportunidad (`O-01`, `O-02`, …).
  final int siguienteNumero;

  /// `true` mientras el repositorio escribe en SQLite.
  final bool guardando;

  /// `true` mientras se lee la preferencia del último establecimiento.
  final bool cargandoPreferencia;

  /// Código del último establecimiento auditado, leído de la tabla
  /// `preferencias` (dato **no** sensible: por eso va a SQLite y no al
  /// almacén seguro de la Semana 11).
  final String? ultimoEstablecimiento;

  /// Oportunidades en las que sí se cumplió la higiene de manos.
  int get cumplidas => oportunidades
      .where((OportunidadRegistro o) => o.cumplio)
      .length;

  /// Adherencia parcial en porcentaje (0 cuando no hay datos).
  int get porcentaje => oportunidades.isEmpty
      ? 0
      : ((cumplidas / oportunidades.length) * 100).round();

  /// `true` si hay algo que guardar.
  bool get hayDatos => oportunidades.isNotEmpty;

  EstadoCaptura copyWith({
    List<OportunidadRegistro>? oportunidades,
    Accion? accionSeleccionada,
    int? siguienteNumero,
    bool? guardando,
    bool? cargandoPreferencia,
    String? ultimoEstablecimiento,
  }) {
    return EstadoCaptura(
      oportunidades: oportunidades ?? this.oportunidades,
      accionSeleccionada: accionSeleccionada ?? this.accionSeleccionada,
      siguienteNumero: siguienteNumero ?? this.siguienteNumero,
      guardando: guardando ?? this.guardando,
      cargandoPreferencia: cargandoPreferencia ?? this.cargandoPreferencia,
      ultimoEstablecimiento: ultimoEstablecimiento ?? this.ultimoEstablecimiento,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EstadoCaptura &&
        listEquals(other.oportunidades, oportunidades) &&
        other.accionSeleccionada == accionSeleccionada &&
        other.siguienteNumero == siguienteNumero &&
        other.guardando == guardando &&
        other.cargandoPreferencia == cargandoPreferencia &&
        other.ultimoEstablecimiento == ultimoEstablecimiento;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(oportunidades),
        accionSeleccionada,
        siguienteNumero,
        guardando,
        cargandoPreferencia,
        ultimoEstablecimiento,
      );

  @override
  String toString() =>
      'EstadoCaptura(${oportunidades.length} oportunidades, '
      'siguiente O-${siguienteNumero.toString().padLeft(2, '0')}, '
      'guardando: $guardando)';
}

/// **`Notifier` de la captura** — temática 2.3.3 del sílabo.
///
/// Es la migración directa del `setState` de `PantallaOportunidades`:
///
/// | Antes (Semana 10)                                     | Ahora (Semana 12) |
/// |---|---|
/// | `void _agregar() { setState(() { _oportunidades.add(…); }); }` | `ref.read(capturaProvider.notifier).agregar()` |
/// | `void _quitar(int n) { setState(() { _oportunidades.removeWhere(…); }); }` | `…notifier.quitar(n)` |
/// | `setState(() => _accionSeleccionada = accion)`        | `…notifier.seleccionarAccion(accion)` |
/// | `setState(() => _guardando = true)` dentro del widget | `state = state.copyWith(guardando: true)` dentro del notifier |
///
/// ## ¿Por qué `keepAlive: true` si es "estado de una pantalla"?
///
/// Porque **no** es estado efímero: es el borrador de una auditoría en curso
/// que debe sobrevivir a la navegación. El flujo real del proyecto es
/// `/establecimiento` → `/oportunidades` → `/auditorias`; si el usuario va al
/// catálogo a consultar un dato y vuelve, el borrador tiene que seguir ahí.
/// Un provider `autoDispose` (el valor por defecto de `@riverpod`) destruiría
/// la captura en cuanto la pantalla saliera del árbol.
///
/// La documentación oficial advierte «AVOID using providers for Ephemeral
/// state» y nombra como efímero el estado de un formulario; este caso es
/// justo el límite: **es estado de negocio compartido**, no un
/// `TextEditingController`. El borrador se descarta explícitamente con
/// [descartar], no por recolección de basura.
///
/// TODO(reto-2, 2 puntos): demuestre con una prueba la diferencia. Cree una
/// copia del provider con `@riverpod` (auto-dispose) en un archivo de
/// laboratorio, navegue fuera de la pantalla y compruebe con
/// `ProviderContainer` que el estado se pierde. Adjunte la evidencia al
/// informe (§7).
@Riverpod(keepAlive: true)
class Captura extends _$Captura {
  /// Clave de la preferencia del último establecimiento auditado. Se
  /// conserva la de la Semana 10 para no romper instalaciones existentes.
  static const String claveUltimoEstablecimiento = 'establecimiento.ultimo';

  @override
  EstadoCaptura build() {
    // El provider se inicializa a sí mismo (regla oficial «AVOID initializing
    // providers in a widget»). La lectura de la preferencia es asíncrona y
    // `build()` es síncrono: por eso se lanza sin `await` y se protege con
    // `ref.mounted`. **Este es exactamente el olor de código que la Semana 13
    // elimina al reescribir este provider como `AsyncNotifier`**: entonces el
    // `await` vive dentro de `build()` y la interfaz recibe un `AsyncValue`
    // con sus estados de carga y error.
    unawaited(_recuperarUltimoEstablecimiento());
    return const EstadoCaptura();
  }

  Future<void> _recuperarUltimoEstablecimiento() async {
    try {
      final String? codigo = await ref
          .read(preferenciasRepositoryProvider)
          .leer(claveUltimoEstablecimiento);
      // Tras un `await` el provider pudo haberse destruido. En Riverpod 3,
      // tocar un `Ref` muerto lanza `UnmountedRefException`; `ref.mounted` es
      // la comprobación oficial.
      if (!ref.mounted) return;
      state = state.copyWith(
        ultimoEstablecimiento: codigo,
        cargandoPreferencia: false,
      );
    } on Object catch (error) {
      debugPrint('No se pudo leer el último establecimiento: $error');
      if (!ref.mounted) return;
      state = state.copyWith(cargandoPreferencia: false);
    }
  }

  /// Cambia la acción que se aplicará a la próxima oportunidad.
  void seleccionarAccion(Accion accion) {
    if (accion == state.accionSeleccionada) return;
    state = state.copyWith(accionSeleccionada: accion);
  }

  /// Agrega una oportunidad. El momento se recorre en ciclo para que la
  /// captura de laboratorio produzca datos variados, igual que en la
  /// Semana 10.
  void agregar() {
    final Momento momento =
        Momento.values[state.oportunidades.length % Momento.values.length];
    state = state.copyWith(
      oportunidades: <OportunidadRegistro>[
        ...state.oportunidades,
        OportunidadRegistro(
          auditoriaId: '', // lo completa el repositorio al guardar
          numero: state.siguienteNumero,
          momento: momento,
          accion: state.accionSeleccionada,
        ),
      ],
      siguienteNumero: state.siguienteNumero + 1,
    );
  }

  /// Quita la oportunidad con ese número correlativo.
  void quitar(int numero) {
    state = state.copyWith(
      oportunidades: state.oportunidades
          .where((OportunidadRegistro o) => o.numero != numero)
          .toList(growable: false),
    );
  }

  /// Descarta el borrador completo (se llama después de guardar o cuando el
  /// usuario lo pide explícitamente).
  void descartar() {
    state = state.copyWith(
      oportunidades: const <OportunidadRegistro>[],
      siguienteNumero: 1,
      guardando: false,
    );
  }

  /// **Guarda la auditoría en SQLite.**
  ///
  /// Devuelve un [ResultadoOperacion]: el notifier no conoce `BuildContext`,
  /// así que no puede mostrar un `SnackBar`; narra el resultado y la pantalla
  /// decide. Es la separación que exige la arquitectura por capas.
  ///
  /// Fíjese también en lo que **no** hace: no valida credenciales, no conoce
  /// drift y no genera el `id` con `DateTime.now()` (usa [generarUuidV4],
  /// Semana 10).
  Future<ResultadoOperacion> guardar() async {
    if (!state.hayDatos) {
      return const OperacionSinDatos(
        'Registre al menos una oportunidad antes de guardar.',
      );
    }

    state = state.copyWith(guardando: true);

    final Establecimiento establecimiento = Establecimiento.ejemplo();
    final Observador observador = Observador.ejemplo();
    final Observado observado = Observado.ejemplo();

    final Auditoria auditoria = Auditoria(
      id: generarUuidV4(),
      establecimientoId: establecimiento.codigoUnico,
      establecimientoNombre: establecimiento.nombre,
      observadorDni: observador.dni,
      observadorNombre: observador.nombresApellidos,
      observadoDni: observado.dni,
      observadoNombre: observado.nombresApellidos,
      fecha: DateTime.now(),
      estado: EstadoAuditoria.borrador,
      oportunidades: List<OportunidadRegistro>.of(state.oportunidades),
    );

    try {
      final String id =
          await ref.read(auditoriaRepositoryProvider).guardar(auditoria);
      await ref
          .read(preferenciasRepositoryProvider)
          .guardar(claveUltimoEstablecimiento, establecimiento.codigoUnico);

      if (!ref.mounted) return const OperacionOk();

      // El borrador se vacía SOLO cuando el guardado terminó bien.
      state = state.copyWith(
        oportunidades: const <OportunidadRegistro>[],
        siguienteNumero: 1,
        guardando: false,
        ultimoEstablecimiento: establecimiento.codigoUnico,
      );
      return OperacionOk(id);
    } on Object catch (fallo) {
      if (!ref.mounted) return const OperacionFallida('No se pudo guardar.');
      state = state.copyWith(guardando: false);
      return OperacionFallida(_mensajeDe(fallo));
    }
  }

  /// Traduce cualquier fallo a un mensaje apto para el usuario, sin filtrar
  /// detalles internos de SQLite (misma política que la Semana 10).
  static String _mensajeDe(Object fallo) {
    final String texto = fallo.toString();
    if (texto.contains('no es válida') || texto.contains('inválida')) {
      return 'La auditoría no pasó la validación del dominio.';
    }
    return 'No se pudo guardar la auditoría en el dispositivo.';
  }
}
