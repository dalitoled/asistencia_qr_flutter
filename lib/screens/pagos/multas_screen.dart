import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../models/multa_model.dart';
import '../../models/socio_model.dart';
import '../../providers/asistencia_provider.dart';
import '../../providers/socios_provider.dart';
import '../../widgets/loading_widget.dart';

class MultasScreen extends ConsumerWidget {
  const MultasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multasAsync = ref.watch(multasProvider);
    final sociosAsync = ref.watch(sociosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Multas Pendientes')),
      body: multasAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (multas) {
          final pendientes = multas.where((m) => m.isPendiente).toList();
          final sociosMap = switch (sociosAsync) {
            AsyncData(:final value) => {for (final s in value) s.id: s},
            _ => <String?, SocioModel>{},
          };

          if (pendientes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: AppConstants.successColor),
                  SizedBox(height: 16),
                  Text('No hay multas pendientes', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Todas las multas han sido pagadas', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(multasProvider.notifier).loadMultas(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              itemCount: pendientes.length,
              itemBuilder: (context, index) {
                final multa = pendientes[index];
                final socio = sociosMap[multa.socioId];
                final codigo = socio?.numeroSocio;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: multa.tipo == TipoMulta.retraso
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      child: Icon(
                        multa.tipo == TipoMulta.retraso ? Icons.access_time : Icons.cancel,
                        color: multa.tipo == TipoMulta.retraso ? Colors.orange : Colors.red,
                      ),
                    ),
                    title: Text(socio?.nombreCompleto ?? multa.socioNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (codigo != null && codigo.isNotEmpty)
                          Text('Código: $codigo', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (multa.tipo == TipoMulta.retraso ? Colors.orange : Colors.red).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                multa.tipoString,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: multa.tipo == TipoMulta.retraso ? Colors.orange : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Bs. ${multa.monto.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Text(
                          '${multa.fecha.day}/${multa.fecha.month}/${multa.fecha.year}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => context.push('/pagos/pagar', extra: multa),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('PAGAR'),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
