import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/socio_model.dart';
import '../../providers/socios_provider.dart';
import '../../services/qr_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart' as app_date;
import '../../widgets/loading_widget.dart';

class SocioDetailScreen extends ConsumerWidget {
  final String socioId;
  
  const SocioDetailScreen({super.key, required this.socioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sociosAsync = ref.watch(sociosProvider);
    
    return sociosAsync.when(
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (e, st) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (socios) {
        final socio = socios.firstWhere(
          (s) => s.id == socioId,
          orElse: () => SocioModel(id: '', nombreCompleto: '', fechaRegistro: DateTime.now()),
        );
        
        if (socio.id == null || socio.id!.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Socio no encontrado')),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalles del Socio'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/socios/$socioId/editar'),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar eliminación'),
                        content: const Text('¿Está seguro de eliminar este socio?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      await ref.read(sociosProvider.notifier).deleteSocio(socioId);
                      if (context.mounted) context.pop();
                    }
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(socio),
                const SizedBox(height: 24),
                _buildInfoCard(socio),
                const SizedBox(height: 24),
                _buildQrCard(socio, ref, context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(SocioModel socio) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            socio.nombreCompleto.isNotEmpty ? socio.nombreCompleto[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          socio.nombreCompleto,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: socio.estado == 'Activo' ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            socio.estado,
            style: TextStyle(color: socio.estado == 'Activo' ? AppColors.success : AppColors.error, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(SocioModel socio) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Información', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (socio.numeroSocio != null && socio.numeroSocio!.isNotEmpty)
              _buildInfoRow(Icons.numbers, 'N° Socio', socio.numeroSocio!),
            _buildInfoRow(Icons.badge, 'Cédula', socio.ci.isNotEmpty ? socio.ci : '-'),
            _buildInfoRow(Icons.phone, 'Teléfono', socio.telefono ?? '-'),
            _buildInfoRow(Icons.location_on, 'Dirección', socio.direccion ?? '-'),
            _buildInfoRow(Icons.calendar_today, 'Fecha de registro', app_date.DateUtils.formatDate(socio.fechaRegistro)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(SocioModel socio, WidgetRef ref, BuildContext context) {
    final qrData = socio.qrCode ?? QrService.generateSocioQr(socio.id!, socio.ci);
    final needsSave = socio.qrCode == null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Código QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            QrImageView(
              data: qrData,
              size: 200,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 8),
            const Text('Escanee este código para registrar asistencia', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            if (needsSave) ...[
              const SizedBox(height: 12),
              const Text(
                'Este código debe ser guardado para usarse permanentemente',
                style: TextStyle(color: Colors.orange, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _saveQrCode(ref, socio, qrData, context),
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Guardar Código QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveQrCode(WidgetRef ref, SocioModel socio, String qrData, BuildContext context) async {
    try {
      final updatedSocio = socio.copyWith(qrCode: qrData);
      await ref.read(sociosProvider.notifier).updateSocio(updatedSocio);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código QR guardado correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar QR: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}