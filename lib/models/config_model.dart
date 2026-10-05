import '../core/constants/app_constants.dart';

class ConfigModel {
  final String uid;
  final String horaLimite;
  final double multaRetraso;
  final double multaFalta;
  final String nombreInstitucion;
  final String? logoUrl;

  ConfigModel({
    required this.uid,
    required this.horaLimite,
    required this.multaRetraso,
    required this.multaFalta,
    required this.nombreInstitucion,
    this.logoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'horaLimite': horaLimite,
      'multaRetraso': multaRetraso,
      'multaFalta': multaFalta,
      'nombreInstitucion': nombreInstitucion,
      'logoUrl': logoUrl,
    };
  }

  factory ConfigModel.fromMap(Map<String, dynamic> map) {
    return ConfigModel(
      uid: map['uid'] ?? 'default',
      horaLimite: map['horaLimite'] ?? AppConstants.defaultHourLimit,
      multaRetraso: (map['multaRetraso'] ?? AppConstants.defaultFineDelay).toDouble(),
      multaFalta: (map['multaFalta'] ?? AppConstants.defaultFineAbsence).toDouble(),
      nombreInstitucion: map['nombreInstitucion'] ?? AppConstants.institutionName,
      logoUrl: map['logoUrl'],
    );
  }

  factory ConfigModel.defaultConfig() {
    return ConfigModel(
      uid: 'default',
      horaLimite: AppConstants.defaultHourLimit,
      multaRetraso: AppConstants.defaultFineDelay,
      multaFalta: AppConstants.defaultFineAbsence,
      nombreInstitucion: AppConstants.institutionName,
    );
  }

  ConfigModel copyWith({
    String? uid,
    String? horaLimite,
    double? multaRetraso,
    double? multaFalta,
    String? nombreInstitucion,
    String? logoUrl,
  }) {
    return ConfigModel(
      uid: uid ?? this.uid,
      horaLimite: horaLimite ?? this.horaLimite,
      multaRetraso: multaRetraso ?? this.multaRetraso,
      multaFalta: multaFalta ?? this.multaFalta,
      nombreInstitucion: nombreInstitucion ?? this.nombreInstitucion,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}