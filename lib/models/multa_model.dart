import 'package:uuid/uuid.dart';

enum TipoMulta { retraso, falta }
enum EstadoMulta { pendiente, pagado }

class MultaModel {
  final String? docId;
  final String uid;
  final String socioId;
  final String socioNombre;
  final TipoMulta tipo;
  final double monto;
  final EstadoMulta estado;
  final DateTime fecha;
  final String? observaciones;
  final String? idPago;

  MultaModel({
    this.docId,
    required this.uid,
    required this.socioId,
    required this.socioNombre,
    required this.tipo,
    required this.monto,
    required this.estado,
    required this.fecha,
    this.observaciones,
    this.idPago,
  });

  String get tipoString => tipo == TipoMulta.retraso ? 'Retraso' : 'Falta';
  String get estadoString => estado == EstadoMulta.pendiente ? 'Pendiente' : 'Pagado';
  bool get isPendiente => estado == EstadoMulta.pendiente;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'socioId': socioId,
      'socioNombre': socioNombre,
      'tipo': tipo.name,
      'monto': monto,
      'estado': estado.name,
      'fecha': fecha.toIso8601String(),
      'observaciones': observaciones,
      'idPago': idPago,
    };
  }

  factory MultaModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return MultaModel(
      docId: docId,
      uid: map['uid'] ?? '',
      socioId: map['socioId'] ?? '',
      socioNombre: map['socioNombre'] ?? '',
      tipo: TipoMulta.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoMulta.retraso,
      ),
      monto: (map['monto'] ?? 0).toDouble(),
      estado: EstadoMulta.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoMulta.pendiente,
      ),
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha']) : DateTime.now(),
      observaciones: map['observaciones'],
      idPago: map['idPago'],
    );
  }

  factory MultaModel.create({
    required String socioId,
    required String socioNombre,
    required TipoMulta tipo,
    required double monto,
    String? observaciones,
  }) {
    return MultaModel(
      uid: const Uuid().v4(),
      socioId: socioId,
      socioNombre: socioNombre,
      tipo: tipo,
      monto: monto,
      estado: EstadoMulta.pendiente,
      fecha: DateTime.now(),
      observaciones: observaciones,
    );
  }

  MultaModel copyWith({
    String? docId,
    String? uid,
    String? socioId,
    String? socioNombre,
    TipoMulta? tipo,
    double? monto,
    EstadoMulta? estado,
    DateTime? fecha,
    String? observaciones,
    String? idPago,
  }) {
    return MultaModel(
      docId: docId ?? this.docId,
      uid: uid ?? this.uid,
      socioId: socioId ?? this.socioId,
      socioNombre: socioNombre ?? this.socioNombre,
      tipo: tipo ?? this.tipo,
      monto: monto ?? this.monto,
      estado: estado ?? this.estado,
      fecha: fecha ?? this.fecha,
      observaciones: observaciones ?? this.observaciones,
      idPago: idPago ?? this.idPago,
    );
  }
}