import 'dart:convert';
import 'dart:math';

import '../entidades/sesion.dart';

/// **Servicio de dominio: emisión de tokens simulados.**
///
/// Semana 11 — actividad de aprendizaje del sílabo: *"Implementan el guardado
/// seguro de un token simulado"*. Este servicio es el que **simula** al
/// servidor de autenticación: fabrica un token con la misma forma que
/// tendría uno real (valor opaco + emisión + expiración) para que todo el
/// ciclo de vida pueda practicarse sin backend.
///
/// Está en `domain/servicios/` y no en `data/` porque no depende de ninguna
/// tecnología: solo de `dart:math` y `dart:convert`, igual que
/// `CalculadoraAdherencia` (Semana 8).
///
/// ## Por qué `Random.secure()` y no `Random()`
///
/// `Random()` produce una secuencia **predecible** a partir de una semilla;
/// dos ejecuciones con la misma semilla generan los mismos números. Un token
/// predecible es un token adivinable. `Random.secure()` obtiene entropía del
/// sistema operativo y es el generador que Dart expone para uso
/// criptográfico.
class GeneradorTokenSimulado {
  /// [azar] se inyecta para que las pruebas sean reproducibles: con una
  /// semilla fija, el token generado es siempre el mismo.
  GeneradorTokenSimulado({
    Duration? vigencia,
    Random? azar,
  })  : vigencia = vigencia ?? TokenSesion.vigenciaPorDefecto,
        _azar = azar ?? Random.secure();

  /// Cuánto dura el token emitido.
  final Duration vigencia;

  final Random _azar;

  /// Emite un token nuevo.
  ///
  /// [ahora] se recibe como parámetro —en lugar de leer el reloj dentro del
  /// método— para que las pruebas puedan situar la emisión en un instante
  /// concreto y comprobar la expiración sin esperar horas reales. Es el
  /// mismo principio de *inyección de dependencias* de la Semana 9 aplicado
  /// al reloj.
  TokenSesion emitir({DateTime? ahora}) {
    final DateTime instante = (ahora ?? DateTime.now()).toUtc();
    return TokenSesion(
      valor: _valorAleatorio(),
      emitidoEn: instante,
      expiraEn: instante.add(vigencia),
    );
  }

  /// 32 bytes de entropía codificados en base64url, sin relleno.
  ///
  /// 256 bits es el tamaño habitual de un token de sesión opaco. La
  /// codificación base64url evita caracteres que estorban al copiar el
  /// token en una URL o en un encabezado HTTP.
  String _valorAleatorio() {
    final List<int> bytes = List<int>.generate(32, (_) => _azar.nextInt(256));
    final String cuerpo = base64Url.encode(bytes).replaceAll('=', '');
    return '${TokenSesion.prefijoSimulado}$cuerpo';
  }
}

/// Usuario del directorio simulado de ManosSeguras.
class UsuarioSimulado {
  const UsuarioSimulado({
    required this.documento,
    required this.nombre,
    required this.rol,
    required this.clave,
  });

  final String documento;
  final String nombre;
  final RolUsuario rol;

  /// Clave en texto plano: **solo** es aceptable porque el directorio es
  /// ficticio y vive en el código de laboratorio. El informe debe registrar
  /// que en producción la verificación de credenciales ocurre en el servidor
  /// y la aplicación nunca almacena contraseñas.
  final String clave;
}

/// **Directorio de usuarios simulado** para la pantalla de inicio de sesión.
///
/// Reemplaza al backend de autenticación (que llega en la Unidad III con
/// Firebase Auth) y permite practicar el flujo completo: credenciales →
/// emisión de token → guardado seguro → reanudación de la sesión.
class DirectorioUsuariosSimulado {
  DirectorioUsuariosSimulado({List<UsuarioSimulado>? usuarios})
      : usuarios = usuarios ?? _porDefecto;

  /// Los tres usuarios de demostración, uno por rol.
  static const List<UsuarioSimulado> _porDefecto = <UsuarioSimulado>[
    UsuarioSimulado(
      documento: '40123456',
      nombre: 'Rosa Quispe Huamán',
      rol: RolUsuario.observador,
      clave: 'higiene2026',
    ),
    UsuarioSimulado(
      documento: '41234567',
      nombre: 'Luis Puma Condori',
      rol: RolUsuario.auditor,
      clave: 'calidad2026',
    ),
    UsuarioSimulado(
      documento: '42345678',
      nombre: 'Ana Ttito Farfán',
      rol: RolUsuario.coordinador,
      clave: 'ipress2026',
    ),
  ];

  final List<UsuarioSimulado> usuarios;

  /// Verifica credenciales y devuelve el usuario, o `null` si no coinciden.
  ///
  /// La comparación de la clave es deliberadamente simple porque el
  /// directorio es de laboratorio; lo que **sí** se modela correctamente es
  /// el mensaje de error: nunca se distingue "usuario inexistente" de
  /// "clave incorrecta", porque esa distinción ayuda a enumerar cuentas.
  UsuarioSimulado? autenticar({
    required String documento,
    required String clave,
  }) {
    final String limpio = documento.trim();
    for (final UsuarioSimulado usuario in usuarios) {
      if (usuario.documento == limpio && usuario.clave == clave) {
        return usuario;
      }
    }
    return null;
  }
}
