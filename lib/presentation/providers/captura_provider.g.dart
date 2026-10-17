// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'captura_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Conserva el borrador al navegar, no al cerrar el proceso de la aplicación.
/// Se libera explícitamente al guardar con éxito o al confirmar el descarte.

@ProviderFor(Captura)
final capturaProvider = CapturaProvider._();

/// Conserva el borrador al navegar, no al cerrar el proceso de la aplicación.
/// Se libera explícitamente al guardar con éxito o al confirmar el descarte.
final class CapturaProvider extends $NotifierProvider<Captura, EstadoCaptura> {
  /// Conserva el borrador al navegar, no al cerrar el proceso de la aplicación.
  /// Se libera explícitamente al guardar con éxito o al confirmar el descarte.
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

String _$capturaHash() => r'a4532454f4ec0b5cf3bc724f2b2f6ce221e5973e';

/// Conserva el borrador al navegar, no al cerrar el proceso de la aplicación.
/// Se libera explícitamente al guardar con éxito o al confirmar el descarte.

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
