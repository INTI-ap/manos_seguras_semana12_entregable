// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'captura_temporal.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Copia de laboratorio: auto-dispose permite demostrar la pérdida al salir.
/// No se usa en la aplicación; sus operaciones coinciden con Captura.

@ProviderFor(CapturaTemporal)
final capturaTemporalProvider = CapturaTemporalProvider._();

/// Copia de laboratorio: auto-dispose permite demostrar la pérdida al salir.
/// No se usa en la aplicación; sus operaciones coinciden con Captura.
final class CapturaTemporalProvider
    extends $NotifierProvider<CapturaTemporal, EstadoCaptura> {
  /// Copia de laboratorio: auto-dispose permite demostrar la pérdida al salir.
  /// No se usa en la aplicación; sus operaciones coinciden con Captura.
  CapturaTemporalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'capturaTemporalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$capturaTemporalHash();

  @$internal
  @override
  CapturaTemporal create() => CapturaTemporal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoCaptura value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoCaptura>(value),
    );
  }
}

String _$capturaTemporalHash() => r'ccfc553593aaf259bcd82637c8c8d87b596df2e5';

/// Copia de laboratorio: auto-dispose permite demostrar la pérdida al salir.
/// No se usa en la aplicación; sus operaciones coinciden con Captura.

abstract class _$CapturaTemporal extends $Notifier<EstadoCaptura> {
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
