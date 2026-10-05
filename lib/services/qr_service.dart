import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class QrService {
  static const String _secretKey = 'AAP_TOLATA_CHICO_SECRET_2026';

  /// Generates a unique encrypted string for a socio
  static String generateSocioQr(String socioId, String ci) {
    final uuid = const Uuid().v4();
    final rawData = '$socioId|$ci|$uuid';
    
    // Simple encoding (Base64) + HMAC for validation
    final bytes = utf8.encode(rawData);
    final base64Data = base64.encode(bytes);
    
    final hmac = Hmac(sha256, utf8.encode(_secretKey));
    final digest = hmac.convert(bytes);
    
    return '$base64Data.${digest.toString().substring(0, 8)}';
  }

  /// Validates and extracts data from a QR string
  static Map<String, String>? validateAndParseQr(String qrData) {
    try {
      final parts = qrData.split('.');
      if (parts.length != 2) return null;

      final base64Data = parts[0];
      final signature = parts[1];

      final bytes = base64.decode(base64Data);
      final rawData = utf8.decode(bytes);

      // Validate HMAC
      final hmac = Hmac(sha256, utf8.encode(_secretKey));
      final digest = hmac.convert(bytes);
      
      if (digest.toString().substring(0, 8) != signature) {
        return null; // Invalid signature
      }

      final dataParts = rawData.split('|');
      if (dataParts.length != 3) return null;

      return {
        'socioId': dataParts[0],
        'ci': dataParts[1],
        'uuid': dataParts[2],
      };
    } catch (e) {
      return null;
    }
  }
}
