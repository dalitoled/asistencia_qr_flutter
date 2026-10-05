import '../models/socio_model.dart';

abstract class SocioRepository {
  Future<List<SocioModel>> getSocios();
  Future<SocioModel?> getSocioById(String id);
  Future<void> createSocio(SocioModel socio);
  Future<void> updateSocio(SocioModel socio);
  Future<void> deleteSocio(String id);
  Stream<List<SocioModel>> watchSocios();
}


