import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/socio_model.dart';
import '../../providers/socios_provider.dart';
import '../../services/qr_service.dart';
import '../../core/theme/app_theme.dart';

class SocioFormScreen extends ConsumerStatefulWidget {
  final String? socioId;
  
  const SocioFormScreen({super.key, this.socioId});

  @override
  ConsumerState<SocioFormScreen> createState() => _SocioFormScreenState();
}

class _SocioFormScreenState extends ConsumerState<SocioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _ciController = TextEditingController();
  final _numeroSocioController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.socioId != null;
    if (_isEditing) {
      _loadSocio();
    }
  }

  Future<void> _loadSocio() async {
    final socios = ref.read(sociosProvider).value ?? [];
    final socio = socios.firstWhere(
      (s) => s.id == widget.socioId,
      orElse: () => SocioModel(
        id: '', nombreCompleto: '', fechaRegistro: DateTime.now(),
      ),
    );
    
    if (socio.id != null && socio.id!.isNotEmpty) {
      _nombreController.text = socio.nombreCompleto;
      _ciController.text = socio.ci;
      _numeroSocioController.text = socio.numeroSocio ?? '';
      _telefonoController.text = socio.telefono ?? '';
      _direccionController.text = socio.direccion ?? '';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ciController.dispose();
    _numeroSocioController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        final socios = ref.read(sociosProvider).value ?? [];
        final socio = socios.firstWhere((s) => s.id == widget.socioId);
        
        final ci = _ciController.text.trim();
        final updatedSocio = socio.copyWith(
          nombreCompleto: _nombreController.text.trim(),
          ci: ci,
          numeroSocio: _numeroSocioController.text.trim().isEmpty ? null : _numeroSocioController.text.trim(),
          telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
          direccion: _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
          qrCode: socio.qrCode ?? (ci.isNotEmpty ? QrService.generateSocioQr(socio.id!, ci) : null),
        );
        
        await ref.read(sociosProvider.notifier).updateSocio(updatedSocio);
      } else {
        final newSocio = SocioModel.create(
          nombreCompleto: _nombreController.text.trim(),
          ci: _ciController.text.trim(),
          numeroSocio: _numeroSocioController.text.trim().isEmpty ? null : _numeroSocioController.text.trim(),
          telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
          direccion: _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
        );
        
        await ref.read(sociosProvider.notifier).createSocio(newSocio);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Socio actualizado' : 'Socio registrado'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Socio' : 'Nuevo Socio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ciController,
                decoration: const InputDecoration(
                  labelText: 'Cédula de identidad (opcional)',
                  prefixIcon: Icon(Icons.badge),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numeroSocioController,
                decoration: const InputDecoration(
                  labelText: 'Número de socio (opcional)',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección (opcional)',
                  prefixIcon: Icon(Icons.location_on),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEditing ? 'Actualizar' : 'Registrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}