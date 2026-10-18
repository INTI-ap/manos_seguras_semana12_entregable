import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'comparacion_captura.dart';

void main() {
  test('la regla Riverpod se prueba sin montar interfaz', () {
    final c = ProviderContainer.test();
    c.read(contadorCapturaProvider.notifier).agregar();
    expect(c.read(contadorCapturaProvider), 1);
  });
  for (final riverpod in [false, true]) {
    testWidgets(
      'agregar muestra el mismo resultado con ${riverpod ? "Riverpod" : "setState"}',
      (t) async {
        await t.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: riverpod
                    ? const CapturaConRiverpod()
                    : const CapturaConSetState(),
              ),
            ),
          ),
        );
        await t.tap(find.text('Oportunidades: 0'));
        await t.pump();
        expect(find.text('Oportunidades: 1'), findsOneWidget);
      },
    );
  }
}
