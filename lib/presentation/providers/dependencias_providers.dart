import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/daos/auditorias_dao.dart';
import '../../data/local/daos/indicadores_dao.dart';
import '../../data/local/daos/preferencias_dao.dart';
import '../../data/local/manos_seguras_db.dart';
import '../../data/local/sembrador.dart';
import '../../data/seguro/almacen_seguro.dart';
import '../../domain/repositorios/auditoria_repository.dart';
import '../../domain/repositorios/indicador_repository.dart';
import '../../domain/repositorios/sesion_repository.dart';
import '../../domain/servicios/generador_token.dart';
import '../di.dart';

/// **Semana 12 · temática 2.3.2 — providers simples.**
///
/// Este archivo es el **puente** entre el grafo de `get_it` que el equipo
/// construyó en la Semana 9 y el mundo de Riverpod. No reemplaza la inyección
/// de dependencias: la **publica** dentro del contenedor de Riverpod para que
/// los widgets dejen de llamar a `getIt<...>()` a mano.
///
/// ```
///   get_it (Semana 9)                 Riverpod (Semana 12)
///   ─────────────────                 ────────────────────
///   getIt<AuditoriaRepository>()  ──►  ref.watch(auditoriaRepositoryProvider)
///   getIt<PreferenciasRepository>() ─► ref.watch(preferenciasRepositoryProvider)
/// ```
///
/// ## ¿Por qué está escrito a mano y no con `@riverpod`?
///
/// Porque **no tiene estado propio**: es una proyección del contenedor. La
/// documentación oficial reserva la generación de código para los providers
/// que sí tienen lógica (notifiers, `family`, `autoDispose`). Un `Provider`
/// de una sola línea se lee mejor escrito a mano.
///
/// ## Regla que NO se puede romper
///
/// Un provider **nunca** debe construir dependencias por su cuenta: si
/// `auditoriaRepositoryProvider` hiciera `AuditoriaRepositoryDrift(...)`
/// directamente, el grafo de la Semana 9 quedaría duplicado y las pruebas
/// dejarían de poder sustituir los dobles. Aquí solo se **lee** `getIt`.
///
/// ## `getIt` debe estar configurado antes
///
/// `main()` llama a `iniciarDependencias()` antes de `runApp`, y las pruebas
/// hacen lo mismo en `setUp`. Si alguien olvida ese paso, Riverpod lanza el
/// error de `get_it` ("Object/factory … is not registered"), que es
/// exactamente el diagnóstico que se quiere: un fallo de arranque explícito.
final Provider<AuditoriaRepository> auditoriaRepositoryProvider =
    Provider<AuditoriaRepository>(
  (Ref ref) => getIt<AuditoriaRepository>(),
  name: 'auditoriaRepository',
);

final Provider<IndicadorRepository> indicadorRepositoryProvider =
    Provider<IndicadorRepository>(
  (Ref ref) => getIt<IndicadorRepository>(),
  name: 'indicadorRepository',
);

final Provider<PreferenciasRepository> preferenciasRepositoryProvider =
    Provider<PreferenciasRepository>(
  (Ref ref) => getIt<PreferenciasRepository>(),
  name: 'preferenciasRepository',
);

final Provider<SesionRepository> sesionRepositoryProvider =
    Provider<SesionRepository>(
  (Ref ref) => getIt<SesionRepository>(),
  name: 'sesionRepository',
);

final Provider<AlmacenSeguro> almacenSeguroProvider = Provider<AlmacenSeguro>(
  (Ref ref) => getIt<AlmacenSeguro>(),
  name: 'almacenSeguro',
);

final Provider<GeneradorTokenSimulado> generadorTokenProvider =
    Provider<GeneradorTokenSimulado>(
  (Ref ref) => getIt<GeneradorTokenSimulado>(),
  name: 'generadorToken',
);

final Provider<DirectorioUsuariosSimulado> directorioUsuariosProvider =
    Provider<DirectorioUsuariosSimulado>(
  (Ref ref) => getIt<DirectorioUsuariosSimulado>(),
  name: 'directorioUsuarios',
);

final Provider<PreferenciasDao> preferenciasDaoProvider =
    Provider<PreferenciasDao>(
  (Ref ref) => getIt<PreferenciasDao>(),
  name: 'preferenciasDao',
);

/// **Reto 1 (2 puntos): publicación completa del grafo de infraestructura.**
///
/// Publica la instancia de la base de datos SQLite y el sembrador de datos,
/// permitiendo su consumo reactivo o en operaciones de fondo sin saltarse
/// la arquitectura de providers ni duplicar instanciaciones.
final Provider<ManosSegurasDb> manosSegurasDbProvider =
    Provider<ManosSegurasDb>(
  (Ref ref) => getIt<ManosSegurasDb>(),
  name: 'manosSegurasDb',
);

final Provider<SembradorDatos> sembradorDatosProvider =
    Provider<SembradorDatos>(
  (Ref ref) => getIt<SembradorDatos>(),
  name: 'sembradorDatos',
);

final Provider<AuditoriasDao> auditoriasDaoProvider = Provider<AuditoriasDao>(
  (Ref ref) => getIt<AuditoriasDao>(),
  name: 'auditoriasDao',
);

final Provider<IndicadoresDao> indicadoresDaoProvider =
    Provider<IndicadoresDao>(
  (Ref ref) => getIt<IndicadoresDao>(),
  name: 'indicadoresDao',
);
