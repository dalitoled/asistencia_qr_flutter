import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/socio_model.dart';
import '../services/firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final sociosProvider = StateNotifierProvider<SociosNotifier, AsyncValue<List<SocioModel>>>((ref) {
  return SociosNotifier(ref.watch(firestoreServiceProvider));
});

final socioSeleccionadoProvider = StateProvider<SocioModel?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredSociosProvider = Provider<AsyncValue<List<SocioModel>>>((ref) {
  final socios = ref.watch(sociosProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

    return socios.whenData((list) {
      if (query.isEmpty) return list;
      return list.where((s) => 
        s.nombreCompleto.toLowerCase().contains(query) ||
        s.ci.toLowerCase().contains(query) ||
        (s.numeroSocio?.toLowerCase().contains(query) ?? false) ||
        (s.telefono?.toLowerCase().contains(query) ?? false)
      ).toList();
    });
});

class SociosNotifier extends StateNotifier<AsyncValue<List<SocioModel>>> {
  final FirestoreService _firestoreService;

  SociosNotifier(this._firestoreService) : super(const AsyncValue.loading()) {
    loadSocios();
  }

  Future<void> loadSocios() async {
    state = const AsyncValue.loading();
    try {
      final socios = await _firestoreService.getSocios(activo: true);
      state = AsyncValue.data(socios);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createSocio(SocioModel socio) async {
    try {
      await _firestoreService.createSocio(socio);
      await loadSocios();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateSocio(SocioModel socio) async {
    try {
      await _firestoreService.updateSocio(socio);
      await loadSocios();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteSocio(String uid) async {
    try {
      await _firestoreService.deleteSocio(uid);
      await loadSocios();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<SocioModel?> searchByCi(String ci) async {
    return _firestoreService.getSocioByCi(ci);
  }
}