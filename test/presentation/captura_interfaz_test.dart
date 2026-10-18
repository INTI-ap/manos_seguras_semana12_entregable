import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manos_seguras/presentation/pantallas/pantalla_bienvenida.dart';
import 'package:manos_seguras/presentation/pantallas/pantalla_oportunidades.dart';
import 'package:manos_seguras/presentation/providers/captura_provider.dart';
import 'package:manos_seguras/presentation/providers/dependencias_providers.dart';
import '../dobles/preferencias_en_memoria.dart';
import '../dobles/repositorio_auditorias_en_memoria.dart';

void main() {
  late ProviderContainer c;
  late GoRouter router;
  late RepositorioAuditoriasEnMemoria a;
  setUp(() {
    a = RepositorioAuditoriasEnMemoria();
    c = ProviderContainer(
      overrides: [
        auditoriaRepositoryProvider.overrideWithValue(a),
        preferenciasRepositoryProvider.overrideWithValue(
          PreferenciasEnMemoria(),
        ),
      ],
    );
    router = GoRouter(
      initialLocation: '/oportunidades',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const PantallaBienvenida()),
        GoRoute(
          path: '/oportunidades',
          builder: (_, _) => const PantallaOportunidades(),
        ),
      ],
    );
  });
  tearDown(() {
    router.dispose();
    c.dispose();
  });
  Future<void> abrir(WidgetTester t) async {
    t.view.physicalSize = const Size(800, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets(
    'el inicio comparte el borrador y continuar abre la misma captura',
    (t) async {
      await abrir(t);
      await t.tap(find.text('Agregar oportunidad 01'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Volver al inicio'));
      await t.pumpAndSettle();
      final continuar = find.text('Continuar el borrador (1 oportunidades)');
      expect(continuar, findsOneWidget);
      await t.ensureVisible(continuar);
      await t.pumpAndSettle();
      await t.tap(continuar);
      await t.pumpAndSettle();
      expect(find.text('Oportunidades registradas (1)'), findsOneWidget);
      expect(c.read(capturaProvider).siguienteNumero, 2);
    },
  );
  testWidgets('cancelar descarte conserva y confirmar elimina el borrador', (
    t,
  ) async {
    await abrir(t);
    await t.tap(find.text('Agregar oportunidad 01'));
    await t.pumpAndSettle();
    final descartar = find.text('Descartar borrador');
    await t.ensureVisible(descartar);
    await t.pumpAndSettle();
    await t.tap(descartar);
    await t.pumpAndSettle();
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(c.read(capturaProvider).hayDatos, isTrue);
    await t.tap(descartar);
    await t.pumpAndSettle();
    await t.tap(find.text('Descartar'));
    await t.pumpAndSettle();
    expect(c.read(capturaProvider).hayDatos, isFalse);
  });
  testWidgets('fallo de guardado informa y conserva la oportunidad visible', (
    t,
  ) async {
    a.falla = true;
    await abrir(t);
    await t.tap(find.text('Agregar oportunidad 01'));
    await t.pumpAndSettle();
    final guardar = find.text('Guardar auditoría en el dispositivo');
    await t.ensureVisible(guardar);
    await t.pumpAndSettle();
    await t.tap(guardar);
    await t.pumpAndSettle();
    expect(find.textContaining('El borrador se conserva.'), findsOneWidget);
    expect(find.text('Oportunidades registradas (1)'), findsOneWidget);
    expect(c.read(capturaProvider).hayDatos, isTrue);
  });
}
