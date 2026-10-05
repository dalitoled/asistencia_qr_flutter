import '../models/socio_model.dart';
import '../services/firestore_service.dart';
import 'socio_repository.dart';

class SocioRepositoryImpl implements SocioRepository {
  final FirestoreService _service = FirestoreService();
  static const String _collection = 'socios';

  @override
  Future<void> createSocio(SocioModel socio) async {
    await _service.addData(
      path: _collection,
      data: socio.toMap(),
    );
  }

  @override
  Future<void> deleteSocio(String id) async {
    await _service.deleteData(path: '$_collection/$id');
  }

  @override
  Future<SocioModel?> getSocioById(String id) async {
    // Single document fetch logic
    // Implementation via stream as we have a collection stream method
    final list = await _service.collectionStream<SocioModel>(
      path: _collection,
      builder: (data, id) => SocioModel.fromMap(data, id),
    ).first;
    
    try {
      return list.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<SocioModel>> getSocios() async {
    return _service.collectionStream<SocioModel>(
      path: _collection,
      builder: (data, id) => SocioModel.fromMap(data, id),
    ).first;
  }

  @override
  Future<void> updateSocio(SocioModel socio) async {
    if (socio.id == null) return;
    await _service.setData(
      path: '$_collection/${socio.id}',
      data: socio.toMap(),
    );
  }

  @override
  Stream<List<SocioModel>> watchSocios() {
    return _service.collectionStream<SocioModel>(
      path: _collection,
      builder: (data, id) => SocioModel.fromMap(data, id),
      sort: (a, b) => a.nombreCompleto.compareTo(b.nombreCompleto),
    );
  }
}
