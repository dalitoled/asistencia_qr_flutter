enum PaymentStatus { pendiente, pagado }

class PaymentModel {
  final String? id;
  final String socioId;
  final String socioNombre;
  final String tipo; // Multa Retraso, Multa Falta, mensualidad, etc.
  final double monto;
  final PaymentStatus estado;
  final DateTime fecha;
  final String? observaciones;

  PaymentModel({
    this.id,
    required this.socioId,
    required this.socioNombre,
    required this.tipo,
    required this.monto,
    this.estado = PaymentStatus.pendiente,
    required this.fecha,
    this.observaciones,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      socioId: map['socioId'] ?? '',
      socioNombre: map['socioNombre'] ?? '',
      tipo: map['tipo'] ?? '',
      monto: (map['monto'] as num?)?.toDouble() ?? 0.0,
      estado: map['estado'] == 'pagado' ? PaymentStatus.pagado : PaymentStatus.pendiente,
      fecha: (map['fecha'] as dynamic)?.toDate() ?? DateTime.now(),
      observaciones: map['observaciones'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'socioId': socioId,
      'socioNombre': socioNombre,
      'tipo': tipo,
      'monto': monto,
      'estado': estado == PaymentStatus.pagado ? 'pagado' : 'pendiente',
      'fecha': fecha,
      'observaciones': observaciones,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? socioId,
    String? socioNombre,
    String? tipo,
    double? monto,
    PaymentStatus? estado,
    DateTime? fecha,
    String? observaciones,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      socioId: socioId ?? this.socioId,
      socioNombre: socioNombre ?? this.socioNombre,
      tipo: tipo ?? this.tipo,
      monto: monto ?? this.monto,
      estado: estado ?? this.estado,
      fecha: fecha ?? this.fecha,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}