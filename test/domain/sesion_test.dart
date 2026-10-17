import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:manos_seguras/core/fallos.dart';
import 'package:manos_seguras/domain/entidades/sesion.dart';
import 'package:manos_seguras/domain/servicios/generador_token.dart';

/// **Pruebas de las entidades de sesión y del generador de tokens.**
///
/// Semana 11. No necesitan Flutter ni el sistema operativo: son pruebas de
/// **dominio puro**, el tipo de prueba que la Sesión 19 formaliza. Cada
/// `expect` corresponde a una regla que el informe técnico debe poder
/// defender.
void main() {
  final DateTime instanteBase = DateTime.utc(2026, 11, 4, 8, 0, 0);

  group('GeneradorTokenSimulado', () {
    test('emite un token con el prefijo del proyecto y suficiente entropía',
        () {
      final TokenSesion token = GeneradorTokenSimulado().emitir();

      expect(token.valor, startsWith(TokenSesion.prefijoSimulado));
      // 32 bytes en base64url sin relleno ocupan 43 caracteres.
      expect(token.valor.length, TokenSesion.prefijoSimulado.length + 43);
    });

    test('dos emisiones producen tokens distintos', () {
      final GeneradorTokenSimulado generador = GeneradorTokenSimulado();

      expect(generador.emitir().valor, isNot(generador.emitir().valor));
    });

    test('con una semilla fija el token es reproducible (pruebas)', () {
      final GeneradorTokenSimulado a =
          GeneradorTokenSimulado(azar: Random(2026));
      final GeneradorTokenSimulado b =
          GeneradorTokenSimulado(azar: Random(2026));

      expect(a.emitir(ahora: instanteBase).valor,
          b.emitir(ahora: instanteBase).valor);
    });

    test('la expiración se calcula a partir del instante de emisión', () {
      final TokenSesion token = GeneradorTokenSimulado(
        vigencia: const Duration(hours: 4),
      ).emitir(ahora: instanteBase);

      expect(token.emitidoEn, instanteBase);
      expect(token.expiraEn, instanteBase.add(const Duration(hours: 4)));
    });
  });

  group('TokenSesion · vigencia', () {
    late TokenSesion token;

    setUp(() {
      token = GeneradorTokenSimulado(
        vigencia: const Duration(hours: 8),
      ).emitir(ahora: instanteBase);
    });

    test('está vigente antes de expirar y deja de estarlo al expirar', () {
      expect(token.vigenteEn(instanteBase), isTrue);
      expect(
        token.vigenteEn(instanteBase.add(const Duration(hours: 7))),
        isTrue,
      );
      // El límite exacto: a la hora de expiración el token ya no sirve.
      expect(
        token.vigenteEn(instanteBase.add(const Duration(hours: 8))),
        isFalse,
      );
      expect(
        token.vigenteEn(instanteBase.add(const Duration(hours: 9))),
        isFalse,
      );
    });

    test('avisa cuando está por expirar', () {
      final DateTime diezMinutosAntes =
          token.expiraEn.subtract(const Duration(minutes: 10));

      expect(token.porExpirarEn(diezMinutosAntes), isTrue);
      expect(token.porExpirarEn(instanteBase), isFalse);
      // Un token ya expirado no está "por expirar": está vencido.
      expect(
        token.porExpirarEn(instanteBase.add(const Duration(hours: 9))),
        isFalse,
      );
    });

    test('el tiempo restante nunca es negativo', () {
      expect(
        token.restanteEn(instanteBase),
        const Duration(hours: 8),
      );
      expect(
        token.restanteEn(instanteBase.add(const Duration(days: 1))),
        Duration.zero,
      );
    });
  });

  group('TokenSesion · huella y serialización', () {
    test('la huella tiene 8 dígitos hexadecimales y es estable', () {
      final TokenSesion token = GeneradorTokenSimulado().emitir();

      expect(token.huella, matches(RegExp(r'^[0-9a-f]{8}$')));
      expect(token.huella, token.huella);
    });

    test('tokens distintos producen huellas distintas', () {
      final GeneradorTokenSimulado generador = GeneradorTokenSimulado();

      expect(generador.emitir().huella, isNot(generador.emitir().huella));
    });

    test('toString NO revela el valor del token', () {
      final TokenSesion token = GeneradorTokenSimulado().emitir();

      expect(token.toString(), isNot(contains(token.valor)));
      expect(token.toString(), contains(token.huella));
    });

    test('serializar y desdeAlmacen reconstruyen el mismo token', () {
      final TokenSesion original =
          GeneradorTokenSimulado().emitir(ahora: instanteBase);

      final TokenSesion recuperado =
          TokenSesion.desdeAlmacen(original.serializar());

      expect(recuperado, original);
      expect(recuperado.hashCode, original.hashCode);
    });

    test('un texto ilegible produce FalloDeValidacion, no una excepción '
        'técnica', () {
      expect(
        () => TokenSesion.desdeAlmacen('esto no es json'),
        throwsA(isA<FalloDeValidacion>()),
      );
    });

    test('una versión de formato desconocida se rechaza', () {
      expect(
        () => TokenSesion.desdeAlmacen(
          '{"v":99,"token":"x","emitidoEn":"2026-11-04T08:00:00.000Z",'
          '"expiraEn":"2026-11-04T16:00:00.000Z"}',
        ),
        throwsA(isA<FalloDeValidacion>()),
      );
    });

    test('un campo faltante se rechaza con un mensaje en español', () {
      expect(
        () => TokenSesion.desdeAlmacen(
          '{"v":1,"emitidoEn":"2026-11-04T08:00:00.000Z",'
          '"expiraEn":"2026-11-04T16:00:00.000Z"}',
        ),
        throwsA(
          isA<FalloDeValidacion>().having(
            (FalloDeValidacion fallo) => fallo.mensaje,
            'mensaje',
            contains('token'),
          ),
        ),
      );
    });
  });

  group('Sesion', () {
    late Sesion sesion;

    setUp(() {
      sesion = Sesion(
        documento: '40123456',
        nombre: 'Rosa Quispe Huamán',
        rol: RolUsuario.observador,
        token: GeneradorTokenSimulado().emitir(ahora: instanteBase),
      );
    });

    test('enmascara el documento dejando visibles solo 4 dígitos', () {
      expect(sesion.documentoEnmascarado, '****3456');
      expect(sesion.documentoEnmascarado, isNot(contains('4012')));
    });

    test('un documento muy corto se enmascara por completo', () {
      final Sesion corta = Sesion(
        documento: '123',
        nombre: 'Prueba',
        rol: RolUsuario.auditor,
        token: sesion.token,
      );

      expect(corta.documentoEnmascarado, '****');
    });

    test('sobrevive al viaje de ida y vuelta por el almacén', () {
      final Sesion recuperada = Sesion.desdeAlmacen(sesion.serializar());

      expect(recuperada.documento, sesion.documento);
      expect(recuperada.nombre, sesion.nombre);
      expect(recuperada.rol, sesion.rol);
      expect(recuperada.token, sesion.token);
    });

    test('un rol desconocido no rompe la lectura de la sesión', () {
      final String manipulada = sesion
          .serializar()
          .replaceAll('"rol":"observador"', '"rol":"superusuario"');

      expect(Sesion.desdeAlmacen(manipulada).rol, RolUsuario.observador);
    });

    test('activaEn refleja la vigencia del token', () {
      expect(sesion.activaEn(instanteBase), isTrue);
      expect(
        sesion.activaEn(instanteBase.add(const Duration(hours: 9))),
        isFalse,
      );
    });

    test('toString no expone el documento completo ni el token', () {
      expect(sesion.toString(), isNot(contains('40123456')));
      expect(sesion.toString(), isNot(contains(sesion.token.valor)));
    });
  });

  group('DirectorioUsuariosSimulado', () {
    final DirectorioUsuariosSimulado directorio =
        DirectorioUsuariosSimulado();

    test('acepta las credenciales de un usuario del directorio', () {
      final UsuarioSimulado? usuario = directorio.autenticar(
        documento: '40123456',
        clave: 'higiene2026',
      );

      expect(usuario, isNotNull);
      expect(usuario!.rol, RolUsuario.observador);
    });

    test('ignora los espacios alrededor del documento', () {
      expect(
        directorio.autenticar(documento: '  40123456 ', clave: 'higiene2026'),
        isNotNull,
      );
    });

    test('rechaza una clave incorrecta', () {
      expect(
        directorio.autenticar(documento: '40123456', clave: 'otra'),
        isNull,
      );
    });

    test('el mensaje de error no distingue usuario inexistente de clave '
        'incorrecta', () {
      const FalloDeAutenticacion fallo = FalloDeAutenticacion();

      expect(fallo.mensaje, 'Documento o clave incorrectos.');
      expect(fallo.mensaje, isNot(contains('no existe')));
    });
  });
}
