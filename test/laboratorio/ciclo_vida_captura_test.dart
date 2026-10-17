import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manos_seguras/presentation/providers/captura_provider.dart';
import 'package:manos_seguras/presentation/providers/dependencias_providers.dart';
import '../dobles/preferencias_en_memoria.dart';
import 'captura_temporal.dart';

void main() {
  for (final temporal in [false, true]) {
    test(
      temporal
          ? 'autoDispose pierde el borrador tras cerrar su último oyente'
          : 'keepAlive conserva el borrador tras cerrar su último oyente',
      () async {
        final c = ProviderContainer.test(
          overrides: [
            preferenciasRepositoryProvider.overrideWithValue(
              PreferenciasEnMemoria(),
            ),
          ],
        );
        final provider = temporal ? capturaTemporalProvider : capturaProvider;
        final sub = c.listen<EstadoCaptura>(provider, (_, _) {});
        if (temporal) {
          c.read(capturaTemporalProvider.notifier).agregar();
        } else {
          c.read(capturaProvider.notifier).agregar();
        }
        expect(c.read(provider).oportunidades, hasLength(1));
        sub.close();
        await c.pump();
        expect(c.read(provider).oportunidades, hasLength(temporal ? 0 : 1));
        await c.pump();
      },
    );
  }
}
