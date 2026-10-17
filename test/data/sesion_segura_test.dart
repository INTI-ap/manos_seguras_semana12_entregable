import 'package:flutter_test/flutter_test.dart';
import 'package:manos_seguras/core/fallos.dart';
import 'package:manos_seguras/data/repositorios/sesion_repository_seguro.dart';
import 'package:manos_seguras/data/seguro/almacen_seguro_en_memoria.dart';
import 'package:manos_seguras/domain/entidades/sesion.dart';
import 'package:manos_seguras/domain/servicios/generador_token.dart';

/// **Pruebas del repositorio de sesión sobre el almacén seguro.**
///
/// Semana 11. Sustituyen el plugin por [AlmacenSeguroEnMemoria]: la prueba
/// corre en cualquier equipo, sin emulador y sin llavero, y comprueba el
/// comportamiento del repositorio (que es lo que el equipo escribió), no el
/// del plugin (que ya está probado por sus autores).
void main() {
  late AlmacenSeguroEnMemoria almacen;
  late SesionRepositorySeguro repositorio;

  Sesion sesionVigente() => Sesion(
        documento: '40123456',
        nombre: 'Rosa Quispe Huamán',
        rol: RolUsuario.observador,
        token: GeneradorTokenSimulado().emitir(ahora: DateTime.now().toUtc()),
      );

  /// Token emitido ayer y vencido hace una hora. Se calcula respecto del
  /// reloj real —y no con una fecha fija— para que la prueba siga siendo
  /// válida en cualquier fecha en que se ejecute.
  Sesion sesionVencida() {
    final DateTime ahora = DateTime.now().toUtc();
    return Sesion(
      documento: '40123456',
      nombre: 'Rosa Quispe Huamán',
      rol: RolUsuario.observador,
      token: TokenSesion(
        valor: 'ms_sim_token_vencido',
        emitidoEn: ahora.subtract(const Duration(days: 1)),
        expiraEn: ahora.subtract(const Duration(hours: 1)),
      ),
    );
  }

  setUp(() {
    almacen = AlmacenSeguroEnMemoria();
    repositorio = SesionRepositorySeguro(almacen);
  });

  group('ciclo de vida', () {
    test('sin nada guardado, leer devuelve null', () async {
      expect(await repositorio.leer(), isNull);
      expect(await repositorio.haySesionActiva(), isFalse);
    });

    test('guardar y leer reconstruyen la sesión completa', () async {
      final Sesion original = sesionVigente();

      await repositorio.guardar(original);
      final Sesion? recuperada = await repositorio.leer();

      expect(recuperada, isNotNull);
      expect(recuperada!.documento, original.documento);
      expect(recuperada.rol, original.rol);
      expect(recuperada.token, original.token);
    });

    test('guardar dos veces no duplica: sobrescribe la clave', () async {
      await repositorio.guardar(sesionVigente());
      await repositorio.guardar(sesionVigente());

      expect(await almacen.claves(), <String>{
        SesionRepositorySeguro.claveSesion,
      });
      expect(almacen.escriturasRealizadas, 2);
    });

    test('cerrar elimina el token del almacén', () async {
      await repositorio.guardar(sesionVigente());

      await repositorio.cerrar();

      expect(await repositorio.leer(), isNull);
      expect(await almacen.contiene(SesionRepositorySeguro.claveSesion),
          isFalse);
      expect(await almacen.claves(), isEmpty);
    });
  });

  group('expiración', () {
    test('una sesión vigente se considera activa', () async {
      await repositorio.guardar(sesionVigente());

      expect(await repositorio.haySesionActiva(), isTrue);
    });

    test('una sesión vencida no está activa y se borra del almacén',
        () async {
      await repositorio.guardar(sesionVencida());

      expect(await repositorio.haySesionActiva(), isFalse);
      // El token vencido no se conserva: dejarlo guardado es basura y
      // amplía la superficie de ataque (MASWE-0024).
      expect(await almacen.claves(), isEmpty);
    });
  });

  group('contenido corrupto', () {
    test('un dato ilegible produce FalloDeValidacion', () async {
      await almacen.escribir(
        SesionRepositorySeguro.claveSesion,
        '{esto no es una sesión',
      );

      expect(
        () => repositorio.leer(),
        throwsA(isA<FalloDeValidacion>()),
      );
    });

    test('haySesionActiva propaga el fallo para que la pantalla pueda '
        'ofrecer cerrar sesión', () async {
      await almacen.escribir(SesionRepositorySeguro.claveSesion, 'basura');

      expect(
        () => repositorio.haySesionActiva(),
        throwsA(isA<FalloDeValidacion>()),
      );
    });
  });

  group('fallos del almacén del sistema', () {
    test('si el almacén falla, el repositorio lanza FalloSeguridad',
        () async {
      final SesionRepositorySeguro roto = SesionRepositorySeguro(
        AlmacenSeguroEnMemoria.queFalla('El llavero está bloqueado.'),
      );

      expect(
        () => roto.guardar(sesionVigente()),
        throwsA(isA<FalloSeguridad>()),
      );
      expect(
        () => roto.leer(),
        throwsA(isA<FalloSeguridad>()),
      );
    });
  });

  group('metadatos para el informe', () {
    test('el mecanismo informado proviene del almacén', () async {
      expect(repositorio.mecanismoDeProteccion, contains('Memoria'));
    });

    test('la huella sirve para comparar tokens sin exponerlos', () async {
      final Sesion original = sesionVigente();
      await repositorio.guardar(original);

      final Sesion recuperada = (await repositorio.leer())!;

      expect(recuperada.token.huella, original.token.huella);
      expect(recuperada.token.toString(), isNot(contains(original.token.valor)));
    });
  });
}
