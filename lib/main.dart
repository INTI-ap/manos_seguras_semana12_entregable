import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/observador_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'data/local/sembrador.dart';
import 'domain/entidades/auditoria.dart';
import 'domain/repositorios/auditoria_repository.dart';
import 'presentation/di.dart';
import 'presentation/providers/sesion_provider.dart';
import 'presentation/providers/tema_provider.dart';
import 'presentation/widgets/app_layout.dart';
import 'router/app_router.dart';

/// Si vale `true`, la aplicación guarda el token de sesión en memoria en
/// lugar del almacén del sistema operativo.
///
/// Se activa desde la línea de comandos, sin tocar el código:
///
/// ```bash
/// flutter run --dart-define=ALMACEN_EN_MEMORIA=true
/// ```
const bool _usarAlmacenEnMemoria = bool.fromEnvironment('ALMACEN_EN_MEMORIA');

/// Punto de entrada de ManosSeguras.
///
/// **Semana 12 — el arranque ahora también construye el `ProviderContainer`.**
///
/// El orden de esta función es parte de la arquitectura y conviene leerlo con
/// cuidado, porque cambió respecto de la Semana 11:
///
/// ```
///  1. ensureInitialized()        → obligatorio antes de usar plugins
///  2. iniciarDependencias()      → abre SQLite y arma el grafo de get_it
///  3. ProviderContainer()        → crea el contenedor de Riverpod
///  4. cargar la preferencia tema → temaProvider.cargarDesdeDisco()
///  5. restaurar la sesión        → sesionCtrlProvider.restaurar()
///  6. sembrar datos si está vacía
///  7. runApp(UncontrolledProviderScope(...))
/// ```
///
/// ## ¿Por qué `ProviderContainer` a mano y no `ProviderScope`?
///
/// Porque los pasos 4 y 5 son asíncronos y deben estar **terminados** antes
/// del primer fotograma: si la aplicación dibujara antes, el usuario vería un
/// destello del tema equivocado y un instante de "sin sesión" antes de que el
/// token se restaure.
///
/// La forma de conseguirlo sin `setState` ni pantallas de carga intermedias
/// es crear el contenedor a mano, **completar el estado antes de `runApp`** y
/// entregárselo al árbol con `UncontrolledProviderScope`. Es la técnica
/// documentada para *inicialización temprana* de providers y también la que
/// usan las pruebas, que construyen su propio `ProviderContainer`.
///
/// Si el paso 2 falla, la aplicación no puede continuar: no hay forma de
/// mostrar datos sin base de datos. Por eso el arranque se envuelve en un
/// `try/catch` que muestra una pantalla de error comprensible (patrón
/// *fail fast with a friendly message*) en lugar de dejar la pantalla en blanco.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await iniciarDependencias(usarAlmacenEnMemoria: _usarAlmacenEnMemoria);

    final ProviderContainer contenedor = ProviderContainer(
      // El observador deja en la consola del editor la traza de qué provider
      // se construyó y cuándo cambió. Es la herramienta de depuración que
      // reemplaza a los `print` sueltos.
      observers: <ProviderObserver>[RegistroDeProviders()],
    );

    // Paso 4. El provider se inicializa a sí mismo cuando alguien se lo pide.
    await contenedor.read(temaProvider.notifier).cargarDesdeDisco();
    // Paso 5. `restaurar()` nunca lanza: si el almacén seguro no está
    // disponible o el dato guardado es ilegible, deja la aplicación sin
    // sesión en lugar de impedir el arranque.
    await contenedor.read(sesionCtrlProvider.notifier).restaurar();

    await _sembrarSiEsPrimerArranque();

    runApp(
      UncontrolledProviderScope(
        container: contenedor,
        child: const ManosSegurasApp(),
      ),
    );
  } catch (error, pila) {
    debugPrint('Falló el arranque de ManosSeguras: $error\n$pila');
    runApp(_PantallaFalloDeArranque(mensaje: '$error'));
  }
}

/// Siembra datos de demostración la primera vez que se abre la aplicación,
/// para que las pantallas de auditorías y de diagnóstico tengan contenido.
///
/// **Decisión documentada:** este comportamiento es aceptable en un proyecto
/// de laboratorio, pero en producción debe quedar detrás de una bandera de
/// compilación (`--dart-define=DEMO=true`) o eliminarse. Es un ejemplo de
/// decisión de diseño que el informe técnico debe registrar.
Future<void> _sembrarSiEsPrimerArranque() async {
  final AuditoriaRepository repositorio = getIt<AuditoriaRepository>();
  final List<Auditoria> existentes = await repositorio.listarAuditorias();
  if (existentes.isNotEmpty) return;

  final SembradorDatos sembrador = getIt<SembradorDatos>();
  await sembrador.limpiar();
  await sembrador.sembrar(cantidad: 3);
}

/// Raíz de la aplicación.
///
/// **Semana 12:** pasa de `StatelessWidget` a `ConsumerWidget`. El cambio no
/// es cosmético: el widget ya no recibe el `ThemeMode` desde un
/// `ValueListenableBuilder`, sino que lo **observa** con `ref.watch`. Cuando
/// cualquier parte de la aplicación cambie el tema, este `build` se vuelve a
/// ejecutar y **solo** él: no se reconstruye el grafo de `get_it` ni se vuelve
/// a abrir la base de datos.
class ManosSegurasApp extends ConsumerWidget {
  const ManosSegurasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode modoActual = ref.watch(temaProvider);

    return MaterialApp.router(
      title: 'ManosSeguras',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: modoActual,
      // Toda la navegación vive en un único lugar (Sesión 15).
      routerConfig: appRouter,
    );
  }
}

/// Pantalla que se muestra si el arranque falla (por ejemplo, si la base de
/// datos local no puede abrirse). Evita la pantalla en blanco y ofrece un
/// diagnóstico mínimo.
class _PantallaFalloDeArranque extends StatelessWidget {
  const _PantallaFalloDeArranque({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: Scaffold(
        appBar: AppBar(title: const Text('ManosSeguras')),
        body: AppLayout(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.storage_rounded,
                  size: 56,
                  color: AppColors.alerta,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo abrir la base de datos local',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
