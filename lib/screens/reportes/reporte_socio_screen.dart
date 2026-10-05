import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../models/multa_model.dart';
import '../../models/pago_model.dart';
import '../../models/socio_model.dart';
import '../../services/export_service.dart';
import '../../services/firestore_service.dart';
import '../../providers/socios_provider.dart';

class ReporteSocioScreen extends ConsumerStatefulWidget {
  const ReporteSocioScreen({super.key});

  @override
  ConsumerState<ReporteSocioScreen> createState() => _ReporteSocioScreenState();
}

class _ReporteSocioScreenState extends ConsumerState<ReporteSocioScreen> {
  SocioModel? _socioSeleccionado;
  int _mesSeleccionado = DateTime.now().month;
  int _anioSeleccionado = DateTime.now().year;
  bool _isLoading = false;
  List<MultaModel>? _multas;
  List<PaymentModel>? _pagos;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final _fmtMonto = NumberFormat('#,##0.00', 'es');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    if (_socioSeleccionado == null) return;
    setState(() {
      _isLoading = true;
      _multas = null;
      _pagos = null;
    });
    try {
      final service = ref.read(firestoreServiceProvider);
      final multas = await service.getMultas(socioId: _socioSeleccionado!.id);
      final pagos = await service.getPagos(socioId: _socioSeleccionado!.id);
      setState(() {
        _multas = multas;
        _pagos = pagos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e'), backgroundColor: AppConstants.errorColor),
        );
      }
    }
  }

  List<MultaModel> get _multasFiltradas {
    if (_multas == null) return [];
    return _multas!
        .where((m) => m.fecha.month == _mesSeleccionado && m.fecha.year == _anioSeleccionado)
        .toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
  }

  List<PaymentModel> get _pagosFiltrados {
    if (_pagos == null) return [];
    return _pagos!
        .where((p) => p.fecha.month == _mesSeleccionado && p.fecha.year == _anioSeleccionado)
        .toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
  }

  Future<void> _exportarPdf() async {
    if (_socioSeleccionado == null) return;
    setState(() => _isLoading = true);
    try {
      await ExportService.exportReporteMensualPdf(
        socio: _socioSeleccionado!,
        mes: _mesSeleccionado,
        anio: _anioSeleccionado,
        multas: _multas ?? [],
        pagos: _pagos ?? [],
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportarExcel() async {
    if (_socioSeleccionado == null) return;
    setState(() => _isLoading = true);
    try {
      final path = await ExportService.exportReporteMensualExcel(
        socio: _socioSeleccionado!,
        mes: _mesSeleccionado,
        anio: _anioSeleccionado,
        multas: _multas ?? [],
        pagos: _pagos ?? [],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel guardado en: $path'),
            backgroundColor: AppConstants.successColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'), backgroundColor: AppConstants.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sociosAsync = ref.watch(sociosProvider);
    final mesNombre = DateFormat('MMMM yyyy', 'es').format(DateTime(_anioSeleccionado, _mesSeleccionado));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte por Socio'),
        actions: [
          if (_socioSeleccionado != null && _multas != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.download),
              onSelected: (value) {
                if (value == 'pdf') _exportarPdf();
                if (value == 'excel') _exportarExcel();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'pdf', child: ListTile(
                  leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text('Exportar PDF'),
                  dense: true,
                )),
                PopupMenuItem(value: 'excel', child: ListTile(
                  leading: Icon(Icons.table_chart, color: Colors.green),
                  title: Text('Exportar Excel'),
                  dense: true,
                )),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Selector de Socio ─────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Seleccionar Socio',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 10),
                          sociosAsync.when(
                            loading: () => const CircularProgressIndicator(),
                            error: (e, _) => Text('Error: $e'),
                            data: (socios) {
                              final filtrados = _searchQuery.isEmpty
                                  ? socios
                                  : socios
                                      .where((s) =>
                                          s.nombreCompleto.toLowerCase().contains(_searchQuery) ||
                                          s.ci.contains(_searchQuery) ||
                                          (s.numeroSocio?.toLowerCase().contains(_searchQuery) ?? false))
                                      .toList();
                              return Column(
                                children: [
                                  TextField(
                                    controller: _searchCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Buscar por nombre, CI o código...',
                                      prefixIcon: const Icon(Icons.search, size: 20),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, size: 18),
                                              onPressed: () {
                                                _searchCtrl.clear();
                                                setState(() => _searchQuery = '');
                                              })
                                          : null,
                                      isDense: true,
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: (v) =>
                                        setState(() => _searchQuery = v.toLowerCase()),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<SocioModel>(
                                    value: _socioSeleccionado,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                      labelText: 'Socio',
                                    ),
                                    items: filtrados
                                        .map((s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(
                                                s.numeroSocio != null && s.numeroSocio!.isNotEmpty
                                                    ? '${s.nombreCompleto} (${s.numeroSocio})'
                                                    : s.nombreCompleto,
                                                style: const TextStyle(fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (s) {
                                      setState(() => _socioSeleccionado = s);
                                      _cargarDatos();
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Selector de Período ───────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 20, color: AppConstants.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Período:', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<int>(
                              value: _mesSeleccionado,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: List.generate(12, (i) => i + 1)
                                  .map((m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(DateFormat('MMMM', 'es').format(DateTime(2000, m))),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _mesSeleccionado = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<int>(
                              value: _anioSeleccionado,
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: [
                                DateTime.now().year - 1,
                                DateTime.now().year,
                                DateTime.now().year + 1,
                              ]
                                  .map((y) => DropdownMenuItem(
                                        value: y,
                                        child: Text(y.toString()),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _anioSeleccionado = v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_socioSeleccionado == null) ...[
                    const SizedBox(height: 40),
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.person_search, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Selecciona un socio para ver su reporte mensual',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ] else if (_multas == null) ...[
                    const SizedBox(height: 40),
                    const Center(child: CircularProgressIndicator()),
                  ] else ...[
                    // ── Encabezado del socio ──────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppConstants.primaryColor, AppConstants.primaryColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_socioSeleccionado!.nombreCompleto,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('CI: ${_socioSeleccionado!.ci} • Período: $mesNombre',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Tarjetas de resumen ───────────────────────────
                    _buildResumenCards(),
                    const SizedBox(height: 12),

                    // ── Botones de exportación ────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportarPdf,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Ver PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportarExcel,
                            icon: const Icon(Icons.table_chart),
                            label: const Text('Exportar Excel'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Tabla de Multas ───────────────────────────────
                    _buildSeccionMultas(),
                    const SizedBox(height: 12),

                    // ── Tabla de Pagos ────────────────────────────────
                    _buildSeccionPagos(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildResumenCards() {
    final multas = _multasFiltradas;
    final pagos = _pagosFiltrados;
    final totalMultas = multas.fold<double>(0, (s, m) => s + m.monto);
    final pendiente = multas
        .where((m) => m.estado == EstadoMulta.pendiente)
        .fold<double>(0, (s, m) => s + m.monto);
    final totalPagos = pagos.fold<double>(0, (s, p) => s + p.monto);

    return Row(
      children: [
        _resumenCard('Multas\ntotales', 'Bs. ${_fmtMonto.format(totalMultas)}',
            Icons.warning_amber, Colors.red),
        const SizedBox(width: 8),
        _resumenCard('Saldo\npendiente', 'Bs. ${_fmtMonto.format(pendiente)}',
            Icons.pending_actions, Colors.orange),
        const SizedBox(width: 8),
        _resumenCard('Pagos\nrecibidos', 'Bs. ${_fmtMonto.format(totalPagos)}',
            Icons.payments, Colors.green),
      ],
    );
  }

  Widget _resumenCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionMultas() {
    final multas = _multasFiltradas;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                const SizedBox(width: 6),
                Text('Multas del período (${multas.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(),
            if (multas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                    child: Text('Sin multas en este período',
                        style: TextStyle(color: Colors.grey))),
              )
            else
              ...multas.map((m) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (m.tipo == TipoMulta.falta ? Colors.red : Colors.orange)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        m.tipo == TipoMulta.falta ? Icons.cancel : Icons.timer_off,
                        size: 16,
                        color: m.tipo == TipoMulta.falta ? Colors.red : Colors.orange,
                      ),
                    ),
                    title: Text(m.tipoString,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy').format(m.fecha)}  •  ${m.observaciones ?? ''}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Bs. ${_fmtMonto.format(m.monto)}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (m.estado == EstadoMulta.pagado ? Colors.green : Colors.red)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            m.estadoString.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: m.estado == EstadoMulta.pagado ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionPagos() {
    final pagos = _pagosFiltrados;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Text('Pagos del período (${pagos.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(),
            if (pagos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                    child: Text('Sin pagos registrados en este período',
                        style: TextStyle(color: Colors.grey))),
              )
            else
              ...pagos.map((p) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    ),
                    title: Text(p.tipo,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy').format(p.fecha)}  •  ${p.observaciones ?? ''}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Text(
                      'Bs. ${_fmtMonto.format(p.monto)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
