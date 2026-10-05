import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../models/config_model.dart';
import '../../services/qr_service.dart';
import '../../providers/asistencia_provider.dart';
import '../../providers/auth_provider.dart';
import 'session_config_dialog.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSessionConfig());
  }

  Future<void> _checkSessionConfig() async {
    if (!mounted) return;

    final sessionConfig = ref.read(sessionConfigProvider);
    if (sessionConfig != null) return;

    final config = ref.read(configProvider).valueOrNull;
    if (!mounted || config == null) return;

    final result = await showDialog<SessionConfig>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SessionConfigDialog(config: config),
    );

    if (result != null && mounted) {
      ref.read(sessionConfigProvider.notifier).setConfig(result);
    } else if (mounted) {
      context.pop();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    final data = QrService.validateAndParseQr(code);

    if (data != null) {
      await _registerAsistencia(data['socioId']!, data['ci']!);
    } else {
      _showError('Código QR no válido o expirado');
    }
  }

  Future<void> _registerAsistencia(String socioId, String socioCi) async {
    try {
      final asistenciaService = ref.read(asistenciaServiceProvider);
      final user = ref.read(authServiceProvider).currentUser;

      await asistenciaService.registrarAsistencia(
        socioId: socioId,
        socioNombre: 'Socio',
        socioCi: socioCi,
        operadorId: user?.uid ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asistencia registrada correctamente'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Socio')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Encuadre el código QR del socio',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
