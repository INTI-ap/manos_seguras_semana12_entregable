import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entidades/catalogos.dart';
import '../../domain/entidades/oportunidad_registro.dart';
import '../providers/captura_provider.dart';
import '../providers/resultado_operacion.dart';
import '../widgets/app_layout.dart';
import '../widgets/tarjetas.dart';

/// Captura de oportunidades (los 5 Momentos) **y guardado en la base local**.
///
/// ## Qué cambia en la Semana 12 (temática 2.3.3)
///
/// Esta pantalla era el ejemplo canónico de `setState`: seis campos de estado
/// (`_oportunidades`, `_siguienteNumero`, `_accionSeleccionada`, `_guardando`,
/// `_ultimoEstablecimiento`, `_cargandoPreferencia`) y cinco llamadas a
/// `setState` repartidas por el archivo. Hoy **no tiene estado propio**: pasa
/// de `StatefulWidget` a `ConsumerWidget` porque todo el estado se mudó a
/// `capturaProvider`.
///
/// ```
///   ANTES (Semana 10)                          AHORA (Semana 12)
///   ─────────────────                          ─────────────────
///   StatefulWidget + setState                  ConsumerWidget + ref.watch
///   final List<OportunidadRegistro> _oportunidades;   →  estado.oportunidades
///   int _siguienteNumero = 1;                  →  estado.siguienteNumero
///   bool _guardando = false;                   →  estado.guardando
///   setState(() => _accionSeleccionada = a);   →  notifier.seleccionar Accion(a)
/// ```
///
/// Lo que **no** cambió, y es lo importante: la pantalla sigue sin conocer
/// drift ni `flutter_secure_storage`. Solo habla con el notifier, y el
/// notifier solo habla con las interfaces del dominio.
///
/// ## Puntos didácticos del archivo
///
///  * `ref.watch(capturaProvider)` en `build`: la pantalla **observa** el
///    estado y se reconstruye cuando cambia.
///  * `ref.read(capturaProvider.notifier)` **dentro de los manejadores**
///    (`onPressed`): la regla oficial es *watch en `build`, read en eventos*.
///  * Después de un `await` se comprueba `context.mounted` antes de tocar el
///    `BuildContext` (lección de la Sesión 16, ahora en su versión moderna).
///  * El notifier devuelve un [ResultadoOperacion] y **la pantalla** decide el
///    mensaje: el notifier no conoce `ScaffoldMessenger`.
class PantallaOportunidades extends ConsumerWidget {
  const PantallaOportunidades({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EstadoCaptura estado = ref.watch(capturaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oportunidades'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Ver auditorías guardadas',
            onPressed: () => context.go('/auditorias'),
            icon: const Icon(Icons.folder_open_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: AppLayout(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!estado.cargandoPreferencia &&
                  estado.ultimoEstablecimiento != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Último establecimiento auditado: '
                    '${estado.ultimoEstablecimiento} '
                    '(preferencia guardada en SQLite)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              _Resumen(
                cumplidas: estado.cumplidas,
                total: estado.oportunidades.length,
                porcentaje: estado.porcentaje,
              ),
              const SizedBox(height: 16),
              const TituloSeccion('Registrar una oportunidad',
                  icono: Icons.add_task),
              TarjetaBase(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Acción observada',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Accion.values.map((Accion accion) {
                        final bool seleccionada =
                            accion == estado.accionSeleccionada;
                        final Color color = EstiloCatalogo.colorAccion(accion);
                        return ChoiceChip(
                          label: Text(accion.etiqueta),
                          selected: seleccionada,
                          avatar: Icon(
                            EstiloCatalogo.iconoAccion(accion),
                            size: 16,
                            color: seleccionada ? Colors.white : color,
                          ),
                          selectedColor: color,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: seleccionada ? Colors.white : null,
                          ),
                          onSelected: (bool _) {
                            // `read`, no `watch`: estamos en un manejador, no
                            // en `build`.
                            ref
                                .read(capturaProvider.notifier)
                                .seleccionarAccion(accion);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            ref.read(capturaProvider.notifier).agregar(),
                        icon: const Icon(Icons.add),
                        label: Text(
                          'Agregar oportunidad '
                          '${estado.siguienteNumero.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TituloSeccion(
                'Oportunidades registradas (${estado.oportunidades.length})',
                icono: Icons.list_alt,
              ),
              if (estado.oportunidades.isEmpty)
                const TarjetaBase(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Aún no hay oportunidades. Use el botón de arriba.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                ...estado.oportunidades.map(
                  (OportunidadRegistro o) => Stack(
                    children: <Widget>[
                      TarjetaOportunidad(
                        numero: o.numero,
                        momento: o.momento,
                        accion: o.accion,
                        observacion: o.observacion,
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          tooltip: 'Quitar',
                          iconSize: 18,
                          onPressed: () => ref
                              .read(capturaProvider.notifier)
                              .quitar(o.numero),
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: estado.guardando
                      ? null
                      : () => _guardar(context, ref),
                  icon: estado.guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    estado.guardando
                        ? 'Guardando en SQLite…'
                        : 'Guardar auditoría en el dispositivo',
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Guarda el borrador y **narra** el resultado.
  ///
  /// El `switch` sobre un `sealed class` obliga al compilador a exigir los
  /// tres casos: no se puede olvidar el error.
  Future<void> _guardar(BuildContext context, WidgetRef ref) async {
    final ResultadoOperacion resultado =
        await ref.read(capturaProvider.notifier).guardar();
    // Tras un `await` el widget pudo haber sido retirado del árbol.
    if (!context.mounted) return;

    switch (resultado) {
      case OperacionOk(:final String? detalle):
        _avisar(context, 'Auditoría guardada en el dispositivo.');
        if (detalle != null) context.go('/auditorias/$detalle');
      case OperacionSinDatos(:final String mensaje):
        _avisar(context, mensaje);
      case OperacionFallida(:final String mensaje):
        _avisar(context, mensaje, error: true);
    }
  }

  void _avisar(BuildContext context, String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? AppColors.alerta : AppColors.exito,
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({
    required this.cumplidas,
    required this.total,
    required this.porcentaje,
  });

  final int cumplidas;
  final int total;
  final int porcentaje;

  @override
  Widget build(BuildContext context) {
    return TarjetaBase(
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Cumplimiento de la observación',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '$cumplidas de $total oportunidades cumplidas',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$porcentaje%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
