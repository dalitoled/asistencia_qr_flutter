import 'package:uuid/uuid.dart';
import '../services/qr_service.dart';

class SocioModel {
  final String? id;
  final String nombreCompleto;
  final String ci;
  final String? telefono;
  final String? direccion;
  final String? numeroSocio;
  final String estado;
  final DateTime fechaRegistro;
  final String? qrCode;
  final String? fotoUrl;

  SocioModel({
    this.id,
    required this.nombreCompleto,
    this.ci = '',
    this.telefono,
    this.direccion,
    this.numeroSocio,
    this.estado = 'Activo',
    required this.fechaRegistro,
    this.qrCode,
    this.fotoUrl,
  });

  factory SocioModel.create({
    String? id,
    required String nombreCompleto,
    String ci = '',
    String? telefono,
    String? direccion,
    String? numeroSocio,
    String? fotoUrl,
  }) {
    final now = DateTime.now();
    final newId = id ?? const Uuid().v4();
    return SocioModel(
      id: newId,
      nombreCompleto: nombreCompleto,
      ci: ci,
      telefono: telefono,
      direccion: direccion,
      numeroSocio: numeroSocio,
      fechaRegistro: now,
      qrCode: ci.isNotEmpty ? QrService.generateSocioQr(newId, ci) : null,
      fotoUrl: fotoUrl,
    );
  }

  factory SocioModel.fromMap(Map<String, dynamic> map, String id) {
    return SocioModel(
      id: id,
      nombreCompleto: map['nombreCompleto'] ?? '',
      ci: map['ci'] ?? '',
      telefono: map['telefono'],
      direccion: map['direccion'],
      numeroSocio: map['numeroSocio'],
      estado: map['estado'] ?? 'Activo',
      fechaRegistro: (map['fechaRegistro'] as dynamic)?.toDate() ?? DateTime.now(),
      qrCode: map['qrCode'],
      fotoUrl: map['fotoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombreCompleto': nombreCompleto,
      'ci': ci,
      'telefono': telefono,
      'direccion': direccion,
      'numeroSocio': numeroSocio,
      'estado': estado,
      'fechaRegistro': fechaRegistro,
      'qrCode': qrCode,
      'fotoUrl': fotoUrl,
    };
  }

  SocioModel copyWith({
    String? id,
    String? nombreCompleto,
    String? ci,
    String? telefono,
    String? direccion,
    String? numeroSocio,
    String? estado,
    DateTime? fechaRegistro,
    String? qrCode,
    String? fotoUrl,
  }) {
    return SocioModel(
      id: id ?? this.id,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      ci: ci ?? this.ci,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      numeroSocio: numeroSocio ?? this.numeroSocio,
      estado: estado ?? this.estado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      qrCode: qrCode ?? this.qrCode,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }
}