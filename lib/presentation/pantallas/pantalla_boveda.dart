import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/fallos.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/daos/preferencias_dao.dart';
import '../../data/local/inspeccion_forense.dart';
import '../../data/repositorios/sesion_repository_inseguro.dart';
import '../../data/repositorios/sesion_repository_seguro.dart';
import '../../data/seguro/almacen_seguro.dart';
import '../../domain/entidades/sesion.dart';
import '../../domain/repositorios/sesion_repository.dart';
import '../../domain/servicios/generador_token.dart';
import '../di.dart';
import '../widgets/app_layout.dart';

/// **Pantalla de la bóveda y de la evidencia forense** (Semana 11).
///
/// Es el laboratorio donde la afirmación "el almacén seguro protege el
/// token" se convierte en un dato medible. La pantalla ejecuta un
/// experimento controlado con **dos tokens simulados distintos**:
///
/// | Paso | Token A | Token B |
/// |---|---|---|
/// | 1. Se genera | `ms_sim_labA_…` | `ms_sim_labB_…` |
/// | 2. Se guarda en | tabla `preferencias` de SQLite | almacén del sistema |
/// | 3. Se busca en el archivo `.sqlite` | **aparece** | **no aparece** |
///
/// El veredicto de cada búsqueda se calcula sobre los bytes reales del
/// archivo (ver `data/local/inspeccion_forense.dart`) y es lo que el
/// estudiante pega en la sección de evidencias del informe técnico.
///
/// ## Una excepción autorizada a la regla de "no mostrar el token"
///
/// El proyecto prohíbe imprimir el token en pantalla. Aquí se hace **una
/// única excepción**, con tres salvaguardas, porque el valor en claro *es*
/// la evidencia:
///
///  1. los tokens son simulados y de laboratorio;
///  2. se muestran censurados por omisión; revelarlos exige accionar un
///     interruptor;
///  3. la guía exige censurar el valor en la captura que se adjunta al
///     informe.
class PantallaBoveda extends StatefulWidget {
  const PantallaBoveda({super.key});

  @override
  State<PantallaBoveda> createState() => _PantallaBovedaState();
}

class _PantallaBovedaState extends State<PantallaBoveda> {
  final GeneradorTokenSimulado _generador = GeneradorTokenSimulado(
    vigencia: const Duration(hours: 1),
  );

  bool _ejecutando = false;
  bool _mostrarValores = false;
  _Experimento? _experimento;
  String? _error;
  Set<String> _clavesDelAlmacen = <String>{};

  @override
  void initState() {
    super.initState();
    _refrescarClaves();
  }

  Future<void> _refrescarClaves() async {
    try {
      final Set<String> claves = await getIt<AlmacenSeguro>().claves();
      if (!mounted) return;
      setState(() => _clavesDelAlmacen = claves);
    } on Fallo catch (fallo) {
      if (!mounted) return;
      setState(() => _error = fallo.mensaje);
    }
  }

  /// **El experimento forense (Reto 5).**
  ///
  /// Guarda dos tokens con los dos repositorios y busca ambos dentro del
  /// archivo de la base de datos. Al terminar, los valores en claro se
  /// conservan únicamente para poder censurarlos en la interfaz; nada se
  /// escribe en los registros de depuración.
  Future<void> _ejecutarExperimento() async {
    setState(() {
      _ejecutando = true;
      _error = null;
    });

    try {
      final PreferenciasDao preferencias = getIt<PreferenciasDao>();
      final SesionRepository inseguro = SesionRepositoryInseguro(preferencias);
      final SesionRepository seguro = getIt<SesionRepository>();

      final Sesion sesionA = _sesionDeLaboratorio('A');
      final Sesion sesionB = _sesionDeLaboratorio('B');

      // Paso 1: el antipatrón. El token queda en la tabla `preferencias`.
      await inseguro.guardar(sesionA);
      // Paso 2: el control. El token sale del sistema de archivos.
      await seguro.guardar(sesionB);

      // Paso 3: se recorren los bytes del archivo buscando cada token.
      final ResultadoForense forenseA =
          await inspeccionarArchivoDeBase(sesionA.token.valor);
      final ResultadoForense forenseB =
          await inspeccionarArchivoDeBase(sesionB.token.valor);

      final String filaEnTextoPlano =
          await preferencias.leer(SesionRepositoryInseguro.claveSesion) ?? '';

      if (!mounted) return;
      setState(() {
        _experimento = _Experimento(
          huellaA: sesionA.token.huella,
          huellaB: sesionB.token.huella,
          valorA: sesionA.token.valor,
          valorB: sesionB.token.valor,
          filaEnTextoPlano: filaEnTextoPlano,
          forenseA: forenseA,
          forenseB: forenseB,
        );
      });
      await _refrescarClaves();
    } on Fallo catch (fallo) {
      if (!mounted) return;
      setState(() => _error = fallo.mensaje);
    } finally {
      if (mounted) setState(() => _ejecutando = false);
    }
  }

  /// Sesión de laboratorio con un token marcado y distinguible.
  ///
  /// El valor generado se prefija con `labA_` / `labB_` para que la búsqueda
  /// dentro del archivo no pueda confundirse con la de otro dato.
  Sesion _sesionDeLaboratorio(String marca) {
    final TokenSesion original = _generador.emitir();
    return Sesion(
      documento: '0000000$marca',
      nombre: 'Token de laboratorio $marca',
      rol: RolUsuario.auditor,
      token: TokenSesion(
        valor: 'laboratorio_${marca}_${original.valor}',
        emitidoEn: original.emitidoEn,
        expiraEn: original.expiraEn,
      ),
    );
  }

  Future<void> _limpiarLaboratorio() async {
    setState(() {
      _ejecutando = true;
      _error = null;
    });
    try {
      await SesionRepositoryInseguro(getIt<PreferenciasDao>()).cerrar();
      await getIt<SesionRepository>().cerrar();
      if (!mounted) return;
      setState(() => _experimento = null);
      await _refrescarClaves();
    } on Fallo catch (fallo) {
      if (!mounted) return;
      setState(() => _error = fallo.mensaje);
    } finally {
      if (mounted) setState(() => _ejecutando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _Experimento? experimento = _experimento;

    return Scaffold(
      appBar: AppBar(title: const Text('Bóveda y evidencia')),
      body: SingleChildScrollView(
        child: AppLayout(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const TituloSeccion(
                'Qué protege el sistema operativo',
                icono: Icons.shield_outlined,
              ),
              _TarjetaAlmacen(
                mecanismo: _mecanismo(),
                claves: _clavesDelAlmacen,
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 8),
                _TarjetaError(mensaje: _error!),
              ],
              const SizedBox(height: 8),
              const TituloSeccion(
                'Experimento forense (Reto 5)',
                icono: Icons.search,
              ),
              TarjetaBase(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'El experimento guarda dos tokens distintos —uno en la '
                      'tabla preferencias de SQLite y otro en el almacén del '
                      'sistema— y busca ambos dentro de los bytes del archivo '
                      'manos_seguras.sqlite.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _ejecutando ? null : _ejecutarExperimento,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          _ejecutando
                              ? 'Ejecutando…'
                              : 'Ejecutar experimento forense',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _ejecutando ? null : _limpiarLaboratorio,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('Limpiar ambos almacenes'),
                      ),
                    ),
                  ],
                ),
              ),
              if (experimento != null) ...<Widget>[
                const SizedBox(height: 8),
                const TituloSeccion(
                  'Resultados del experimento',
                  icono: Icons.fact_check_outlined,
                ),
                _TarjetaResultado(
                  titulo: 'Token A · tabla preferencias (SQLite)',
                  subtitulo: 'Antipatrón: texto plano en el archivo',
                  huella: experimento.huellaA,
                  resultado: experimento.forenseA,
                ),
                _TarjetaResultado(
                  titulo: 'Token B · almacén del sistema operativo',
                  subtitulo: _mecanismo(),
                  huella: experimento.huellaB,
                  resultado: experimento.forenseB,
                ),
                TarjetaBase(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Fila guardada en la tabla preferencias',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _mostrarValores,
                        onChanged: (bool valor) =>
                            setState(() => _mostrarValores = valor),
                        title: const Text(
                          'Mostrar el token en claro (solo laboratorio)',
                          style: TextStyle(fontSize: 12),
                        ),
                        subtitle: const Text(
                          'En la captura del informe el valor debe ir '
                          'censurado.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD9E2F3)),
                        ),
                        child: Text(
                          _censurar(
                            experimento.filaEnTextoPlano,
                            experimento.valorA,
                            _mostrarValores,
                          ),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _Aviso(
                        'El almacén seguro guarda el token B; para leerlo '
                        'haría falta el Keystore o el Keychain del '
                        'dispositivo, no una copia del archivo. Por eso el '
                        'Token B no aparece en la inspección.',
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/sesion'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver a la pantalla de sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _mecanismo() {
    final SesionRepository repositorio = getIt<SesionRepository>();
    return repositorio is SesionRepositorySeguro
        ? repositorio.mecanismoDeProteccion
        : 'Almacén sin cifrado (implementación de laboratorio)';
  }

  static String _censurar(String texto, String valor, bool mostrar) {
    if (mostrar || valor.isEmpty) return texto;
    return texto.replaceAll(valor, '«valor censurado»');
  }
}

/// Datos que deja el experimento. **No** contiene los tokens completos más
/// allá de lo necesario para censurar la fila en texto plano.
class _Experimento {
  const _Experimento({
    required this.huellaA,
    required this.huellaB,
    required this.valorA,
    required this.valorB,
    required this.filaEnTextoPlano,
    required this.forenseA,
    required this.forenseB,
  });

  final String huellaA;
  final String huellaB;
  final String valorA;
  final String valorB;
  final String filaEnTextoPlano;
  final ResultadoForense forenseA;
  final ResultadoForense forenseB;
}

class _TarjetaAlmacen extends StatelessWidget {
  const _TarjetaAlmacen({required this.mecanismo, required this.claves});

  final String mecanismo;
  final Set<String> claves;

  @override
  Widget build(BuildContext context) {
    return TarjetaBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.vpn_key_outlined, color: AppColors.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mecanismo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            claves.isEmpty
                ? 'El almacén seguro está vacío: no hay ninguna clave guardada.'
                : 'Claves en el almacén seguro (${claves.length}): '
                    '${claves.join(', ')}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 6),
          const Text(
            'Solo se muestran los nombres de las claves. Los valores cifrados '
            'no se vuelcan a la interfaz.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TarjetaResultado extends StatelessWidget {
  const _TarjetaResultado({
    required this.titulo,
    required this.subtitulo,
    required this.huella,
    required this.resultado,
  });

  final String titulo;
  final String subtitulo;
  final String huella;
  final ResultadoForense resultado;

  @override
  Widget build(BuildContext context) {
    final Color color = resultado.hayFuga
        ? AppColors.alerta
        : (resultado.archivoExiste ? AppColors.exito : AppColors.aviso);
    final IconData icono = resultado.hayFuga
        ? Icons.report_gmailerrorred
        : (resultado.archivoExiste ? Icons.verified_outlined : Icons.help_outline);

    return TarjetaBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icono, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            'Huella del token: $huella',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            resultado.veredicto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Archivo: ${resultado.ruta}',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TarjetaError extends StatelessWidget {
  const _TarjetaError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return TarjetaBase(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline, color: AppColors.alerta),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.info_outline, size: 18, color: AppColors.navy),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
