import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'dependencias_providers.dart';

part 'tema_provider.g.dart';

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
@Riverpod(keepAlive: true)
class Tema extends _$Tema {
  /// Clave con la que la preferencia se guarda en la tabla `preferencias`.
  ///
  /// Se conserva **exactamente** la de la Semana 10 (`'tema.modo'`): si
  /// cambiara, las instalaciones existentes perderían la preferencia
  /// guardada. Es un ejemplo real de compatibilidad hacia atrás.
  static const String clave = 'tema.modo';

  @override
  ThemeMode build() => ThemeMode.system;

  /// Lee la preferencia guardada y actualiza el estado.
  ///
  /// **No** se llama desde `build()`: la documentación oficial lo prohíbe
  /// («DON'T perform side effects during the initialization of a provider» y
  /// «AVOID initializing providers in a widget»). Se llama una sola vez,
  /// desde `main()`, antes de `runApp`.
  ///
  /// Si no hay nada guardado o la lectura falla, se conserva
  /// `ThemeMode.system` en lugar de propagar el error: una preferencia no
  /// debe impedir que la aplicación abra. Es la misma política que la
  /// Semana 10 y está registrada en el informe.
  ///
  /// TODO(reto-1c, 1 punto): la política actual **traga** el error con
  /// `debugPrint`. Proponga y documente una política mejor (por ejemplo,
  /// exponer un `bool huboFallo` en el estado para que `/diagnostico` lo
  /// muestre) sin romper el arranque.
  Future<void> cargarDesdeDisco() async {
    try {
      final String? guardado =
          await ref.read(preferenciasRepositoryProvider).leer(clave);
      state = _desdeTexto(guardado);
    } catch (error) {
      debugPrint('No se pudo leer la preferencia de tema: $error');
    }
  }

  /// Persiste el modo elegido por el usuario y notifica a los consumidores.
  ///
  /// TODO(reto-1b, 1 punto): analice qué ocurre si el guardado falla (disco
  /// lleno, base bloqueada). Hoy el estado en memoria ya cambió y el disco
  /// quedó desincronizado. Implemente la política que su equipo decida
  /// —revertir el valor en memoria o mantener la preferencia solo en esta
  /// sesión— y documéntela. Pista: note que este método puede devolver
  /// [ResultadoOperacion] igual que los otros notifiers del proyecto.
  Future<void> cambiarYGuardar(ThemeMode nuevo) async {
    state = nuevo;
    try {
      await ref
          .read(preferenciasRepositoryProvider)
          .guardar(clave, _aTexto(nuevo));
    } catch (error) {
      debugPrint('No se pudo guardar la preferencia de tema: $error');
    }
  }

  /// Alterna entre claro y oscuro. Se expone como método del notifier —y no
  /// como código en el widget— para que la regla «¿qué sigue después?» viva
  /// en un solo lugar y sea comprobable con una prueba.
  Future<void> alternar() => cambiarYGuardar(
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );

  static ThemeMode _desdeTexto(String? texto) {
    switch (texto) {
      case 'claro':
        return ThemeMode.light;
      case 'oscuro':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _aTexto(ThemeMode modo) {
    switch (modo) {
      case ThemeMode.light:
        return 'claro';
      case ThemeMode.dark:
        return 'oscuro';
      case ThemeMode.system:
        return 'sistema';
    }
  }
}
