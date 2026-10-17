// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'captura_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(Captura)
final capturaProvider = CapturaProvider._();

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
final class CapturaProvider extends $NotifierProvider<Captura, EstadoCaptura> {
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
  CapturaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'capturaProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$capturaHash();

  @$internal
  @override
  Captura create() => Captura();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoCaptura value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoCaptura>(value),
    );
  }
}

String _$capturaHash() => r'cf80aee82aa1feb7702ac29e128c2d8027f275cf';

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

abstract class _$Captura extends $Notifier<EstadoCaptura> {
  EstadoCaptura build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EstadoCaptura, EstadoCaptura>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EstadoCaptura, EstadoCaptura>,
              EstadoCaptura,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
