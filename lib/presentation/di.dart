import 'package:get_it/get_it.dart';

import '../data/local/conexion.dart';
import '../data/local/daos/auditorias_dao.dart';
import '../data/local/daos/indicadores_dao.dart';
import '../data/local/daos/preferencias_dao.dart';
import '../data/local/infraestructura.dart';
import '../data/local/manos_seguras_db.dart';
import '../data/local/sembrador.dart';
import '../data/remoto/higiene_api_service.dart';
import '../data/repositorios/auditoria_repository_drift.dart';
import '../data/repositorios/indicador_repository_offline_first.dart';
import '../data/repositorios/preferencias_repository_drift.dart';
import '../data/repositorios/sesion_repository_seguro.dart';
import '../data/seguro/almacen_seguro.dart';
import '../data/seguro/almacen_seguro_en_memoria.dart';
import '../data/seguro/almacen_seguro_sistema.dart';
import '../domain/repositorios/auditoria_repository.dart';
import '../domain/repositorios/indicador_repository.dart';
import '../domain/repositorios/sesion_repository.dart';
import '../domain/servicios/generador_token.dart';

/// **Contenedor de inyección de dependencias (get_it).**
///
/// Semana 9 — temática 2.1.6. Es el único archivo del proyecto que conoce
/// las clases concretas (`DriftAuditoriasDao`, `HigieneApiService`,
/// `ManosSegurasDb`) y las conecta entre sí. Todo lo demás pide
/// abstracciones: `getIt<AuditoriaRepository>()`.
///
/// ## El grafo de dependencias
///
/// ```
///   ManosSegurasDb  (singleton asíncrono)
///        ├── auditoriasDao   ──► AuditoriaRepositoryDrift      ──► AuditoriaRepository
///        ├── indicadoresDao  ──► IndicadorRepositoryOfflineFirst
///        │        ▲                        ▲
///        │        └── HigieneApiService ───┘
///        └── preferenciasDao ──► PreferenciasRepositoryDrift
/// ```
///
/// ## Reglas del contenedor que conviene respetar
///
///  1. **Una sola instancia de la base** (`registerLazySingletonAsync`).
///     Abrir dos conexiones al mismo archivo SQLite provoca bloqueos
///     (`database is locked`).
///  2. **Dependencias perezosas.** Los repositorios no se construyen hasta
///     que alguien los pide.
///  3. **Nada de estado global mutable.** [getIt] se expone como variable
///     global por comodidad didáctica; en una aplicación grande conviene
///     pasar el `GetIt` por constructor o usar un `InheritedWidget`.
///
/// ## Qué cambia en la Semana 12 (temática 2.3)
///
/// **Nada de este archivo construye estado.** Se retiraron de aquí las dos
/// clases que en las Semanas 10 y 11 vivían registradas como *singletons con
/// estado*: `TemaApp` y `GestorSesion`. Hoy ese estado lo administran los
/// `Notifier` de `presentation/providers/`, y `get_it` se queda con lo único
/// que le corresponde: **construir objetos**.
///
/// ```
///   get_it     → ¿quién construye cada objeto y con qué implementación?
///   Riverpod   → ¿quién observa el estado y cuándo se reconstruye la interfaz?
/// ```
///
/// Esa separación es la respuesta del proyecto a la pregunta «¿Riverpod
/// reemplaza a get_it?»: **no lo reemplaza, lo complementa**. `get_it` sigue
/// siendo el contenedor de composición (Semana 9) y Riverpod es la capa
/// reactiva (Semana 12). El puente entre ambos es
/// `presentation/providers/dependencias_providers.dart`.
final GetIt getIt = GetIt.instance;

/// Registra todas las dependencias de la aplicación.
///
/// Se llama una sola vez, desde `main()`, y **antes** de `runApp`.
Future<void> configurarDependencias({
  /// Permite sustituir la base de datos en las pruebas y en la demostración
  /// en memoria sin tocar el resto del grafo.
  Future<ManosSegurasDb> Function()? abrirBase,
  bool usarRespaldoLocal = false,

  /// **Semana 11.** Cuando es `true`, el token de sesión se guarda en un
  /// almacén en memoria en lugar del almacén del sistema operativo. Sirve
  /// para `flutter test` y para la demostración en un equipo sin Keystore ni
  /// llavero configurado.
  bool usarAlmacenEnMemoria = false,
}) async {
  if (getIt.isRegistered<ManosSegurasDb>() ||
      getIt.isRegistered<AlmacenSeguro>()) {
    await getIt.reset();
  }

  // --- Semana 11: almacén seguro de secretos --------------------------
  //
  // Se registra ANTES de la base de datos porque no depende de ella: el
  // token no vive en SQLite. Este es exactamente el punto del grafo donde
  // se decide *dónde* se guarda un dato sensible, y por eso es el único
  // lugar que hay que cambiar para pasar del almacén real al de pruebas.
  getIt.registerLazySingleton<AlmacenSeguro>(
    () => usarAlmacenEnMemoria
        ? AlmacenSeguroEnMemoria()
        : AlmacenSeguroSistema(),
  );

  // --- Capa de infraestructura: la base de datos ----------------------
  //
  // `registerLazySingletonAsync` acepta una función asíncrona; get_it
  // espera a que se complete antes de entregar la instancia a quien la
  // pida. Es lo que permite que `main()` haga `await getIt.allReady()`.
  //
  // TODO(reto-1a, mejora): agregue aquí el registro del sembrador de datos
  // (`SembradorDatos`) y de cualquier servicio nuevo que incorpore su
  // equipo, siempre **contra su interfaz del dominio**.
  //
  // La versión base registra la base local como singleton asíncrono.
  // `registerLazySingletonAsync` acepta una función asíncrona y get_it
  // espera a que se complete antes de entregar la instancia a quien la pida.
  getIt.registerLazySingletonAsync<ManosSegurasDb>(
    () => (abrirBase ?? abrirBaseDeDatos)(),
    dispose: (ManosSegurasDb base) => base.close(),
  );
}

/// Completa el grafo **después** de que la base está abierta.
///
/// Este método se entrega resuelto porque su patrón se repite en todas las
/// aplicaciones: cada DAO se construye sobre la MISMA instancia de la base y
/// cada repositorio se registra **contra su interfaz del dominio**, que es
/// la esencia del DIP de la Semana 9.
Future<void> _registrarRepositorios({
  required bool usarRespaldoLocal,
}) async {
  final ManosSegurasDb base = await getIt.getAsync<ManosSegurasDb>();
  final InfraestructuraLocal infra = InfraestructuraLocal(base);

  getIt
    ..registerSingleton<AuditoriasDao>(infra.auditoriasDao)
    ..registerSingleton<IndicadoresDao>(infra.indicadoresDao)
    ..registerSingleton<PreferenciasDao>(infra.preferenciasDao)
    ..registerSingleton<HigieneApiService>(
      HigieneApiService(usarRespaldoLocal: usarRespaldoLocal),
      dispose: (HigieneApiService servicio) => servicio.cerrar(),
    )
    ..registerLazySingleton<AuditoriaRepository>(
      () => AuditoriaRepositoryDrift(getIt<AuditoriasDao>()),
    )
    ..registerLazySingleton<IndicadorRepository>(
      () => IndicadorRepositoryOfflineFirst(
        dao: getIt<IndicadoresDao>(),
        servicio: getIt<HigieneApiService>(),
      ),
    )
    ..registerLazySingleton<PreferenciasRepository>(
      () => PreferenciasRepositoryDrift(getIt<PreferenciasDao>()),
    )
    ..registerLazySingleton<SembradorDatos>(
      () => SembradorDatos(
        base: base,
        repositorio: getIt<AuditoriaRepository>(),
      ),
    )
    // --- Semana 11: sesión y token seguro ------------------------------
    //
    // `SesionRepositorySeguro` recibe CUALQUIER `AlmacenSeguro`. En la
    // aplicación real es el adaptador de `flutter_secure_storage`; en las
    // pruebas, el almacén en memoria. El repositorio no cambia.
    ..registerLazySingleton<SesionRepository>(
      () => SesionRepositorySeguro(getIt<AlmacenSeguro>()),
    )
    ..registerLazySingleton<GeneradorTokenSimulado>(
      () => GeneradorTokenSimulado(),
    )
    ..registerLazySingleton<DirectorioUsuariosSimulado>(
      () => DirectorioUsuariosSimulado(),
    );
}

/// Atajo para `main()` y para las pruebas: configura, espera a que todo esté
/// listo y devuelve la base ya abierta.
Future<ManosSegurasDb> iniciarDependencias({
  Future<ManosSegurasDb> Function()? abrirBase,
  bool usarRespaldoLocal = false,
  bool usarAlmacenEnMemoria = false,
}) async {
  await configurarDependencias(
    abrirBase: abrirBase,
    usarRespaldoLocal: usarRespaldoLocal,
    usarAlmacenEnMemoria: usarAlmacenEnMemoria,
  );
  await getIt.allReady();
  await _registrarRepositorios(usarRespaldoLocal: usarRespaldoLocal);
  return getIt.get<ManosSegurasDb>();
}
