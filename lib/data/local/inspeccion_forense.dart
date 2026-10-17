import 'dart:io';
import 'dart:typed_data';

import 'conexion.dart';

/// **Inspección forense del archivo de la base de datos** (Semana 11).
///
/// Este archivo implementa la prueba que convierte la teoría en evidencia:
/// después de guardar un token, se recorre el archivo `manos_seguras.sqlite`
/// **byte a byte** buscando el valor del token. El resultado es inapelable:
///
/// | Escenario | Apariciones del token en el archivo |
/// |---|---|
/// | `SesionRepositoryInseguro` (tabla `preferencias`) | ≥ 1 → **hallazgo** |
/// | `SesionRepositorySeguro` (Keystore / Keychain) | 0 → **control eficaz** |
///
/// Se apoya en dos hechos que el estudiante debe comprender:
///
///  1. SQLite **no cifra** el contenido de sus tablas: los valores de texto
///     quedan en claro dentro del archivo (salvo que se use una extensión
///     como SQLCipher, que este proyecto no usa).
///  2. El almacén seguro **no escribe nada** en ese archivo: el token viaja
///     al Keystore de Android o al Keychain de Apple, que no son archivos
///     legibles por la aplicación.
///
/// Solo funciona en Android, iOS, macOS, Linux y Windows (necesita
/// `dart:io`). En web el archivo no existe como tal y la inspección se
/// reporta como no aplicable.
class ResultadoForense {
  const ResultadoForense({
    required this.ruta,
    required this.archivoExiste,
    required this.tamanoBytes,
    required this.apariciones,
  });

  /// Ruta del archivo inspeccionado.
  final String ruta;

  /// `false` si la base todavía no se creó en el dispositivo.
  final bool archivoExiste;

  /// Tamaño del archivo en bytes (0 si no existe).
  final int tamanoBytes;

  /// Cuántas veces aparece la aguja buscada dentro del archivo.
  final int apariciones;

  /// `true` si el dato sensible quedó expuesto en el archivo.
  bool get hayFuga => apariciones > 0;

  /// Veredicto listo para mostrar en pantalla y para pegar en el informe.
  String get veredicto => archivoExiste
      ? (hayFuga
          ? 'HALLAZGO: el dato aparece $apariciones vez/veces en texto plano '
              'dentro de ${_nombreArchivo()} ($tamanoBytes bytes).'
          : 'Control eficaz: el dato NO aparece en ${_nombreArchivo()} '
              '($tamanoBytes bytes inspeccionados).')
      : 'Todavía no existe el archivo ${_nombreArchivo()}. Genere datos '
          'primero.';

  String _nombreArchivo() {
    final int separador = ruta.lastIndexOf(Platform.pathSeparator);
    return separador >= 0 ? ruta.substring(separador + 1) : ruta;
  }
}

/// Busca [aguja] dentro del archivo de la base de datos local.
///
/// La comparación se hace sobre los bytes interpretados como texto. Como el
/// token y el JSON de la sesión son ASCII (base64url e ISO-8601), la
/// búsqueda es exacta y no produce falsos positivos.
Future<ResultadoForense> inspeccionarArchivoDeBase(String aguja) async {
  final String ruta = await rutaDeLaBaseDeDatos();
  final File archivo = File(ruta);

  if (!await archivo.exists()) {
    return ResultadoForense(
      ruta: ruta,
      archivoExiste: false,
      tamanoBytes: 0,
      apariciones: 0,
    );
  }

  final Uint8List bytes = await archivo.readAsBytes();
  return ResultadoForense(
    ruta: ruta,
    archivoExiste: true,
    tamanoBytes: bytes.length,
    apariciones: aguja.isEmpty
        ? 0
        : _contarApariciones(String.fromCharCodes(bytes), aguja),
  );
}

/// Cuenta cuántas veces aparece [aguja] dentro de [pajar].
///
/// Se implementa a mano —en lugar de usar una expresión regular— porque la
/// aguja es un texto arbitrario que podría contener caracteres con
/// significado especial en una regex (por ejemplo, el `+` de base64url).
int _contarApariciones(String pajar, String aguja) {
  int contador = 0;
  int desde = 0;
  while (true) {
    final int posicion = pajar.indexOf(aguja, desde);
    if (posicion < 0) return contador;
    contador++;
    desde = posicion + aguja.length;
  }
}
