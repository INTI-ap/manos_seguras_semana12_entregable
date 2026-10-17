// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tema_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// **Semana 12 · temática 2.3.3 — de `ValueNotifier` a `Notifier`.**
///
/// Este archivo reemplaza a `core/tema_app.dart`, que en la Semana 10 era un
/// `ValueNotifier<ThemeMode>` observado con `ValueListenableBuilder` desde
/// `main.dart`. La lógica es la misma; lo que cambia es el **mecanismo**:
///
/// | Antes (Semana 10)                     | Ahora (Semana 12)                    |
/// |---|---|
/// | `TemaApp extends ValueNotifier<ThemeMode>` | `Tema extends _$Tema` (`Notifier`) |
/// | `gestor.cargarDesdeDisco()`            | `ref.read(temaProvider.notifier).cargarDesdeDisco()` |
/// | `ValueListenableBuilder<TemaApp>`      | `ref.watch(temaProvider)`            |
/// | `getIt<TemaApp>()`                     | `ref.watch(temaProvider)`            |
///
/// ## Por qué `keepAlive: true`
///
/// El modo de tema lo consume la **raíz** de la aplicación, que nunca se
/// desmonta. Si el provider fuera *auto-dispose* (el valor por defecto de
/// `@riverpod`) y en algún momento nadie lo observara —por ejemplo durante un
/// `pushReplacement` que reconstruye el árbol—, Riverpod destruiría su estado
/// y volvería a `ThemeMode.system`, perdiendo la preferencia elegida. Con
/// `keepAlive: true` el estado vive lo que vive la aplicación.
///
/// Genera, en `tema_provider.g.dart`, el provider `temaProvider` y la clase
/// base `_$Tema`. **El archivo `.g.dart` no se edita a mano.**

@ProviderFor(Tema)
final temaProvider = TemaProvider._();

/// **Semana 12 · temática 2.3.3 — de `ValueNotifier` a `Notifier`.**
///
/// Este archivo reemplaza a `core/tema_app.dart`, que en la Semana 10 era un
/// `ValueNotifier<ThemeMode>` observado con `ValueListenableBuilder` desde
/// `main.dart`. La lógica es la misma; lo que cambia es el **mecanismo**:
///
/// | Antes (Semana 10)                     | Ahora (Semana 12)                    |
/// |---|---|
/// | `TemaApp extends ValueNotifier<ThemeMode>` | `Tema extends _$Tema` (`Notifier`) |
/// | `gestor.cargarDesdeDisco()`            | `ref.read(temaProvider.notifier).cargarDesdeDisco()` |
/// | `ValueListenableBuilder<TemaApp>`      | `ref.watch(temaProvider)`            |
/// | `getIt<TemaApp>()`                     | `ref.watch(temaProvider)`            |
///
/// ## Por qué `keepAlive: true`
///
/// El modo de tema lo consume la **raíz** de la aplicación, que nunca se
/// desmonta. Si el provider fuera *auto-dispose* (el valor por defecto de
/// `@riverpod`) y en algún momento nadie lo observara —por ejemplo durante un
/// `pushReplacement` que reconstruye el árbol—, Riverpod destruiría su estado
/// y volvería a `ThemeMode.system`, perdiendo la preferencia elegida. Con
/// `keepAlive: true` el estado vive lo que vive la aplicación.
///
/// Genera, en `tema_provider.g.dart`, el provider `temaProvider` y la clase
/// base `_$Tema`. **El archivo `.g.dart` no se edita a mano.**
final class TemaProvider extends $NotifierProvider<Tema, ThemeMode> {
  /// **Semana 12 · temática 2.3.3 — de `ValueNotifier` a `Notifier`.**
  ///
  /// Este archivo reemplaza a `core/tema_app.dart`, que en la Semana 10 era un
  /// `ValueNotifier<ThemeMode>` observado con `ValueListenableBuilder` desde
  /// `main.dart`. La lógica es la misma; lo que cambia es el **mecanismo**:
  ///
  /// | Antes (Semana 10)                     | Ahora (Semana 12)                    |
  /// |---|---|
  /// | `TemaApp extends ValueNotifier<ThemeMode>` | `Tema extends _$Tema` (`Notifier`) |
  /// | `gestor.cargarDesdeDisco()`            | `ref.read(temaProvider.notifier).cargarDesdeDisco()` |
  /// | `ValueListenableBuilder<TemaApp>`      | `ref.watch(temaProvider)`            |
  /// | `getIt<TemaApp>()`                     | `ref.watch(temaProvider)`            |
  ///
  /// ## Por qué `keepAlive: true`
  ///
  /// El modo de tema lo consume la **raíz** de la aplicación, que nunca se
  /// desmonta. Si el provider fuera *auto-dispose* (el valor por defecto de
  /// `@riverpod`) y en algún momento nadie lo observara —por ejemplo durante un
  /// `pushReplacement` que reconstruye el árbol—, Riverpod destruiría su estado
  /// y volvería a `ThemeMode.system`, perdiendo la preferencia elegida. Con
  /// `keepAlive: true` el estado vive lo que vive la aplicación.
  ///
  /// Genera, en `tema_provider.g.dart`, el provider `temaProvider` y la clase
  /// base `_$Tema`. **El archivo `.g.dart` no se edita a mano.**
  TemaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'temaProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$temaHash();

  @$internal
  @override
  Tema create() => Tema();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$temaHash() => r'd64d472bb6d132765b2899680d18a3b0b4133c24';

/// **Semana 12 · temática 2.3.3 — de `ValueNotifier` a `Notifier`.**
///
/// Este archivo reemplaza a `core/tema_app.dart`, que en la Semana 10 era un
/// `ValueNotifier<ThemeMode>` observado con `ValueListenableBuilder` desde
/// `main.dart`. La lógica es la misma; lo que cambia es el **mecanismo**:
///
/// | Antes (Semana 10)                     | Ahora (Semana 12)                    |
/// |---|---|
/// | `TemaApp extends ValueNotifier<ThemeMode>` | `Tema extends _$Tema` (`Notifier`) |
/// | `gestor.cargarDesdeDisco()`            | `ref.read(temaProvider.notifier).cargarDesdeDisco()` |
/// | `ValueListenableBuilder<TemaApp>`      | `ref.watch(temaProvider)`            |
/// | `getIt<TemaApp>()`                     | `ref.watch(temaProvider)`            |
///
/// ## Por qué `keepAlive: true`
///
/// El modo de tema lo consume la **raíz** de la aplicación, que nunca se
/// desmonta. Si el provider fuera *auto-dispose* (el valor por defecto de
/// `@riverpod`) y en algún momento nadie lo observara —por ejemplo durante un
/// `pushReplacement` que reconstruye el árbol—, Riverpod destruiría su estado
/// y volvería a `ThemeMode.system`, perdiendo la preferencia elegida. Con
/// `keepAlive: true` el estado vive lo que vive la aplicación.
///
/// Genera, en `tema_provider.g.dart`, el provider `temaProvider` y la clase
/// base `_$Tema`. **El archivo `.g.dart` no se edita a mano.**

abstract class _$Tema extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
