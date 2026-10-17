import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mismo caso mínimo: contar oportunidades agregadas. Solo para comparación.
class CapturaConSetState extends StatefulWidget {
  const CapturaConSetState({super.key});
  @override
  State<CapturaConSetState> createState() => _CapturaConSetStateState();
}

class _CapturaConSetStateState extends State<CapturaConSetState> {
  int total = 0;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => total++),
    child: Text('Oportunidades: $total'),
  );
}

final contadorCapturaProvider = NotifierProvider<ContadorCaptura, int>(
  ContadorCaptura.new,
);

class ContadorCaptura extends Notifier<int> {
  @override
  int build() => 0;
  void agregar() => state++;
}

class CapturaConRiverpod extends ConsumerWidget {
  const CapturaConRiverpod({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton(
    onPressed: () => ref.read(contadorCapturaProvider.notifier).agregar(),
    child: Text('Oportunidades: ${ref.watch(contadorCapturaProvider)}'),
  );
}
