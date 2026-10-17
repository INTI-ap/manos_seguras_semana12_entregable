import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// **Observador de providers** (Semana 12).
///
/// Riverpod expone `ProviderObserver`: un objeto que recibe **todos** los
/// eventos del ciclo de vida de **todos** los providers de un contenedor.
/// Sirve para tres cosas concretas y nada más:
///
///  1. **Depurar**: ver en la consola del editor qué provider se construyó,
///     cuándo cambió y con qué valor. Es la herramienta que reemplaza a los
///     `print` repartidos por el código.
///  2. **Auditar**: en una aplicación con datos clínicos, saber qué estado
///     cambió y en qué orden es parte de la trazabilidad.
///  3. **Medir**: contar reconstrucciones para justificar decisiones de
///     rendimiento en el informe técnico.
///
/// ## Las cuatro firmas que hay que respetar (Riverpod 3)
///
/// En la versión 2 el observador recibía el provider y el contenedor como dos
/// parámetros separados. En la **versión 3** reciben un único
/// `ProviderObserverContext` que contiene ambos:
///
/// ```dart
/// // Riverpod 2 (ya no compila en 3)
/// void didAddProvider(ProviderBase provider, Object? value,
///                     ProviderContainer container) {}
///
/// // Riverpod 3
/// void didAddProvider(ProviderObserverContext context, Object? value) {}
/// ```
///
/// Es un cambio que aparece en la guía de migración oficial y que los
/// apuntes antiguos no recogen.
///
/// ## Regla de oro: el observador NO escribe estado
///
/// Aquí solo se registra. Si un observador llamara a `ref.read(...)` o
/// modificara un provider, se produciría una reacción en cadena imposible de
/// depurar. La documentación oficial lo advierte: los `onDispose` y los
/// observadores no deben provocar efectos secundarios.
///
/// **Advertencia de seguridad (Semana 11 sigue vigente):** este registro
/// imprime el **nombre** del provider y un resumen del valor, nunca el valor
/// completo de un estado que pueda contener datos personales o credenciales.
/// Por eso [EstadoSesion.toString] y [EstadoCaptura.toString] están escritos a
/// mano: no vuelcan campos sensibles.
final class RegistroDeProviders extends ProviderObserver {
  RegistroDeProviders({this.activo = kDebugMode});

  /// En compilaciones de release el registro se apaga: no se paga el costo de
  /// construir las cadenas de texto.
  final bool activo;

  int _creados = 0;
  int _actualizados = 0;
  int _destruidos = 0;
  int _fallos = 0;

  /// Contadores listos para que `/diagnostico` los muestre si el equipo lo
  /// decide (Reto 1).
  Map<String, int> get resumen => <String, int>{
        'creados': _creados,
        'actualizados': _actualizados,
        'destruidos': _destruidos,
        'fallos': _fallos,
      };

  String _nombre(ProviderObserverContext context) =>
      context.provider.name ?? context.provider.runtimeType.toString();

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (!activo) return;
    _creados++;
    debugPrint('[riverpod] + ${_nombre(context)}');
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (!activo) return;
    _actualizados++;
    debugPrint('[riverpod] ~ ${_nombre(context)} → $newValue');
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    if (!activo) return;
    _destruidos++;
    debugPrint('[riverpod] - ${_nombre(context)}');
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!activo) return;
    _fallos++;
    // Fíjese en que NO se imprime el stack trace completo en release; en
    // depuración sí, porque es la única forma de diagnosticar.
    debugPrint('[riverpod] ! ${_nombre(context)}: $error');
    if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
  }
}
