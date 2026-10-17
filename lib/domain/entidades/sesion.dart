/// **Entidades del dominio para la sesión del observador.**
///
/// Semana 11 — temáticas 2.2.4 y 2.2.5 del sílabo:
/// *almacenamiento seguro* y *guardado seguro de un token de sesión*.
///
/// Este archivo es **Dart puro**: no importa `flutter`, ni `drift`, ni
/// `flutter_secure_storage`. Es la aplicación del principio de inversión de
/// dependencias (DIP, Semana 9): el dominio describe *qué* es un token y
/// *cuándo* deja de ser válido; la capa `data/` decide *dónde* se guarda.
///
/// Decisión de diseño que el informe debe registrar: el token **no** expone
/// su valor por la interfaz ni por los registros de depuración. Lo único que
/// la aplicación muestra es una **huella** (un resumen de 32 bits), suficiente
/// para comparar dos tokens en una demostración y insuficiente para
/// reconstruirlos.
library;

import 'dart:convert';

import '../../core/fallos.dart';

/// Rol de la persona que inicia sesión en ManosSeguras.
///
/// Se mantiene como `enum` con etiqueta para poder mostrarlo en pantalla sin
/// traducir cadenas sueltas por todo el código.
enum RolUsuario {
  observador('Observador de higiene de manos'),
  auditor('Auditor de calidad'),
  coordinador('Coordinador de la IPRESS');

  const RolUsuario(this.etiqueta);

  /// Texto listo para la interfaz.
  final String etiqueta;

  /// Reconstruye el rol desde el nombre con el que se serializó.
  ///
  /// Si el valor guardado no corresponde a ningún rol conocido (por ejemplo,
  /// porque el catálogo cambió entre versiones), se devuelve [observador] en
  /// lugar de fallar: una sesión con rol desconocido debe poder cerrarse.
  static RolUsuario desdeNombre(String? nombre) {
    for (final RolUsuario rol in values) {
      if (rol.name == nombre) return rol;
    }
    return RolUsuario.observador;
  }
}

/// **Token de sesión emitido por el servidor de autenticación.**
///
/// En esta semana el token es *simulado*: lo genera el propio dispositivo con
/// [GeneradorTokenSimulado] para poder practicar todo el ciclo de vida
/// (emisión → almacenamiento → lectura → expiración → cierre) sin depender de
/// un backend. La estructura, en cambio, es la de un token real: un valor
/// opaco con fecha de emisión y fecha de expiración.
///
/// Es un **objeto de valor inmutable**: dos tokens con el mismo valor y las
/// mismas fechas son iguales, y ninguno de sus campos puede modificarse
/// después de construido. La renovación produce una instancia nueva.
class TokenSesion {
  const TokenSesion({
    required this.valor,
    required this.emitidoEn,
    required this.expiraEn,
  });

  /// Vigencia por omisión de un token simulado: 8 horas.
  ///
  /// Ocho horas es la duración de un turno hospitalario, que es la unidad de
  /// trabajo real de una observación de higiene de manos. Un token que vive
  /// más que el turno no aporta seguridad; uno que vive menos obliga a
  /// reautenticarse en medio de una auditoría.
  static const Duration vigenciaPorDefecto = Duration(hours: 8);

  /// Umbral a partir del cual la interfaz avisa que la sesión está por
  /// expirar.
  static const Duration umbralAviso = Duration(minutes: 15);

  /// Prefijo de los tokens simulados, para distinguirlos a simple vista de
  /// un token emitido por un servidor real.
  static const String prefijoSimulado = 'ms_sim_';

  /// Versión del formato de serialización. Si algún día cambia la forma en
  /// que el token se guarda, este número lo delata y permite migrar en lugar
  /// de fallar (mismo criterio que `schemaVersion` en drift, Semana 10).
  static const int versionFormato = 1;

  /// Valor opaco del token. **Nunca** se muestra en pantalla ni se registra
  /// con `debugPrint`.
  final String valor;

  /// Momento (UTC) en que el servidor lo emitió.
  final DateTime emitidoEn;

  /// Momento (UTC) a partir del cual deja de ser válido.
  final DateTime expiraEn;

  /// `true` si el token todavía puede usarse.
  bool vigenteEn(DateTime ahora) => expiraEn.isAfter(ahora.toUtc());

  /// `true` si el token es válido pero está por expirar.
  bool porExpirarEn(DateTime ahora) {
    final DateTime instante = ahora.toUtc();
    return vigenteEn(instante) &&
        expiraEn.difference(instante) <= umbralAviso;
  }

  /// Tiempo que le queda al token (cero si ya expiró).
  Duration restanteEn(DateTime ahora) {
    final Duration restante = expiraEn.difference(ahora.toUtc());
    return restante.isNegative ? Duration.zero : restante;
  }

  /// **Huella del token**: 8 dígitos hexadecimales derivados del valor.
  ///
  /// Es lo único que la interfaz puede mostrar. Se calcula con FNV-1a de
  /// 32 bits —un resumen no criptográfico— porque su único propósito es
  /// permitir comparar visualmente dos tokens distintos en la demostración
  /// del laboratorio. **No** sustituye a un hash criptográfico (SHA-256) ni
  /// debe usarse para verificar autenticidad.
  String get huella {
    int resumen = 0x811c9dc5;
    for (final int byte in utf8.encode(valor)) {
      resumen = (resumen ^ byte) * 0x01000193 & 0xffffffff;
    }
    return resumen.toRadixString(16).padLeft(8, '0');
  }

  /// Serializa el token al formato de transporte hacia el almacén seguro.
  ///
  /// Se usa JSON y no una cadena con separadores porque el nombre del
  /// usuario sí puede contener guiones o puntos, y porque `jsonDecode`
  /// valida la estructura al leer (ver [desdeAlmacen]).
  String serializar() => jsonEncode(_aMapa());

  /// Reconstruye el token desde el texto guardado.
  ///
  /// Cualquier anomalía (JSON inválido, campos faltantes, versión
  /// desconocida) se traduce a [FalloDeValidacion]: un dato corrupto en el
  /// almacén **no** debe romper la aplicación, debe provocar un cierre de
  /// sesión controlado.
  factory TokenSesion.desdeAlmacen(String texto) {
    final Map<String, Object?> mapa = _mapaDesdeJson(texto);
    final Object? version = mapa['v'];
    if (version != versionFormato) {
      throw FalloDeValidacion(
        'El token guardado usa un formato desconocido (v: $version).',
      );
    }
    return TokenSesion(
      valor: _textoRequerido(mapa, 'token'),
      emitidoEn: _fechaRequerida(mapa, 'emitidoEn'),
      expiraEn: _fechaRequerida(mapa, 'expiraEn'),
    );
  }

  Map<String, Object?> _aMapa() => <String, Object?>{
        'v': versionFormato,
        'token': valor,
        'emitidoEn': emitidoEn.toUtc().toIso8601String(),
        'expiraEn': expiraEn.toUtc().toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is TokenSesion &&
      other.valor == valor &&
      other.emitidoEn == emitidoEn &&
      other.expiraEn == expiraEn;

  @override
  int get hashCode => Object.hash(valor, emitidoEn, expiraEn);

  /// Representación segura para los registros: **nunca** incluye [valor].
  @override
  String toString() => 'TokenSesion(huella: $huella, expiraEn: '
      '${expiraEn.toUtc().toIso8601String()})';

  // ---------------------------------------------------------------------
  // Utilidades internas de (de)serialización
  // ---------------------------------------------------------------------

  static Map<String, Object?> _mapaDesdeJson(String texto) {
    try {
      final Object? decodificado = jsonDecode(texto);
      if (decodificado is Map<String, Object?>) return decodificado;
      throw const FormatException('Se esperaba un objeto JSON.');
    } on FormatException catch (error) {
      throw FalloDeValidacion(
        'El token guardado no tiene un formato legible.',
        causa: error,
      );
    }
  }

  static String _textoRequerido(Map<String, Object?> mapa, String campo) {
    final Object? valor = mapa[campo];
    if (valor is String && valor.isNotEmpty) return valor;
    throw FalloDeValidacion('Falta el campo "$campo" en el token guardado.');
  }

  static DateTime _fechaRequerida(Map<String, Object?> mapa, String campo) {
    final DateTime? fecha = DateTime.tryParse(_textoRequerido(mapa, campo));
    if (fecha == null) {
      throw FalloDeValidacion(
        'El campo "$campo" del token guardado no es una fecha válida.',
      );
    }
    return fecha.toUtc();
  }
}

/// **Sesión activa**: quién inició sesión y con qué token.**
///
/// La sesión se compone de un [TokenSesion] y de la identidad mínima del
/// usuario (documento, nombre y rol). Se guarda completa en el almacén
/// seguro porque el nombre y el documento también son datos personales
/// (PII): cualquiera que lea el archivo de la base de datos SQLite no debe
/// poder vincular las auditorías con la persona que las levantó.
class Sesion {
  const Sesion({
    required this.documento,
    required this.nombre,
    required this.rol,
    required this.token,
  });

  /// Versión del formato de la sesión completa.
  static const int versionFormato = 1;

  /// Documento Nacional de Identidad del usuario. **Dato personal.**
  final String documento;

  /// Nombre y apellidos del usuario. **Dato personal.**
  final String nombre;

  /// Rol con el que se inició sesión.
  final RolUsuario rol;

  /// Token que acompaña a la sesión.
  final TokenSesion token;

  /// `true` mientras el token siga vigente.
  bool activaEn(DateTime ahora) => token.vigenteEn(ahora);

  /// Número de documento enmascarado para mostrarlo en pantalla.
  ///
  /// Se conserva el bloque final y se oculta el resto (`****1234`): es la
  /// misma convención que usan las entidades financieras y evita que una
  /// captura de pantalla del informe exponga el documento completo.
  String get documentoEnmascarado {
    if (documento.length <= 4) return '****';
    return '****${documento.substring(documento.length - 4)}';
  }

  /// Serializa la sesión completa (incluido el token) para el almacén seguro.
  String serializar() => jsonEncode(<String, Object?>{
        'v': versionFormato,
        'documento': documento,
        'nombre': nombre,
        'rol': rol.name,
        'token': jsonDecode(token.serializar()),
      });

  /// Reconstruye la sesión desde el texto guardado.
  factory Sesion.desdeAlmacen(String texto) {
    final Map<String, Object?> mapa;
    try {
      final Object? decodificado = jsonDecode(texto);
      if (decodificado is! Map<String, Object?>) {
        throw const FormatException('Se esperaba un objeto JSON.');
      }
      mapa = decodificado;
    } on FormatException catch (error) {
      throw FalloDeValidacion(
        'La sesión guardada no tiene un formato legible.',
        causa: error,
      );
    }

    if (mapa['v'] != versionFormato) {
      throw FalloDeValidacion(
        'La sesión guardada usa un formato desconocido (v: ${mapa['v']}).',
      );
    }

    final Object? tokenCrudo = mapa['token'];
    if (tokenCrudo is! Map<String, Object?>) {
      throw const FalloDeValidacion('La sesión guardada no incluye el token.');
    }

    return Sesion(
      documento: _textoRequerido(mapa, 'documento'),
      nombre: _textoRequerido(mapa, 'nombre'),
      rol: RolUsuario.desdeNombre(mapa['rol'] as String?),
      token: TokenSesion.desdeAlmacen(jsonEncode(tokenCrudo)),
    );
  }

  static String _textoRequerido(Map<String, Object?> mapa, String campo) {
    final Object? valor = mapa[campo];
    if (valor is String && valor.isNotEmpty) return valor;
    throw FalloDeValidacion('Falta el campo "$campo" en la sesión guardada.');
  }

  @override
  String toString() => 'Sesion(documento: $documentoEnmascarado, '
      'rol: ${rol.name}, token: $token)';
}
