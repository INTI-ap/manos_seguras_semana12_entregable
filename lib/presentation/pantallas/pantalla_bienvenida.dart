import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../providers/captura_provider.dart';
import '../providers/sesion_provider.dart';
import '../providers/tema_provider.dart';
import '../widgets/app_layout.dart';
import '../widgets/tarjetas.dart';

/// Pantalla de bienvenida: presenta el proyecto, los 5 Momentos y los accesos
/// a los recorridos del curso.
///
/// **Semana 12:** es el segundo consumidor de los mismos providers que usan
/// `/oportunidades` y `/sesion`. Ese es el argumento central de la temática
/// 2.3.1 y no hay forma de verlo con `setState`: aquí se muestra, sin ninguna
/// comunicación entre pantallas, **el estado de la captura en curso** y **si
/// hay sesión activa**, porque ambos viven en providers compartidos.
///
/// ```
///   /oportunidades ──┐                        ┌── ref.watch(capturaProvider)
///                    ├── capturaProvider ─────┤
///   /  (aquí)     ───┘                        └── (cualquier pantalla futura)
///
///   Con `setState` ese estado moriría al cerrar la pantalla; para
///   compartirlo habría que subirlo a un `InheritedWidget` a mano.
/// ```
class PantallaBienvenida extends ConsumerWidget {
  const PantallaBienvenida({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EstadoCaptura captura = ref.watch(capturaProvider);
    final EstadoSesion sesion = ref.watch(sesionCtrlProvider);
    final ThemeMode modo = ref.watch(temaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ManosSeguras'),
        actions: <Widget>[
          IconButton(
            tooltip: modo == ThemeMode.dark
                ? 'Cambiar a tema claro'
                : 'Cambiar a tema oscuro',
            onPressed: () => ref.read(temaProvider.notifier).alternar(),
            icon: Icon(
              modo == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: AppLayout(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _Encabezado(),
              const SizedBox(height: 16),
              // Estado compartido: la misma información que ve /oportunidades.
              _TarjetaEstadoCompartido(captura: captura, sesion: sesion),
              const SizedBox(height: 16),
              const TarjetaMomentos(),
              const SizedBox(height: 4),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(
                    captura.hayDatos ? '/oportunidades' : '/establecimiento',
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    captura.hayDatos
                        ? 'Continuar el borrador '
                              '(${captura.oportunidades.length} oportunidades)'
                        : 'Comenzar auditoría',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, height: 1.1),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/oportunidades'),
                  icon: const Icon(Icons.add_task),
                  label: const Text('Capturar oportunidades (Riverpod)'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/auditorias'),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Auditorías guardadas en el dispositivo'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/diagnostico'),
                  icon: const Icon(Icons.storage_outlined),
                  label: const Text('Diagnóstico de la base local'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/sesion'),
                  icon: const Icon(Icons.lock_outline),
                  label: Text(
                    sesion.haySesion
                        ? 'Sesión activa: ${sesion.sesion!.nombre}'
                        : 'Sesión y token seguro',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/boveda'),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Bóveda y evidencia forense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta que demuestra la **reactividad compartida** de la Semana 12.
///
/// Ninguna de las dos pantallas involucradas se comunica con la otra: las dos
/// observan el mismo provider y Riverpod se encarga de reconstruir solo lo que
/// cambió. Al agregar oportunidades en `/oportunidades`, esta tarjeta se
/// actualiza aunque el usuario no haya navegado todavía.
class _TarjetaEstadoCompartido extends StatelessWidget {
  const _TarjetaEstadoCompartido({required this.captura, required this.sesion});

  final EstadoCaptura captura;
  final EstadoSesion sesion;

  @override
  Widget build(BuildContext context) {
    return TarjetaBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.hub_outlined, color: AppColors.navy, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estado compartido por Riverpod',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Fila(
            etiqueta: 'Borrador en curso',
            valor: captura.hayDatos
                ? '${captura.oportunidades.length} oportunidades · '
                      '${captura.porcentaje}% de cumplimiento'
                : 'sin oportunidades capturadas',
          ),
          _Fila(
            etiqueta: 'Sesión',
            valor: sesion.haySesion
                ? '${sesion.sesion!.nombre} (${sesion.sesion!.rol.etiqueta})'
                : 'sin iniciar',
          ),
          _Fila(
            etiqueta: 'Último establecimiento',
            valor: captura.ultimoEstablecimiento ?? '—',
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              etiqueta,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.clean_hands, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text(
            'ManosSeguras',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Auditoría digital de higiene de manos con persistencia local '
            '(offline-first). Semana 12: el estado de la aplicación —la '
            'captura en curso, la sesión y el tema— vive en providers de '
            'Riverpod, sin un solo setState repartido por las pantallas.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'drift + SQLite · flutter_secure_storage · Riverpod',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
