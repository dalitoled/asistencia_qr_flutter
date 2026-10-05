import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/asistencia_model.dart';
import '../models/multa_model.dart';
import '../models/pago_model.dart';
import '../models/config_model.dart';
import '../services/firestore_service.dart';
import '../core/utils/date_utils.dart' as app_date;
import 'socios_provider.dart';

final configProvider = StateNotifierProvider<ConfigNotifier, AsyncValue<ConfigModel>>((ref) {
  return ConfigNotifier(ref.watch(firestoreServiceProvider));
});

class SessionConfig {
  final String tipoSesion;
  final double multaRetraso;
  final double multaFalta;

  SessionConfig({
    required this.tipoSesion,
    required this.multaRetraso,
    required this.multaFalta,
  });

  String get tipoSesionLabel {
    switch (tipoSesion) {
      case 'ordinaria': return 'Reunión Ordinaria';
      case 'extraordinaria': return 'Reunión Extraordinaria';
      case 'desfile': return 'Desfile';
      case 'otro': return 'Otro';
      default: return tipoSesion;
    }
  }
}

final sessionConfigProvider = StateNotifierProvider<SessionConfigNotifier, SessionConfig?>((ref) {
  return SessionConfigNotifier(ref);
});

class SessionConfigNotifier extends StateNotifier<SessionConfig?> {
  final Ref _ref;

  SessionConfigNotifier(this._ref) : super(null);

  void setConfig(SessionConfig config) {
    state = config;
  }

  void clear() {
    state = null;
  }
}

final asistenciaHoyProvider = FutureProvider<List<AsistenciaModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAsistencias(fecha: DateTime.now());
});

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getDashboardStats();
});

final multasProvider = StateNotifierProvider<MultasNotifier, AsyncValue<List<MultaModel>>>((ref) {
  return MultasNotifier(ref.watch(firestoreServiceProvider));
});

final pagosProvider = StateNotifierProvider<PagosNotifier, AsyncValue<List<PaymentModel>>>((ref) {
  return PagosNotifier(ref.watch(firestoreServiceProvider));
});

class ConfigNotifier extends StateNotifier<AsyncValue<ConfigModel>> {
  final FirestoreService _firestoreService;

  ConfigNotifier(this._firestoreService) : super(const AsyncValue.loading()) {
    loadConfig();
  }

  Future<void> loadConfig() async {
    try {
      final config = await _firestoreService.getConfig();
      state = AsyncValue.data(config);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateConfig(ConfigModel config) async {
    try {
      await _firestoreService.updateConfig(config);
      state = AsyncValue.data(config);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

class MultasNotifier extends StateNotifier<AsyncValue<List<MultaModel>>> {
  final FirestoreService _firestoreService;

  MultasNotifier(this._firestoreService) : super(const AsyncValue.loading()) {
    loadMultas();
  }

  Future<void> loadMultas({String? socioId, bool? pendientes}) async {
    state = const AsyncValue.loading();
    try {
      final multas = await _firestoreService.getMultas(socioId: socioId, pendientes: pendientes);
      state = AsyncValue.data(multas);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> createMulta(MultaModel multa) async {
    try {
      final docId = await _firestoreService.createMulta(multa);
      await loadMultas();
      return docId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> pagarMulta(MultaModel multa, String idPago) async {
    try {
      final multaPagada = multa.copyWith(
        estado: EstadoMulta.pagado,
        idPago: idPago,
      );
      await _firestoreService.updateMulta(multaPagada);
      await loadMultas();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> pagarMultaConMonto(MultaModel multa, double monto, String idPago) async {
    try {
      final multaPagada = multa.copyWith(
        estado: EstadoMulta.pagado,
        monto: monto,
        idPago: idPago,
      );
      await _firestoreService.updateMulta(multaPagada);
      await loadMultas();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

class PagosNotifier extends StateNotifier<AsyncValue<List<PaymentModel>>> {
  final FirestoreService _firestoreService;

  PagosNotifier(this._firestoreService) : super(const AsyncValue.loading()) {
    loadPagos();
  }

  Future<void> loadPagos({String? socioId}) async {
    state = const AsyncValue.loading();
    try {
      final pagos = await _firestoreService.getPagos(socioId: socioId);
      state = AsyncValue.data(pagos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> createPago(PaymentModel pago) async {
    try {
      final id = await _firestoreService.createPago(pago);
      await loadPagos();
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final reporteFechaProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(start: DateTime(now.year, now.month), end: now);
});

final asistenciasPorRangoProvider = FutureProvider.family<List<AsistenciaModel>, DateTimeRange>((ref, rango) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final end = DateTime(rango.end.year, rango.end.month, rango.end.day, 23, 59, 59);
  return firestoreService.getAsistenciasByRange(rango.start, end);
});

final multasPorRangoProvider = FutureProvider.family<List<MultaModel>, DateTimeRange>((ref, rango) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final end = DateTime(rango.end.year, rango.end.month, rango.end.day, 23, 59, 59);
  return firestoreService.getMultasByRange(rango.start, end);
});

final asistenciaServiceProvider = Provider<AsistenciaService>((ref) {
  return AsistenciaService(ref.watch(firestoreServiceProvider), ref);
});

class AsistenciaService {
  final FirestoreService _firestoreService;
  final Ref _ref;

  AsistenciaService(this._firestoreService, this._ref);

  Future<AsistenciaModel> registrarAsistencia({
    required String socioId,
    required String socioNombre,
    required String socioCi,
    required String operadorId,
  }) async {
    final asistenciaExistente = await _firestoreService.getAsistenciaToday(socioId);
    if (asistenciaExistente != null) {
      throw Exception('El socio ya registro asistencia hoy');
    }

    final sessionConfig = _ref.read(sessionConfigProvider);
    final config = await _firestoreService.getConfig();
    final now = DateTime.now();
    final esRetraso = app_date.DateUtils.isAfterLimit(now, config.horaLimite);

    final tipo = esRetraso ? TipoAsistencia.retraso : TipoAsistencia.asistencia;
    final tipoSesion = sessionConfig?.tipoSesion;
    
    final asistencia = AsistenciaModel.create(
      socioId: socioId,
      socioNombre: socioNombre,
      socioCi: socioCi,
      tipo: tipo,
      operadorId: operadorId,
      tipoSesion: tipoSesion,
    );

    await _firestoreService.createAsistencia(asistencia);

    if (esRetraso) {
      final montoRetraso = sessionConfig?.multaRetraso ?? config.multaRetraso;
      final multa = MultaModel.create(
        socioId: socioId,
        socioNombre: socioNombre,
        tipo: TipoMulta.retraso,
        monto: montoRetraso,
        observaciones: 'Multa por retraso - ${sessionConfig?.tipoSesionLabel ?? ''}',
      );
      await _firestoreService.createMulta(multa);
    }

    _ref.invalidate(asistenciaHoyProvider);
    _ref.invalidate(dashboardStatsProvider);

    return asistencia;
  }

  Future<int> registrarFaltasDelDia() async {
    final socios = await _firestoreService.getSocios(activo: true);
    final hoy = DateTime.now();
    final asistenciasHoy = await _firestoreService.getAsistencias(fecha: hoy);
    final config = await _firestoreService.getConfig();
    final sessionConfig = _ref.read(sessionConfigProvider);

    final socioIdsConAsistencia = asistenciasHoy.map((a) => a.socioId).toSet();
    final sociosSinAsistencia = socios.where((s) => !socioIdsConAsistencia.contains(s.id)).toList();

    int count = 0;
    for (final socio in sociosSinAsistencia) {
      final montoFalta = sessionConfig?.multaFalta ?? config.multaFalta;
      final multa = MultaModel.create(
        socioId: socio.id ?? '',
        socioNombre: socio.nombreCompleto,
        tipo: TipoMulta.falta,
        monto: montoFalta,
        observaciones: 'Falta automática - ${hoy.day}/${hoy.month}/${hoy.year}',
      );
      await _firestoreService.createMulta(multa);
      count++;
    }

    _ref.invalidate(asistenciaHoyProvider);
    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(multasProvider);

    return count;
  }
}