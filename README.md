# ManosSeguras — Semana 12: Gestión de Estado Avanzada con Riverpod

Proyecto Flutter del **proyecto integrador** de **SIS048 – Desarrollo de Software II**
(Universidad Andina del Cusco, semestre 2026-II), correspondiente a la
**Unidad de Aprendizaje II: Arquitectura Limpia, Persistencia y Gestión de
Estado Avanzada**.

Esta entrega implementa la **Guía de Aplicación N.° 08 · Parte I** (Semana 12)
y continúa exactamente donde terminó la Semana 11:

| Temática del sílabo | Qué se implementa aquí |
|---|---|
| 2.3.1. ¿Por qué Riverpod? Provider vs Riverpod: motivación | `presentation/providers/dependencias_providers.dart` (puente get_it → Riverpod) y `pantalla_bienvenida.dart` (estado compartido entre pantallas). |
| 2.3.2. Providers simples y generación de código con `@riverpod` | `tema_provider.dart`, `captura_provider.dart`, `sesion_provider.dart` + `riverpod_annotation`, `riverpod_generator` y `build_runner`. |
| 2.3.3. `Notifier`: migración de la Lista de Tareas | `captura_provider.dart`: los seis campos de `setState` de `/oportunidades` se convierten en un `EstadoCaptura` inmutable con un `Notifier`. |
| Repaso 2.1.6 (Semana 9) | `get_it` sigue siendo el contenedor de composición; Riverpod se limita a publicar y observar. |
| Repaso 2.2.5 (Semana 11) | El token sigue en `flutter_secure_storage`; lo que cambia es cómo la interfaz observa la sesión. |

**Actividades de aprendizaje del sílabo:** *"Comparan setState vs Riverpod en
un mismo caso de uso"* y *"Crean sus primeros providers con Riverpod"* — la
primera se cumple con la comparación lado a lado del §9 de la teoría y con la
tabla «antes / ahora» de cada archivo migrado; la segunda, con los tres
notifiers y los ocho providers simples del proyecto.

---

## Los retos de la Semana 12

Cada reto tiene su punto de partida en el código, marcado con
`TODO(reto-n)` y con el detalle en la guía de aplicación.

| Reto | Tema | Archivos de partida |
|---|---|---|
| 1 | Publicar el resto del grafo de `get_it` y migrar una pantalla adicional | `presentation/providers/dependencias_providers.dart` |
| 1b/1c | Política de fallo al guardar y al leer la preferencia de tema | `presentation/providers/tema_provider.dart` |
| 2 | `autoDispose` vs `keepAlive`: demostrar la diferencia con una prueba | `presentation/providers/captura_provider.dart` |
| 3 | Adelantar el `AsyncNotifier` de la Semana 13 y comparar | `presentation/providers/sesion_provider.dart` |
| 4 | `family`: un provider parametrizado por año (indicadores) | `presentation/pantallas/pantalla_indicador_detalle.dart` |
| 5 | Observador de providers y contadores en `/diagnostico` | `core/observador_riverpod.dart` |

---

## Cómo ejecutarlo

```bash
flutter --version                   # verificado con Flutter 3.44.9 / Dart 3.12.2
flutter create .                    # genera las carpetas android/, ios/, web/…
flutter pub get
dart run build_runner build         # genera drift + los providers de @riverpod
flutter run
```

> **Esta entrega no modifica el esquema de la base de datos.** No hay tablas
> nuevas ni cambios de `schemaVersion`: el estado de la interfaz no es un dato
> que deba persistirse en SQLite. Prueba de ello: al ejecutar
> `dart run build_runner build`, `lib/data/local/manos_seguras_db.g.dart`
> queda **idéntico** (se puede comprobar con `git diff`). El único código
> nuevo que produce el generador es `lib/presentation/providers/*.g.dart`.

Para la demostración sin depender del llavero del equipo:

```bash
flutter run --dart-define=ALMACEN_EN_MEMORIA=true
```

---

## Verificación reproducible

```bash
./scripts/verificar.sh
```

Salida esperada al 15 de octubre de 2026:

```
flutter analyze --fatal-infos   →  No issues found!
flutter test                    →  135 pruebas en verde (1 omitida)
```

La única prueba omitida es la que depende de un `Secret Service` real en el
escritorio (`skip:` documentado en su propio archivo); no es un fallo.

---

## El tren de versiones de Riverpod (dato verificado, no copiado)

| Paquete | Versión fijada | Fecha de publicación |
|---|---|---|
| `flutter_riverpod` | 3.4.3 | 2026-09-03 |
| `riverpod` (transitiva) | 3.4.3 | 2026-09-03 |
| `riverpod_annotation` | 4.0.7 | 2026-09-03 |
| `riverpod_generator` | 4.0.9 | 2026-09-03 |
| `build_runner` | 2.15.1 | — |

Dos advertencias que casi todo el material de Internet no recoge:

1. **`riverpod_annotation` va por la rama 4.x mientras `riverpod` va por la
   3.x.** No son la misma línea de versiones: mezclarlas «a ojo» rompe la
   resolución de dependencias.
2. **`riverpod_lint` no se puede instalar en este laboratorio.** La 3.1.9
   exige Dart `>=3.13.0-0` y el SDK disponible es 3.12.2; la 3.1.8, que sí
   acepta 3.12, fija `riverpod 3.4.2`, incompatible con `flutter_riverpod`
   3.4.3. Se documenta la limitación en lugar de fingir que el lint está
   activo. Desde la versión 3.1.6, además, `riverpod_lint` **ya no usa
   `custom_lint`**: se declara en `analysis_options.yaml` y lo ejecuta
   `dart analyze`.

---

## Trazabilidad de fuentes

Todo dato técnico de los documentos y de los comentarios del código proviene
de una fuente consultada realmente el **15 de octubre de 2026** y registrada
en `../fuentes/Fuentes_Verificadas_Semana12.md`, con URL y cita textual.


## Persona 2: captura de oportunidades

El borrador vive en `capturaProvider`, con `keepAlive: true`, y las pantallas lo observan con `ref.watch`. Volver al inicio o consultar el catálogo no descarta el trabajo. Esto conserva el estado dentro del mismo `ProviderContainer`; no escribe el borrador a disco ni lo restaura después de terminar el proceso.

`EstadoCaptura.inicial()` es constante. El constructor para estados con datos copia la lista en una lista no modificable; `copyWith` conserva la misma protección. Esta separación evita que una lista externa modifique retroactivamente el estado. La igualdad y el hash comparan los campos de cada oportunidad, sin cambiar las entidades del dominio.

La pantalla permite agregar, quitar, guardar y confirmar el descarte. Quitar no renumera ni reutiliza el correlativo. Mientras se guarda, el notifier rechaza llamadas simultáneas y cambios del borrador. Si el repositorio falla, conserva las oportunidades y la acción para reintentar. Si SQLite confirma y después falla la preferencia, devuelve éxito y vacía el borrador: repetir el guardado de una auditoría ya confirmada produciría duplicados.

`test/laboratorio/comparacion_captura.dart` implementa el mismo contador de oportunidades con setState y Notifier; sus pruebas comprueban el mismo resultado visible y una regla sin widgets. `captura_temporal.dart` replica las operaciones de captura cambiando únicamente su ciclo de vida a autoDispose. Las pruebas contrastan la pérdida del borrador con la conservación del provider real al cerrar el último oyente. El laboratorio no se incluye en las rutas del APK.

Validación de Persona 2: 17 pruebas nuevas (9 de regresión sin widgets, 3 de interfaz, 3 de comparación y 2 de ciclo de vida). Las pruebas originales de captura siguen verificando las reglas obligatorias. No se cambia el esquema SQLite ni la implementación de sesión y tema. Android se prepara con el endurecimiento de Semana 11 y un ID de aplicación separado para evitar reemplazar la instalación anterior.

Comandos de validación:

```text
dart run build_runner build
flutter analyze --fatal-infos --no-pub
flutter test --no-pub --reporter compact
flutter build apk --debug --no-pub
```

Las imágenes reales y las salidas literales de terminal se entregan fuera del repositorio. En Semana 12 las salidas de análisis y pruebas se insertan como texto en la sección 8, no como imágenes de terminal.
