import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../models/pago_model.dart';
import '../../models/socio_model.dart';
import '../../providers/asistencia_provider.dart';
import '../../providers/socios_provider.dart';
import '../../widgets/loading_widget.dart';

class PagosScreen extends ConsumerWidget {
  const PagosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagosAsync = ref.watch(pagosProvider);
    final sociosAsync = ref.watch(sociosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pagos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber),
            tooltip: 'Multas Pendientes',
            onPressed: () => context.push('/pagos/multas'),
          ),
        ],
      ),
      body: pagosAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pagos) {
          final sociosMap = switch (sociosAsync) {
            AsyncData(:final value) => {for (final s in value) s.id: s},
            _ => <String?, SocioModel>{},
          };

          if (pagos.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.payment,
              title: 'No hay pagos registrados',
              subtitle: 'Los pagos aparecerán aquí cuando se registren',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(pagosProvider.notifier).loadPagos(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              itemCount: pagos.length,
              itemBuilder: (context, index) {
                final pago = pagos[index];
                final socio = sociosMap[pago.socioId];
                final codigo = socio?.numeroSocio;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: pago.estado == PaymentStatus.pagado
                          ? AppConstants.successColor.withOpacity(0.1)
                          : AppConstants.warningColor.withOpacity(0.1),
                      child: Icon(
                        pago.estado == PaymentStatus.pagado ? Icons.check : Icons.pending,
                        color: pago.estado == PaymentStatus.pagado ? AppConstants.successColor : AppConstants.warningColor,
                      ),
                    ),
                    title: Text(socio?.nombreCompleto ?? pago.socioNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (codigo != null && codigo.isNotEmpty)
                          Text('Código: $codigo', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        Text('${pago.tipo} - Bs. ${pago.monto.toStringAsFixed(2)}'),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: pago.estado == PaymentStatus.pagado
                            ? AppConstants.successColor.withOpacity(0.1)
                            : AppConstants.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pago.estado == PaymentStatus.pagado ? 'PAGADO' : 'PENDIENTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: pago.estado == PaymentStatus.pagado ? AppConstants.successColor : AppConstants.warningColor,
                        ),
                      ),
                    ),
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