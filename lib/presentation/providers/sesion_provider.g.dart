// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sesion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(SesionCtrl)
final sesionCtrlProvider = SesionCtrlProvider._();

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
final class SesionCtrlProvider
    extends $NotifierProvider<SesionCtrl, EstadoSesion> {
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
  SesionCtrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sesionCtrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sesionCtrlHash();

  @$internal
  @override
  SesionCtrl create() => SesionCtrl();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoSesion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoSesion>(value),
    );
  }
}

String _$sesionCtrlHash() => r'49a66305c380fe42b34f797230c00886ffffc814';

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

abstract class _$SesionCtrl extends $Notifier<EstadoSesion> {
  EstadoSesion build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EstadoSesion, EstadoSesion>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EstadoSesion, EstadoSesion>,
              EstadoSesion,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
