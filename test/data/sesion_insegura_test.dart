import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:manos_seguras/data/local/conexion.dart';
import 'package:manos_seguras/data/local/daos/preferencias_dao.dart';
import 'package:manos_seguras/data/local/manos_seguras_db.dart';
import 'package:manos_seguras/data/repositorios/sesion_repository_inseguro.dart';
import 'package:manos_seguras/data/repositorios/sesion_repository_seguro.dart';
import 'package:manos_seguras/data/seguro/almacen_seguro_en_memoria.dart';
import 'package:manos_seguras/domain/entidades/sesion.dart';
import 'package:manos_seguras/domain/servicios/generador_token.dart';

/// **Prueba automatizada de la fuga de datos (base del Reto 5).**
///
/// Es la traducción a código de la demostración forense de la guía: guarda el
/// mismo tipo de token con las dos implementaciones del repositorio y busca
/// el valor dentro de los **bytes reales** del archivo SQLite.
///
/// La prueba corre en CI sin emulador, así que la evidencia no depende de que
/// alguien recuerde tomar una captura: el equipo puede demostrar, en cada
/// `flutter test`, que:
///
///  1. el token guardado con [SesionRepositoryInseguro] **sí** aparece en el
///     archivo (debilidad MASWE-0001);
///  2. el token guardado con [SesionRepositorySeguro] **no** aparece
///     (control MASVS-STORAGE-1 satisfecho).
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory carpeta;
  late String ruta;
  late ManosSegurasDb base;
  late PreferenciasDao preferencias;

  Sesion sesionDePrueba(String marca) {
    final TokenSesion token =
        GeneradorTokenSimulado().emitir(ahora: DateTime.utc(2026, 11, 4));
    return Sesion(
      documento: '40123456',
      nombre: 'Rosa Quispe Huamán',
      rol: RolUsuario.observador,
      token: TokenSesion(
        valor: 'prueba_${marca}_${token.valor}',
        emitidoEn: token.emitidoEn,
        expiraEn: token.expiraEn,
      ),
    );
  }

  /// Lee el archivo una vez cerrada la base, para que SQLite haya volcado
  /// todo su contenido a disco.
  Future<String> leerArchivo() async {
    await base.close();
    return String.fromCharCodes(await File(ruta).readAsBytes());
  }

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('manos_seguras_semana11');
    ruta = '${carpeta.path}${Platform.pathSeparator}manos_seguras.sqlite';
    base = abrirBaseDeDatosDeArchivo(ruta);
    preferencias = DriftPreferenciasDao(base);
    // Fuerza la apertura y la creación del archivo: drift abre la base de
    // forma perezosa, y sin esta lectura el archivo todavía no existiría en
    // la segunda prueba.
    await preferencias.leerTodo();
  });

  tearDown(() async {
    try {
      await base.close();
    } catch (_) {
      // La prueba ya la cerró para leer el archivo: cerrar dos veces no es
      // un error que deba hacer fallar la limpieza.
    }
    await carpeta.delete(recursive: true);
  });

  test('el token del repositorio inseguro queda en texto plano en la tabla '
      'preferencias', () async {
    final Sesion sesion = sesionDePrueba('A');
    await SesionRepositoryInseguro(preferencias).guardar(sesion);

    // 1) La propia aplicación puede volver a leerlo tal cual.
    final String? crudo =
        await preferencias.leer(SesionRepositoryInseguro.claveSesion);
    expect(crudo, isNotNull);
    expect(crudo!, contains(sesion.token.valor));

    // 2) Y está dentro de los bytes del archivo, sin cifrar.
    final String archivo = await leerArchivo();
    expect(archivo, contains(sesion.token.valor));
    expect(archivo, contains('40123456'));
  });

  test('el token del repositorio seguro no aparece en el archivo SQLite',
      () async {
    final Sesion sesion = sesionDePrueba('B');
    final AlmacenSeguroEnMemoria almacen = AlmacenSeguroEnMemoria();

    // El repositorio seguro escribe en el almacén del sistema (en la prueba,
    // en memoria); la base de datos ni se entera.
    await SesionRepositorySeguro(almacen).guardar(sesion);

    final String archivo = await leerArchivo();
    expect(archivo, isNot(contains(sesion.token.valor)));
    expect(archivo, isNot(contains('40123456')));

    // El dato sí está donde corresponde: en el almacén seguro.
    expect(await almacen.contiene(SesionRepositorySeguro.claveSesion), isTrue);
  });

  test('borrar la fila no es suficiente: el rastro desaparece tras VACUUM',
      () async {
    final Sesion sesion = sesionDePrueba('C');
    final SesionRepositoryInseguro repositorio =
        SesionRepositoryInseguro(preferencias);

    await repositorio.guardar(sesion);
    await repositorio.cerrar();

    // Tras el borrado lógico, la aplicación ya no lee el dato…
    expect(
      await preferencias.leer(SesionRepositoryInseguro.claveSesion),
      isNull,
    );

    // …pero los bytes pueden seguir en páginas libres del archivo hasta que
    // SQLite compacte la base. Esta es la lección: "borrado" no es "borrado
    // seguro" en una base de datos que no cifra.
    await base.customStatement('VACUUM');

    final String archivo = await leerArchivo();
    expect(archivo, isNot(contains(sesion.token.valor)));
  });
}
