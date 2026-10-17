import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/fallos.dart';
import '../../data/repositorios/sesion_repository_seguro.dart';
import '../../domain/entidades/sesion.dart';
import '../../domain/repositorios/sesion_repository.dart';
import '../../domain/servicios/generador_token.dart';
import 'dependencias_providers.dart';
import 'resultado_operacion.dart';

part 'sesion_provider.g.dart';

/// **Estado de la sesión a nivel de aplicación** (Semana 12).
///
/// Reemplaza a `core/gestor_sesion.dart`, que en la Semana 11 era un
/// `ValueNotifier<Sesion?>` observado con `ValueListenableBuilder`.
///
/// La diferencia importante respecto de [Tema] no es el mecanismo, sino el
/// **contenido**: aquí el estado ya no es un `Sesion?` suelto, sino un objeto
/// con tres campos. El motivo es que la pantalla necesita distinguir «no hay
/// sesión» de «estoy guardando en el Keystore» de «el almacén falló», y un
/// `Sesion?` no puede expresar esas tres situaciones a la vez.
///
/// ```
///   EstadoSesion(procesando: false, sesion: null)          → "Sin sesión"
///   EstadoSesion(procesando: true,  sesion: null)          → botón deshabilitado
///   EstadoSesion(procesando: false, sesion: Sesion(…))     → tarjeta con la huella
/// ```
///
/// La Semana 13 va a reemplazar esta clase por `AsyncValue<EstadoSesion>`,
/// que trae `loading` / `error` / `data` de fábrica. Aquí se construye a mano
/// **para que se vea por qué hace falta**.
@immutable
class EstadoSesion {
  const EstadoSesion({
    this.sesion,
    this.procesando = false,
    this.ultimoFallo,
  });

  /// Sesión activa en memoria, o `null`.
  final Sesion? sesion;

  /// `true` mientras hay una operación de sesión en vuelo.
  final bool procesando;

  /// Último mensaje de fallo, o `null`. Se limpia al empezar una operación:
  /// es estado derivado de la interacción, no un registro histórico.
  final String? ultimoFallo;

  /// `true` si hay una sesión con token vigente.
  bool get haySesionActiva =>
      sesion != null && sesion!.activaEn(DateTime.now());

  bool get haySesion => sesion != null;

  EstadoSesion copyWith({
    Sesion? sesion,
    bool? procesando,
    String? ultimoFallo,
    bool limpiarSesion = false,
    bool limpiarFallo = false,
  }) {
    return EstadoSesion(
      sesion: limpiarSesion ? null : (sesion ?? this.sesion),
      procesando: procesando ?? this.procesando,
      ultimoFallo: limpiarFallo ? null : (ultimoFallo ?? this.ultimoFallo),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstadoSesion &&
          other.sesion == sesion &&
          other.procesando == procesando &&
          other.ultimoFallo == ultimoFallo;

  @override
  int get hashCode => Object.hash(sesion, procesando, ultimoFallo);

  @override
  String toString() => 'EstadoSesion(${sesion == null ? 'sin sesión' : sesion!.nombre}, '
      'procesando: $procesando, fallo: $ultimoFallo)';
}

/// **Ciclo de vida del token de sesión, ahora como `Notifier`.**
///
/// El ciclo de vida no cambió nada respecto de la Semana 11:
///
/// ```
///  iniciar()     credenciales → token simulado → guardar (Keystore/Keychain)
///       │
///  restaurar()   lee del almacén seguro; si el token expiró, cierra sesión
///       │
///  cerrar()      elimina la clave del almacén seguro
/// ```
///
/// Lo que cambió es quién decide:
///
///  * antes, la pantalla llamaba a `getIt<GestorSesion>()` y hacía `setState`
///    para el indicador de progreso;
///  * ahora la pantalla **observa** `sesionProvider` y el notifier es el único
///    que escribe el estado.
///
/// TODO(reto-3, 3 puntos): la Semana 13 reescribe esto con `AsyncNotifier` y
/// `AsyncValue`. Adelántese: escriba en un archivo aparte
/// (`sesion_provider_async.dart`) la versión con `AsyncNotifier`, compare
/// cuántas líneas se ahorran, y documente en el informe **un caso concreto**
/// en el que el `AsyncValue` evita un error que la versión actual permite
/// (pista: dos `iniciar()` pulsados a la vez).
@Riverpod(keepAlive: true)
class SesionCtrl extends _$SesionCtrl {
  @override
  EstadoSesion build() => const EstadoSesion();

  /// Nombre del mecanismo que protege el token en esta plataforma.
  ///
  /// Se expone como *getter* del notifier —y no como campo del estado— porque
  /// es una propiedad del repositorio, no de la sesión: no cambia de una
  /// operación a otra y no tiene sentido notificar a la interfaz cuando se
  /// consulta.
  String get mecanismoDeProteccion {
    final SesionRepository repositorio = ref.read(sesionRepositoryProvider);
    return repositorio is SesionRepositorySeguro
        ? repositorio.mecanismoDeProteccion
        : 'Almacén sin cifrado (implementación de laboratorio)';
  }

  /// Texto listo para la interfaz con la información **no sensible** de la
  /// sesión: huella del token y tiempo restante.
  ///
  /// Advertencia honesta: el tiempo restante se calcula con `DateTime.now()`
  /// en el momento de leer, así que **no** se actualiza solo mientras la
  /// pantalla está abierta. La Semana 13 lo resuelve con un `Stream`/`Timer`
  /// observado por el provider. Está anotado como limitación conocida.
  String? get descripcionToken {
    final Sesion? sesion = state.sesion;
    if (sesion == null) return null;
    final Duration restante = sesion.token.restanteEn(DateTime.now());
    final String horas = restante.inHours.toString().padLeft(2, '0');
    final String minutos = (restante.inMinutes % 60).toString().padLeft(2, '0');
    return 'huella ${sesion.token.huella} · expira en ${horas}h ${minutos}m';
  }

  /// `true` si el token sigue siendo válido pero está por expirar.
  bool get porExpirar {
    final Sesion? sesion = state.sesion;
    return sesion != null && sesion.token.porExpirarEn(DateTime.now());
  }

  /// **Restaura la sesión** al arrancar la aplicación.
  ///
  /// Se llama una sola vez desde `main()`, después de crear el
  /// `ProviderContainer`. Si el almacén no responde, la aplicación **no**
  /// debe impedir el arranque: se registra el problema y se continúa sin
  /// sesión. Si lo que falla es el contenido guardado, se limpia el almacén y
  /// se pide autenticarse otra vez.
  Future<void> restaurar() async {
    final SesionRepository repositorio = ref.read(sesionRepositoryProvider);
    try {
      final Sesion? guardada = await repositorio.leer();
      if (!ref.mounted) return;
      if (guardada == null) {
        state = const EstadoSesion();
        return;
      }
      if (!guardada.activaEn(DateTime.now())) {
        // Token vencido: cerrar es la única respuesta correcta.
        await repositorio.cerrar();
        if (!ref.mounted) return;
        state = const EstadoSesion();
        return;
      }
      state = EstadoSesion(sesion: guardada);
    } on FalloDeValidacion catch (error) {
      debugPrint('La sesión guardada no es legible, se descarta: '
          '${error.mensaje}');
      await repositorio.cerrar();
      if (!ref.mounted) return;
      state = const EstadoSesion();
    } on FalloSeguridad catch (error) {
      debugPrint('El almacén seguro no está disponible: ${error.mensaje}');
      if (!ref.mounted) return;
      state = EstadoSesion(ultimoFallo: error.mensaje);
    }
  }

  /// **Inicia sesión**: verifica credenciales, emite un token simulado y lo
  /// guarda en el almacén seguro.
  ///
  /// En este último caso la sesión **no** queda activa en memoria: es
  /// preferible pedir de nuevo el inicio de sesión que dejar al usuario
  /// trabajando con una sesión que no sobrevivirá al cierre de la aplicación.
  Future<ResultadoOperacion> iniciar({
    required String documento,
    required String clave,
    DateTime? ahora,
  }) async {
    if (state.procesando) {
      // Guarda de reentrada: dos pulsaciones rápidas del botón no pueden
      // emitir dos tokens. En la Semana 13 esta guarda desaparece porque el
      // AsyncValue ya expresa "hay una operación en curso".
      return const OperacionSinDatos('Ya hay una operación de sesión en curso.');
    }

    state = state.copyWith(procesando: true, limpiarFallo: true);

    try {
      final UsuarioSimulado? usuario = ref
          .read(directorioUsuariosProvider)
          .autenticar(documento: documento, clave: clave);
      if (usuario == null) {
        throw const FalloDeAutenticacion();
      }

      final Sesion nueva = Sesion(
        documento: usuario.documento,
        nombre: usuario.nombre,
        rol: usuario.rol,
        token: ref.read(generadorTokenProvider).emitir(ahora: ahora),
      );

      await ref.read(sesionRepositoryProvider).guardar(nueva);
      if (!ref.mounted) return const OperacionOk();

      state = EstadoSesion(sesion: nueva);
      return OperacionOk('Sesión iniciada para ${nueva.nombre}.');
    } on Fallo catch (fallo) {
      if (!ref.mounted) return OperacionFallida(fallo.mensaje);
      state = state.copyWith(procesando: false, ultimoFallo: fallo.mensaje);
      return OperacionFallida(fallo.mensaje);
    }
  }

  /// **Cierra sesión** de forma completa: borra el dato del almacén seguro y
  /// la referencia en memoria.
  Future<ResultadoOperacion> cerrar() async {
    if (state.procesando) {
      return const OperacionSinDatos('Ya hay una operación de sesión en curso.');
    }

    state = state.copyWith(procesando: true, limpiarFallo: true);
    try {
      await ref.read(sesionRepositoryProvider).cerrar();
      if (!ref.mounted) return const OperacionOk();
      state = const EstadoSesion();
      return const OperacionOk(
        'Sesión cerrada y token eliminado del almacén seguro.',
      );
    } on Fallo catch (fallo) {
      if (!ref.mounted) return OperacionFallida(fallo.mensaje);
      state = state.copyWith(procesando: false, ultimoFallo: fallo.mensaje);
      return OperacionFallida(fallo.mensaje);
    }
  }
}
