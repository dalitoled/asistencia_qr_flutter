import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../models/asistencia_model.dart';
import '../../models/multa_model.dart';
import '../../models/socio_model.dart';
import '../../providers/asistencia_provider.dart';
import '../../providers/socios_provider.dart';
import '../../services/export_service.dart';

enum VistaReporte { porSocio, porDia, porMes, retrasos, faltas }

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  VistaReporte _vista = VistaReporte.porSocio;
  final Set<String> _sociosExpandidos = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarRango() async {
    final current = ref.read(reporteFechaProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: current,
      locale: const Locale('es', 'BO'),
    );
    if (picked != null) {
      ref.read(reporteFechaProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rango = ref.watch(reporteFechaProvider);
    final asistenciasAsync = ref.watch(asistenciasPorRangoProvider(rango));
    final multasAsync = ref.watch(multasPorRangoProvider(rango));
    final sociosAsync = ref.watch(sociosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rango de fechas', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _seleccionarRango,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat('dd/MM/yyyy').format(rango.start)} - ${DateFormat('dd/MM/yyyy').format(rango.end)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Reporte por socio (nuevo)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppConstants.primaryColor.withOpacity(0.4), width: 1.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/reportes/socio'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_search, color: AppConstants.primaryColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reporte Mensual por Socio',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            SizedBox(height: 4),
                            Text(
                              'Multas y pagos individuales en PDF o Excel por mes',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Exportar Reportes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _exportarPdf(asistenciasAsync, multasAsync, sociosAsync),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar a PDF'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _exportarExcel(asistenciasAsync, multasAsync, sociosAsync),
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Exportar a Excel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resumen del Período', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    asistenciasAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                      data: (asistencias) {
                        final presentes = asistencias.where((a) => a.tipo == TipoAsistencia.asistencia).length;
                        final retrasos = asistencias.where((a) => a.tipo == TipoAsistencia.retraso).length;
                        return Column(
                          children: [
                            _buildStatRow('Total asistencias', asistencias.length.toString(), Colors.blue),
                            _buildStatRow('Presentes', presentes.toString(), Colors.green),
                            _buildStatRow('Retrasos', retrasos.toString(), Colors.orange),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    multasAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (multas) {
                        final faltas = multas.where((m) => m.tipo == TipoMulta.falta).length;
                        final multasRetraso = multas.where((m) => m.tipo == TipoMulta.retraso).length;
                        return Column(
                          children: [
                            _buildStatRow('Faltas', faltas.toString(), Colors.red),
                            _buildStatRow('Multas por retraso', multasRetraso.toString(), Colors.deepOrange),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Detalle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        DropdownButton<VistaReporte>(
                          value: _vista,
                          underline: const SizedBox(),
                          isDense: true,
                          items: const [
                            DropdownMenuItem(value: VistaReporte.porSocio, child: Text('Por Socio')),
                            DropdownMenuItem(value: VistaReporte.porDia, child: Text('Por Día')),
                            DropdownMenuItem(value: VistaReporte.porMes, child: Text('Por Mes')),
                            DropdownMenuItem(value: VistaReporte.retrasos, child: Text('Retrasos')),
                            DropdownMenuItem(value: VistaReporte.faltas, child: Text('Faltas')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _vista = v);
                          },
                        ),
                      ],
                    ),
                    if (_vista == VistaReporte.porSocio) ...[
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar socio por nombre o código...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildDetalle(asistenciasAsync, multasAsync, sociosAsync),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalle(
    AsyncValue<List<AsistenciaModel>> asistenciasAsync,
    AsyncValue<List<MultaModel>> multasAsync,
    AsyncValue<List<SocioModel>> sociosAsync,
  ) {
    final asistencias = asistenciasAsync.valueOrNull ?? [];
    final multas = multasAsync.valueOrNull ?? [];
    final socios = sociosAsync.valueOrNull ?? [];
    final sociosMap = {for (final s in socios) s.id: s};

    switch (_vista) {
      case VistaReporte.porSocio:
        return _buildPorSocio(asistencias, multas, sociosMap);
      case VistaReporte.porDia:
        return _buildPorDia(asistencias, multas);
      case VistaReporte.porMes:
        return _buildPorMes(asistencias, multas);
      case VistaReporte.retrasos:
        return _buildRetrasos(asistencias, multas, sociosMap);
      case VistaReporte.faltas:
        return _buildFaltas(asistencias, multas, sociosMap);
    }
  }

  Widget _buildPorSocio(
    List<AsistenciaModel> asistencias,
    List<MultaModel> multas,
    Map<String?, SocioModel> sociosMap,
  ) {
    final sociosData = <String, _SocioDetalle>{};
    for (final a in asistencias) {
      sociosData.putIfAbsent(a.socioId, () => _SocioDetalle());
      sociosData[a.socioId]!.registros.add(_Registro(
        tipo: a.tipo == TipoAsistencia.asistencia ? 'Presente' : 'Retraso',
        fecha: a.fecha,
      ));
    }
    for (final m in multas) {
      sociosData.putIfAbsent(m.socioId, () => _SocioDetalle());
      final tipo = m.tipo == TipoMulta.falta ? 'Falta' : 'Multa Retraso';
      sociosData[m.socioId]!.registros.add(_Registro(
        tipo: tipo,
        fecha: m.fecha,
        monto: m.monto,
        pagado: m.estado == EstadoMulta.pagado ? 'Pagado' : 'Pendiente',
      ));
    }

    if (sociosData.isEmpty) {
      return const Center(child: Text('Sin datos en el período seleccionado'));
    }

    var sorted = sociosData.entries.toList()
      ..sort((a, b) => sociosMap[a.key]?.nombreCompleto.compareTo(sociosMap[b.key]?.nombreCompleto ?? '') ?? 0);

    if (_searchQuery.isNotEmpty) {
      sorted = sorted.where((e) {
        final socio = sociosMap[e.key];
        final nombre = socio?.nombreCompleto.toLowerCase() ?? '';
        final codigo = socio?.numeroSocio?.toLowerCase() ?? '';
        return nombre.contains(_searchQuery) || codigo.contains(_searchQuery);
      }).toList();
    }

    if (sorted.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Center(child: Text('No se encontraron socios con ese criterio')),
      );
    }

    return Column(
      children: sorted.map((e) {
        final socio = sociosMap[e.key];
        final nombre = socio?.nombreCompleto ?? e.key ?? 'Desconocido';
        final codigo = socio?.numeroSocio;
        final expanded = _sociosExpandidos.contains(e.key);
        final detalle = e.value;

        final presentes = detalle.registros.where((r) => r.tipo == 'Presente').length;
        final retrasos = detalle.registros.where((r) => r.tipo == 'Retraso' || r.tipo == 'Multa Retraso').length;
        final faltas = detalle.registros.where((r) => r.tipo == 'Falta').length;
        final deuda = detalle.registros.where((r) => r.pagado == 'Pendiente').fold<double>(0, (sum, r) => sum + (r.monto ?? 0));

        return Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  if (expanded) {
                    _sociosExpandidos.remove(e.key);
                  } else {
                    _sociosExpandidos.add(e.key);
                  }
                });
              },
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 20),
                title: Text(
                  codigo != null && codigo.isNotEmpty ? '$nombre ($codigo)' : nombre,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    if (presentes > 0) _chip('P:$presentes', Colors.green),
                    if (retrasos > 0) _chip('R:$retrasos', Colors.orange),
                    if (faltas > 0) _chip('F:$faltas', Colors.red),
                    if (deuda > 0) _chip('Bs.${deuda.toStringAsFixed(0)}', Colors.red),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  children: detalle.registros.map((r) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    title: Text(r.tipo, style: const TextStyle(fontSize: 12)),
                    subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(r.fecha),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    trailing: r.monto != null
                        ? Text(
                            'Bs.${r.monto!.toStringAsFixed(2)} ${r.pagado ?? ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: r.pagado == 'Pagado' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  )).toList(),
                ),
              ),
            const Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPorDia(List<AsistenciaModel> asistencias, List<MultaModel> multas) {
    final dias = <DateTime, _DiaStats>{};
    for (final a in asistencias) {
      final dia = DateTime(a.fecha.year, a.fecha.month, a.fecha.day);
      dias.putIfAbsent(dia, () => _DiaStats());
      if (a.tipo == TipoAsistencia.asistencia) dias[dia]!.presentes++;
      if (a.tipo == TipoAsistencia.retraso) dias[dia]!.retrasos++;
    }
    for (final m in multas.where((m) => m.tipo == TipoMulta.falta)) {
      final dia = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);
      dias.putIfAbsent(dia, () => _DiaStats());
      dias[dia]!.faltas++;
    }

    if (dias.isEmpty) {
      return const Center(child: Text('Sin datos en el período seleccionado'));
    }

    final sorted = dias.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      children: sorted.map((e) {
        final stats = e.value;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(DateFormat('EEEE d MMMM yyyy', 'es').format(e.key),
              style: const TextStyle(fontSize: 13)),
          trailing: Wrap(
            spacing: 6,
            children: [
              _chip('P:${stats.presentes}', Colors.green),
              _chip('R:${stats.retrasos}', Colors.orange),
              _chip('F:${stats.faltas}', Colors.red),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPorMes(List<AsistenciaModel> asistencias, List<MultaModel> multas) {
    final meses = <String, _DiaStats>{};
    for (final a in asistencias) {
      final key = '${a.fecha.year}-${a.fecha.month.toString().padLeft(2, '0')}';
      meses.putIfAbsent(key, () => _DiaStats());
      if (a.tipo == TipoAsistencia.asistencia) meses[key]!.presentes++;
      if (a.tipo == TipoAsistencia.retraso) meses[key]!.retrasos++;
    }
    for (final m in multas.where((m) => m.tipo == TipoMulta.falta)) {
      final key = '${m.fecha.year}-${m.fecha.month.toString().padLeft(2, '0')}';
      meses.putIfAbsent(key, () => _DiaStats());
      meses[key]!.faltas++;
    }

    if (meses.isEmpty) {
      return const Center(child: Text('Sin datos en el período seleccionado'));
    }

    final sorted = meses.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      children: sorted.map((e) {
        final parts = e.key.split('-');
        final month = int.parse(parts[1]);
        final year = int.parse(parts[0]);
        final date = DateTime(year, month);
        final stats = e.value;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(DateFormat('MMMM yyyy', 'es').format(date),
              style: const TextStyle(fontSize: 13)),
          trailing: Wrap(
            spacing: 6,
            children: [
              _chip('P:${stats.presentes}', Colors.green),
              _chip('R:${stats.retrasos}', Colors.orange),
              _chip('F:${stats.faltas}', Colors.red),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRetrasos(
    List<AsistenciaModel> asistencias,
    List<MultaModel> multas,
    Map<String?, SocioModel> sociosMap,
  ) {
    final retrasos = asistencias.where((a) => a.tipo == TipoAsistencia.retraso).toList();
    if (retrasos.isEmpty) {
      return const Center(child: Text('Sin retrasos en el período seleccionado'));
    }

    final multaMap = <String, List<MultaModel>>{};
    for (final m in multas.where((m) => m.tipo == TipoMulta.retraso)) {
      multaMap.putIfAbsent(m.socioId, () => []);
      multaMap[m.socioId]!.add(m);
    }

    return Column(
      children: retrasos.map((a) {
        final socio = sociosMap[a.socioId];
        final nombre = socio?.nombreCompleto ?? a.socioNombre;
        final codigo = socio?.numeroSocio;
        final multasSocio = multaMap[a.socioId] ?? [];
        final totalDeuda = multasSocio.where((m) => m.estado == EstadoMulta.pendiente).fold<double>(0, (s, m) => s + m.monto);
        final totalPagado = multasSocio.where((m) => m.estado == EstadoMulta.pagado).fold<double>(0, (s, m) => s + m.monto);

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            codigo != null && codigo.isNotEmpty ? '$nombre ($codigo)' : nombre,
            style: const TextStyle(fontSize: 13),
          ),
          subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(a.fecha),
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (multasSocio.isNotEmpty)
                Text('Bs.${totalDeuda.toStringAsFixed(2)} pend.',
                    style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
              if (totalPagado > 0)
                Text('Bs.${totalPagado.toStringAsFixed(2)} pagado',
                    style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFaltas(
    List<AsistenciaModel> asistencias,
    List<MultaModel> multas,
    Map<String?, SocioModel> sociosMap,
  ) {
    final faltas = multas.where((m) => m.tipo == TipoMulta.falta).toList();
    if (faltas.isEmpty) {
      return const Center(child: Text('Sin faltas en el período seleccionado'));
    }

    return Column(
      children: faltas.map((m) {
        final socio = sociosMap[m.socioId];
        final nombre = socio?.nombreCompleto ?? m.socioNombre;
        final codigo = socio?.numeroSocio;
        final pagado = m.estado == EstadoMulta.pagado;

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            codigo != null && codigo.isNotEmpty ? '$nombre ($codigo)' : nombre,
            style: const TextStyle(fontSize: 13),
          ),
          subtitle: Text(DateFormat('dd/MM/yyyy').format(m.fecha),
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bs.${m.monto.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: pagado ? Colors.green : Colors.red,
                  )),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (pagado ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  pagado ? 'PAGADO' : 'PENDIENTE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: pagado ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportarPdf(
    AsyncValue<List<AsistenciaModel>> asistenciasAsync,
    AsyncValue<List<MultaModel>> multasAsync,
    AsyncValue<List<SocioModel>> sociosAsync,
  ) async {
    final asistencias = asistenciasAsync.valueOrNull ?? [];
    final multas = multasAsync.valueOrNull ?? [];
    final socios = sociosAsync.valueOrNull ?? [];
    final sociosMap = {for (final s in socios) s.id: s};

    final data = <Map<String, dynamic>>[];
    for (final a in asistencias) {
      final socio = sociosMap[a.socioId];
      data.add({
        'socio': socio?.nombreCompleto ?? a.socioNombre,
        'ci': socio?.ci ?? '',
        'tipo': a.tipo == TipoAsistencia.asistencia ? 'Presente' : 'Retraso',
        'fecha': DateFormat('dd/MM/yyyy HH:mm').format(a.fecha),
      });
    }
    for (final m in multas.where((m) => m.tipo == TipoMulta.falta)) {
      final socio = sociosMap[m.socioId];
      data.add({
        'socio': socio?.nombreCompleto ?? m.socioNombre,
        'ci': socio?.ci ?? '',
        'tipo': 'Falta',
        'fecha': DateFormat('dd/MM/yyyy').format(m.fecha),
      });
    }

    await ExportService.exportToPdfWithData(data);
  }

  Future<void> _exportarExcel(
    AsyncValue<List<AsistenciaModel>> asistenciasAsync,
    AsyncValue<List<MultaModel>> multasAsync,
    AsyncValue<List<SocioModel>> sociosAsync,
  ) async {
    final asistencias = asistenciasAsync.valueOrNull ?? [];
    final multas = multasAsync.valueOrNull ?? [];
    final socios = sociosAsync.valueOrNull ?? [];
    final sociosMap = {for (final s in socios) s.id: s};

    final data = <Map<String, dynamic>>[];
    for (final a in asistencias) {
      final socio = sociosMap[a.socioId];
      data.add({
        'socio': socio?.nombreCompleto ?? a.socioNombre,
        'ci': socio?.ci ?? '',
        'tipo': a.tipo == TipoAsistencia.asistencia ? 'Presente' : 'Retraso',
        'fecha': DateFormat('dd/MM/yyyy HH:mm').format(a.fecha),
      });
    }
    for (final m in multas.where((m) => m.tipo == TipoMulta.falta)) {
      final socio = sociosMap[m.socioId];
      data.add({
        'socio': socio?.nombreCompleto ?? m.socioNombre,
        'ci': socio?.ci ?? '',
        'tipo': 'Falta',
        'fecha': DateFormat('dd/MM/yyyy').format(m.fecha),
      });
    }

    await ExportService.exportToExcelWithData(data);
  }
}

class _Registro {
  final String tipo;
  final DateTime fecha;
  final double? monto;
  final String? pagado;
  _Registro({required this.tipo, required this.fecha, this.monto, this.pagado});
}

class _SocioDetalle {
  final List<_Registro> registros = [];
}

class _DiaStats {
  int presentes = 0;
  int retrasos = 0;
  int faltas = 0;
}
