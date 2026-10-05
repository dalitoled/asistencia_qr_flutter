import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/socios_provider.dart';
import '../../models/asistencia_model.dart';
import '../../models/socio_model.dart';
import '../../providers/asistencia_provider.dart';
import '../asistencia/session_config_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final asistenciasHoy = ref.watch(asistenciaHoyProvider);
    final sociosAsync = ref.watch(sociosProvider);

    final userName = authAsync.valueOrNull?.name ?? 'Administrador';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AAP Tolata Chico', style: TextStyle(fontSize: 18)),
            Text(userName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.block),
            tooltip: 'Cerrar día - marcar faltas',
            onPressed: () => _cerrarDia(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(currentUserProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(context, userName),
            const SizedBox(height: 16),
            _buildSessionConfigCard(context, ref),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => _buildStatsOverview(
                socioCount: stats['socios']?.toString() ?? '0',
                asistenciaCount: stats['asistenciaHoy']?.toString() ?? '0',
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => _buildStatsOverview(socioCount: '0', asistenciaCount: '0'),
            ),
            const SizedBox(height: 24),
            Text(
              'Acciones Rápidas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildActionGrid(context),
            const SizedBox(height: 24),
            asistenciasHoy.when(
              data: (asistencias) => sociosAsync.when(
                data: (socios) => _buildAsistenciasSocios(context, socios, asistencias),
                loading: () => const SizedBox(),
                error: (_, __) => _buildRecentActivity(context, asistencias),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/qr-scanner'),
        label: const Text('ESCANEAR QR'),
        icon: const Icon(Icons.qr_code_scanner),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, $userName',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          'Gestiona el control de agua el día de hoy',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview({required String socioCount, required String asistenciaCount}) {
    return Row(
      children: [
        _buildStatCard(
          'Socios',
          socioCount,
          Icons.people,
          Colors.blue,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Asistencias Hoy',
          asistenciaCount,
          Icons.check_circle,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          context,
          'Socios',
          Icons.person_add,
          Colors.indigo,
          () => context.push('/socios'),
        ),
        _buildActionCard(
          context,
          'Pagos',
          Icons.monetization_on,
          Colors.orange,
          () => context.push('/pagos'),
        ),
        _buildActionCard(
          context,
          'Multas',
          Icons.warning_amber,
          Colors.red,
          () => context.push('/pagos/multas'),
        ),
        _buildActionCard(
          context,
          'Reportes',
          Icons.bar_chart,
          Colors.teal,
          () => context.push('/reportes'),
        ),
        _buildActionCard(
          context,
          'Ajustes',
          Icons.settings,
          Colors.blueGrey,
          () => context.push('/settings'),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsistenciasSocios(BuildContext context, List<SocioModel> socios, List<AsistenciaModel> asistencias) {
    final asistenciaMap = {for (final a in asistencias) a.socioId: a};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Estado de Socios Hoy',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text('${socios.length} socios', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: socios.length,
          itemBuilder: (context, index) {
            final socio = socios[index];
            final asistencia = asistenciaMap[socio.id];

            final bool tieneAsistencia = asistencia != null;
            final bool esRetraso = tieneAsistencia && asistencia.tipo == TipoAsistencia.retraso;

            final Color statusColor = tieneAsistencia
                ? (esRetraso ? Colors.orange : Colors.green)
                : Colors.grey;
            final String statusText = tieneAsistencia
                ? (esRetraso ? 'RETRASO' : 'PRESENTE')
                : 'SIN REGISTRO';
            final String? hora = tieneAsistencia
                ? '${asistencia.fecha.hour.toString().padLeft(2, '0')}:${asistencia.fecha.minute.toString().padLeft(2, '0')}'
                : null;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.2),
                child: Text(
                  socio.nombreCompleto[0].toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(socio.nombreCompleto, style: const TextStyle(fontSize: 14)),
              subtitle: socio.numeroSocio != null && socio.numeroSocio!.isNotEmpty
                  ? Text('Código: ${socio.numeroSocio}', style: TextStyle(fontSize: 11, color: Colors.grey[600]))
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hora != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(hora, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, List<AsistenciaModel> asistencias) {
    if (asistencias.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Asistencias Hoy',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: asistencias.length > 5 ? 5 : asistencias.length,
          itemBuilder: (context, index) {
            final a = asistencias[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppConstants.primaryColor,
                child: Text(
                  a.socioNombre[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(a.socioNombre),
              subtitle: Text('${a.tipo == TipoAsistencia.asistencia ? 'Asistencia' : 'Retraso'} · ${a.fecha.hour.toString().padLeft(2, '0')}:${a.fecha.minute.toString().padLeft(2, '0')}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (a.tipo == TipoAsistencia.asistencia ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  a.tipo == TipoAsistencia.asistencia ? 'PRESENTE' : 'RETRASO',
                  style: TextStyle(
                    color: a.tipo == TipoAsistencia.asistencia ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSessionConfigCard(BuildContext context, WidgetRef ref) {
    final sessionConfig = ref.watch(sessionConfigProvider);
    final configAsync = ref.watch(configProvider);

    return configAsync.when(
      data: (config) {
        final bool isSessionActive = sessionConfig != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
            side: BorderSide(
              color: isSessionActive ? Colors.green.withOpacity(0.5) : Colors.amber.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isSessionActive ? Icons.play_circle_fill : Icons.pause_circle_filled,
                          color: isSessionActive ? Colors.green : Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isSessionActive ? 'Jornada Activa' : 'Jornada no Iniciada',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSessionActive ? Colors.green[700] : Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                    if (isSessionActive)
                      TextButton.icon(
                        onPressed: () {
                          ref.read(sessionConfigProvider.notifier).clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Jornada finalizada'),
                              backgroundColor: AppConstants.warningColor,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.stop, color: Colors.red, size: 18),
                        label: const Text('Finalizar', style: TextStyle(color: Colors.red, fontSize: 13)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isSessionActive
                      ? 'Tipo: ${sessionConfig.tipoSesionLabel}\nMultas: Retraso ${sessionConfig.multaRetraso.toStringAsFixed(2)} Bs | Falta ${sessionConfig.multaFalta.toStringAsFixed(2)} Bs'
                      : 'Configura el tipo de sesión y las multas aplicables para el registro del día de hoy.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<SessionConfig>(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => SessionConfigDialog(
                            config: config,
                            currentConfig: sessionConfig,
                          ),
                        );
                        if (result != null) {
                          ref.read(sessionConfigProvider.notifier).setConfig(result);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isSessionActive ? 'Jornada modificada con éxito' : 'Jornada iniciada con éxito'),
                                backgroundColor: AppConstants.successColor,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSessionActive ? Colors.grey[200] : AppConstants.primaryColor,
                        foregroundColor: isSessionActive ? Colors.black87 : Colors.white,
                        elevation: isSessionActive ? 0 : 2,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      icon: Icon(isSessionActive ? Icons.edit : Icons.settings),
                      label: Text(isSessionActive ? 'Modificar' : 'Configurar Registro'),
                    ),
                    if (isSessionActive) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/qr-scanner'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Escanear QR'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(),
    );
  }
}

Future<void> _cerrarDia(BuildContext context, WidgetRef ref) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cerrar día'),
      content: const Text('¿Marcar como falta a todos los socios que no registraron asistencia hoy?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('CERRAR DÍA'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    final service = ref.read(asistenciaServiceProvider);
    final count = await service.registrarFaltasDelDia();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count falta(s) registrada(s) para hoy'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }
}