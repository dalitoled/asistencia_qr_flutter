import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/config_model.dart';
import '../../providers/asistencia_provider.dart';
import '../../widgets/loading_widget.dart';

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  final _horaLimiteController = TextEditingController();
  final _multaRetrasoController = TextEditingController();
  final _multaFaltaController = TextEditingController();
  final _nombreController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _horaLimiteController.dispose();
    _multaRetrasoController.dispose();
    _multaFaltaController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  void _loadConfig(ConfigModel config) {
    _horaLimiteController.text = config.horaLimite;
    _multaRetrasoController.text = config.multaRetraso.toStringAsFixed(2);
    _multaFaltaController.text = config.multaFalta.toStringAsFixed(2);
    _nombreController.text = config.nombreInstitucion;
  }

  Future<void> _save() async {
    final config = ref.read(configProvider).valueOrNull;
    if (config == null) return;

    setState(() => _isSaving = true);
    try {
      final updated = config.copyWith(
        horaLimite: _horaLimiteController.text.trim(),
        multaRetraso: double.tryParse(_multaRetrasoController.text.trim()) ?? config.multaRetraso,
        multaFalta: double.tryParse(_multaFaltaController.text.trim()) ?? config.multaFalta,
        nombreInstitucion: _nombreController.text.trim(),
      );
      await ref.read(configProvider.notifier).updateConfig(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(configProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: configAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (config) {
          if (_horaLimiteController.text.isEmpty) {
            _loadConfig(config);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Institución', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nombreController,
                          decoration: const InputDecoration(labelText: 'Nombre de la institución', prefixIcon: Icon(Icons.business)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Horario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _horaLimiteController,
                          decoration: const InputDecoration(labelText: 'Hora límite (HH:mm)', prefixIcon: Icon(Icons.access_time)),
                          keyboardType: TextInputType.datetime,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Multas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _multaRetrasoController,
                          decoration: const InputDecoration(labelText: 'Multa por retraso (Bs)', prefixIcon: Icon(Icons.attach_money)),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _multaFaltaController,
                          decoration: const InputDecoration(labelText: 'Multa por falta (Bs)', prefixIcon: Icon(Icons.money_off)),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}