import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/socio_model.dart';
import '../models/asistencia_model.dart';
import '../models/multa_model.dart';
import '../models/pago_model.dart';
import '../models/config_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<T>> collectionStream<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentID) builder,
    Query Function(Query query)? queryBuilder,
    int Function(T lhs, T rhs)? sort,
  }) {
    Query query = _db.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => builder(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      if (sort != null) {
        list.sort(sort);
      }
      return list;
    });
  }

  Future<void> setData({required String path, required Map<String, dynamic> data, bool merge = true}) async {
    await _db.doc(path).set(data, SetOptions(merge: merge));
  }

  Future<String> addData({required String path, required Map<String, dynamic> data}) async {
    final ref = await _db.collection(path).add(data);
    return ref.id;
  }

  Future<void> deleteData({required String path}) async {
    await _db.doc(path).delete();
  }

  // Socio methods
  Future<List<SocioModel>> getSocios({bool? activo}) async {
    Query query = _db.collection('socios');
    if (activo == true) {
      query = query.where('estado', isEqualTo: 'Activo');
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => SocioModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> createSocio(SocioModel socio) async {
    if (socio.id != null) {
      await _db.collection('socios').doc(socio.id).set(socio.toMap());
    } else {
      await _db.collection('socios').add(socio.toMap());
    }
  }

  Future<void> updateSocio(SocioModel socio) async {
    if (socio.id != null) {
      await _db.collection('socios').doc(socio.id).update(socio.toMap());
    }
  }

  Future<void> deleteSocio(String id) async {
    await _db.collection('socios').doc(id).delete();
  }

  Future<SocioModel?> getSocioByCi(String ci) async {
    final snapshot = await _db.collection('socios').where('ci', isEqualTo: ci).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return SocioModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  // Asistencia methods
  Future<List<AsistenciaModel>> getAsistencias({DateTime? fecha}) async {
    Query query = _db.collection('asistencias');
    if (fecha != null) {
      final start = DateTime(fecha.year, fecha.month, fecha.day);
      final end = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
      query = query.where('fecha', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('fecha', isLessThanOrEqualTo: end.toIso8601String());
    }
    final snapshot = await query.orderBy('fecha', descending: true).get();
    return snapshot.docs.map((doc) => AsistenciaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<AsistenciaModel?> getAsistenciaToday(String socioId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final snapshot = await _db.collection('asistencias')
        .where('socioId', isEqualTo: socioId)
        .where('fecha', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('fecha', isLessThanOrEqualTo: end.toIso8601String())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return AsistenciaModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  }

  Future<List<AsistenciaModel>> getAsistenciasByRange(DateTime start, DateTime end) async {
    final snapshot = await _db.collection('asistencias')
        .where('fecha', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('fecha', isLessThanOrEqualTo: end.toIso8601String())
        .orderBy('fecha', descending: true)
        .get();
    return snapshot.docs.map((doc) => AsistenciaModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> createAsistencia(AsistenciaModel asistencia) async {
    await _db.collection('asistencias').add(asistencia.toMap());
  }

  // Multa methods
  Future<List<MultaModel>> getMultas({String? socioId, bool? pendientes}) async {
    Query query = _db.collection('multas');
    if (socioId != null) {
      query = query.where('socioId', isEqualTo: socioId);
    }
    if (pendientes == true) {
      query = query.where('estado', isEqualTo: 'pendiente');
    }
    final snapshot = await query.orderBy('fecha', descending: true).get();
    return snapshot.docs.map((doc) => MultaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<String> createMulta(MultaModel multa) async {
    final ref = await _db.collection('multas').add(multa.toMap());
    return ref.id;
  }

  Future<void> updateMulta(MultaModel multa) async {
    final docId = multa.docId ?? multa.uid;
    await _db.collection('multas').doc(docId).update(multa.toMap());
  }

  // Config methods
  Future<ConfigModel> getConfig() async {
    try {
      final doc = await _db.collection('config').doc('sistema').get();
      if (doc.exists) {
        return ConfigModel.fromMap(doc.data()!);
      }
    } catch (_) {}
    return ConfigModel.defaultConfig();
  }

  Future<void> updateConfig(ConfigModel config) async {
    await _db.collection('config').doc('sistema').set(config.toMap());
  }

  // Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    int socioCount = 0;
    int asistenciaHoy = 0;
    try {
      final sociosSnap = await _db.collection('socios').count().get();
      socioCount = sociosSnap.count ?? 0;
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final asistenciasSnap = await _db.collection('asistencias')
          .where('fecha', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('fecha', isLessThanOrEqualTo: end.toIso8601String())
          .count()
          .get();
      asistenciaHoy = asistenciasSnap.count ?? 0;
    } catch (_) {}
    return {'socios': socioCount, 'asistenciaHoy': asistenciaHoy};
  }

  // Pagos
  Future<List<PaymentModel>> getPagos({String? socioId}) async {
    Query query = _db.collection('pagos');
    if (socioId != null) {
      query = query.where('socioId', isEqualTo: socioId);
    }
    final snapshot = await query.orderBy('fecha', descending: true).get();
    return snapshot.docs.map((doc) => PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<List<MultaModel>> getMultasByRange(DateTime start, DateTime end) async {
    final snapshot = await _db.collection('multas')
        .where('fecha', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('fecha', isLessThanOrEqualTo: end.toIso8601String())
        .orderBy('fecha', descending: true)
        .get();
    return snapshot.docs.map((doc) => MultaModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<String> createPago(PaymentModel pago) async {
    final ref = await _db.collection('pagos').add(pago.toMap());
    return ref.id;
  }
}