import 'package:flutter/material.dart';
import '../../models/config_model.dart';
import '../../providers/asistencia_provider.dart';

class SessionConfigDialog extends StatefulWidget {
  final ConfigModel config;
  final SessionConfig? currentConfig;
  const SessionConfigDialog({required this.config, this.currentConfig, super.key});

  @override
  State<SessionConfigDialog> createState() => _SessionConfigDialogState();
}

class _SessionConfigDialogState extends State<SessionConfigDialog> {
  late String _tipoSesion;
  late TextEditingController _retrasoCtrl;
  late TextEditingController _faltaCtrl;

  @override
  void initState() {
    super.initState();
    _tipoSesion = widget.currentConfig?.tipoSesion ?? 'ordinaria';
    _retrasoCtrl = TextEditingController(
      text: (widget.currentConfig?.multaRetraso ?? widget.config.multaRetraso).toStringAsFixed(2),
    );
    _faltaCtrl = TextEditingController(
      text: (widget.currentConfig?.multaFalta ?? widget.config.multaFalta).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _retrasoCtrl.dispose();
    _faltaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.currentConfig == null ? 'Configurar Jornada' : 'Modificar Jornada'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tipo de sesión', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _tipoSesion,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ordinaria', child: Text('Reunión Ordinaria')),
                DropdownMenuItem(value: 'extraordinaria', child: Text('Reunión Extraordinaria')),
                DropdownMenuItem(value: 'desfile', child: Text('Desfile')),
                DropdownMenuItem(value: 'otro', child: Text('Otro')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _tipoSesion = v);
              },
            ),
            const SizedBox(height: 16),
            const Text('Montos de multas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _retrasoCtrl,
              decoration: const InputDecoration(
                labelText: 'Multa por retraso (Bs)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _faltaCtrl,
              decoration: const InputDecoration(
                labelText: 'Multa por falta (Bs)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final retraso = double.tryParse(_retrasoCtrl.text.trim());
            final falta = double.tryParse(_faltaCtrl.text.trim());
            if (retraso == null || falta == null || retraso <= 0 || falta <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ingrese montos válidos')),
              );
              return;
            }
            Navigator.pop(context, SessionConfig(
              tipoSesion: _tipoSesion,
              multaRetraso: retraso,
              multaFalta: falta,
            ));
          },
          child: Text(widget.currentConfig == null ? 'INICIAR JORNADA' : 'GUARDAR CAMBIOS'),
        ),
      ],
    );
  }
}
