#!/usr/bin/env bash
#
# Verificación completa del proyecto de la Semana 12.
#
#   ./scripts/verificar.sh
#
# El script reproduce exactamente lo que ejecuta el pipeline de GitHub Actions
# definido en ../.github/workflows/flutter-semana12.yml, para que el estudiante
# pueda comprobarlo antes de hacer commit.
#
# Novedades de la Semana 12:
#   * el paso 3 ejecuta `build_runner`, que ahora genera DOS cosas: el código
#     de drift (Semana 10) y los providers de Riverpod (`*.g.dart`) a partir de
#     las anotaciones `@riverpod`. Si el paso produce cambios inesperados en
#     los archivos versionados, hay que revisarlos antes del commit;
#   * el paso 5 ejecuta toda la batería, que ahora incluye las pruebas de los
#     notifiers SIN interfaz (`test/presentation/*_provider_test.dart`) y la
#     prueba forense de la Semana 11 (`test/data/sesion_insegura_test.dart`).

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> 1/5  Versiones"
flutter --version

echo "==> 2/5  Dependencias"
flutter pub get

echo "==> 3/5  Código generado (drift + Riverpod)"
# No hay tablas nuevas en la Semana 12: el estado de la interfaz NO se guarda
# en SQLite. Este paso debe dejar lib/data/local/manos_seguras_db.g.dart
# idéntico y solo puede escribir en lib/presentation/providers/*.g.dart.
dart run build_runner build

echo "==> 4/5  Análisis estático"
flutter analyze --fatal-infos

echo "==> 5/5  Pruebas (providers + evidencia forense de la Semana 11)"
flutter test --reporter expanded

echo
echo "Verificación completada sin errores."
echo "Pruebas de los notifiers: test/presentation/*_provider_test.dart"
echo "Evidencia forense (Semana 11): test/data/sesion_insegura_test.dart"
