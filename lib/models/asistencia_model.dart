enum TipoAsistencia { asistencia, retraso, falta }

enum TipoSesion { ordinaria, extraordinaria, desfile, otro }

class AsistenciaModel {
  final String? id;
  final String socioId;
  final String socioNombre;
  final String? socioCi;
  final String? operadorId;
  final DateTime fecha;
  final TipoAsistencia tipo;
  final String? observaciones;
  final double? multaMonto;
  final String? tipoSesion;

  AsistenciaModel({
    this.id,
    required this.socioId,
    required this.socioNombre,
    this.socioCi,
    this.operadorId,
    required this.fecha,
    required this.tipo,
    this.observaciones,
    this.multaMonto,
    this.tipoSesion,
  });

  factory AsistenciaModel.fromMap(Map<String, dynamic> map, String id) {
    return AsistenciaModel(
      id: id,
      socioId: map['socioId'] ?? '',
      socioNombre: map['socioNombre'] ?? '',
      socioCi: map['socioCi'],
      operadorId: map['operadorId'],
      fecha: map['fecha'] != null ? (map['fecha'] is DateTime ? map['fecha'] : DateTime.tryParse(map['fecha'].toString()) ?? DateTime.now()) : DateTime.now(),
      tipo: TipoAsistencia.values.firstWhere(
        (e) => e.name == (map['tipo'] ?? ''),
        orElse: () => TipoAsistencia.asistencia,
      ),
      observaciones: map['observaciones'],
      multaMonto: (map['multaMonto'] as num?)?.toDouble(),
      tipoSesion: map['tipoSesion'],
    );
  }

  factory AsistenciaModel.create({
    required String socioId,
    required String socioNombre,
    String? socioCi,
    required TipoAsistencia tipo,
    required String operadorId,
    String? observaciones,
    double? multaMonto,
    String? tipoSesion,
  }) {
    return AsistenciaModel(
      socioId: socioId,
      socioNombre: socioNombre,
      socioCi: socioCi,
      operadorId: operadorId,
      fecha: DateTime.now(),
      tipo: tipo,
      observaciones: observaciones,
      multaMonto: multaMonto,
      tipoSesion: tipoSesion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'socioId': socioId,
      'socioNombre': socioNombre,
      'socioCi': socioCi,
      'operadorId': operadorId,
      'fecha': fecha.toIso8601String(),
      'tipo': tipo.name,
      'observaciones': observaciones,
      'multaMonto': multaMonto,
      'tipoSesion': tipoSesion,
    };
  }
}
