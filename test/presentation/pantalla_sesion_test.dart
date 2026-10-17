import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manos_seguras/data/repositorios/sesion_repository_seguro.dart';
import 'package:manos_seguras/data/seguro/almacen_seguro.dart';
import 'package:manos_seguras/data/seguro/almacen_seguro_en_memoria.dart';
import 'package:manos_seguras/domain/entidades/sesion.dart';
import 'package:manos_seguras/domain/repositorios/sesion_repository.dart';
import 'package:manos_seguras/domain/servicios/generador_token.dart';
import 'package:manos_seguras/presentation/di.dart';
import 'package:manos_seguras/presentation/pantallas/pantalla_sesion.dart';
import 'package:manos_seguras/presentation/providers/sesion_provider.dart';

/// **Pruebas de widget de la pantalla de sesión** (Semanas 11 y 12).
///
/// La Semana 11 ya probaba aquí el ciclo completo. En la Semana 12 el ciclo de
/// vida se prueba además **sin interfaz**, en `sesion_provider_test.dart`; a
/// esta prueba le queda lo que solo se puede verificar montando la pantalla:
///
///  1. que la interfaz reaccione a los cambios de `sesionProvider` (antes lo
///     hacía un `ValueListenableBuilder`; ahora, `ref.watch`);
///  2. **que el valor del token nunca llegue a la pantalla**, que es la regla
///     de manejo del dato sensible más fácil de romper sin darse cuenta
///     (basta con un `Text(sesion.token.valor)` "para depurar").
///
/// El contenedor se crea a mano con `ProviderContainer.test()` —que lo
/// destruye al terminar la prueba— y se inyecta con
/// `UncontrolledProviderScope`, igual que hace `main()` al arrancar.
void main() {
  late AlmacenSeguroEnMemoria almacen;

  setUp(() {
    almacen = AlmacenSeguroEnMemoria();
    getIt
      ..registerSingleton<AlmacenSeguro>(almacen)
      ..registerSingleton<SesionRepository>(
        SesionRepositorySeguro(almacen),
      )
      ..registerSingleton<GeneradorTokenSimulado>(GeneradorTokenSimulado())
      ..registerSingleton<DirectorioUsuariosSimulado>(
        DirectorioUsuariosSimulado(),
      );
  });

  tearDown(() async {
    await getIt.reset();
  });

  /// Abre la pantalla con su propio contenedor de Riverpod.
  ///
  /// `ProviderContainer.test()` registra la destrucción del contenedor al
  /// final de la prueba: no hace falta un `tearDown` que lo cierre.
  Future<ProviderContainer> abrir(WidgetTester tester) async {
    final ProviderContainer contenedor = ProviderContainer.test();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: contenedor,
        child: const MaterialApp(home: PantallaSesion()),
      ),
    );
    await tester.pumpAndSettle();
    return contenedor;
  }

  Future<void> iniciarSesion(
    WidgetTester tester, {
    String documento = '40123456',
    String clave = 'higiene2026',
  }) async {
    await tester.enterText(find.byType(TextFormField).first, documento);
    await tester.enterText(find.byType(TextFormField).last, clave);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
  }

  testWidgets('sin sesión, la pantalla invita a iniciarla',
      (WidgetTester tester) async {
    await abrir(tester);

    expect(find.text('Sin sesión iniciada'), findsOneWidget);
    expect(find.text('Sesión activa'), findsNothing);
    expect(find.textContaining('almacén del sistema'), findsOneWidget);
  });

  testWidgets('con credenciales correctas la sesión queda activa',
      (WidgetTester tester) async {
    await abrir(tester);
    await iniciarSesion(tester);

    expect(find.text('Sesión activa'), findsOneWidget);
    expect(find.text('Rosa Quispe Huamán'), findsOneWidget);
    // El documento se muestra enmascarado.
    expect(find.text('****3456'), findsOneWidget);
    expect(find.textContaining('Token vigente'), findsOneWidget);
    // El dato del token se resume como "huella … · expira en …"; se busca el
    // sufijo para no confundirlo con el texto de la nota de seguridad.
    expect(find.textContaining('expira en'), findsOneWidget);
  });

  testWidgets('con credenciales incorrectas no se crea ninguna sesión',
      (WidgetTester tester) async {
    await abrir(tester);
    await iniciarSesion(tester, clave: 'clave-equivocada');

    expect(find.text('Sin sesión iniciada'), findsOneWidget);
    expect(find.text('Documento o clave incorrectos.'), findsOneWidget);
    expect(await almacen.claves(), isEmpty);
  });

  testWidgets('el valor del token NO se muestra en la pantalla',
      (WidgetTester tester) async {
    await abrir(tester);
    await iniciarSesion(tester);

    // La prueba conoce el token porque puede leerlo del repositorio…
    final Sesion? sesion = await getIt<SesionRepository>().leer();
    expect(sesion, isNotNull);

    // …y comprueba que en el árbol de widgets no aparece por ningún lado.
    expect(find.textContaining(sesion!.token.valor), findsNothing);
    expect(find.text(sesion.token.valor), findsNothing);
    // Solo se publica la huella.
    expect(find.textContaining(sesion.token.huella), findsOneWidget);
  });

  testWidgets('cerrar sesión vacía el almacén seguro',
      (WidgetTester tester) async {
    await abrir(tester);
    await iniciarSesion(tester);

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Cerrar sesión y borrar el token'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sin sesión iniciada'), findsOneWidget);
    expect(await almacen.claves(), isEmpty);
    expect(await getIt<SesionRepository>().leer(), isNull);
  });

  testWidgets('la interfaz reacciona a los cambios del provider',
      (WidgetTester tester) async {
    final ProviderContainer contenedor = await abrir(tester);
    await iniciarSesion(tester);

    // El estado lo cambia el NOTIFIER, no la pantalla: la interfaz lo refleja
    // porque observa `sesionProvider` con `ref.watch`.
    await contenedor.read(sesionCtrlProvider.notifier).cerrar();
    await tester.pumpAndSettle();

    expect(find.text('Sin sesión iniciada'), findsOneWidget);

    // Y al revés: si otra pantalla inicia sesión, esta se entera sola.
    await contenedor.read(sesionCtrlProvider.notifier).iniciar(
          documento: '41234567',
          clave: 'calidad2026',
        );
    await tester.pumpAndSettle();

    expect(find.text('Sesión activa'), findsOneWidget);
    expect(find.text('Luis Puma Condori'), findsOneWidget);
  });
}
