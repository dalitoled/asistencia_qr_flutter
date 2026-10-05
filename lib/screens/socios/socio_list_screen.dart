import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/socios_provider.dart';
import '../../widgets/socio_card.dart';
import '../../widgets/loading_widget.dart';

class SocioListScreen extends ConsumerStatefulWidget {
  const SocioListScreen({super.key});

  @override
  ConsumerState<SocioListScreen> createState() => _SocioListScreenState();
}

class _SocioListScreenState extends ConsumerState<SocioListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sociosAsync = ref.watch(filteredSociosProvider);

    ref.listen(searchQueryProvider, (prev, next) {
      if (next.isEmpty && _searchController.text.isNotEmpty) {
        _searchController.clear();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Socios'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingS),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, CI o N° socio...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
            ),
          ),
        ),
      ),
      body: sociosAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, st) => ErrorStateWidget(
          message: 'Error al cargar socios: $e',
          onRetry: () => ref.read(sociosProvider.notifier).loadSocios(),
        ),
        data: (socios) {
          if (socios.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.people_outline,
              title: 'No hay socios registrados',
              subtitle: 'Agrega el primer socio usando el botón +',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(sociosProvider.notifier).loadSocios(),
            child: ListView.builder(
              itemCount: socios.length,
              padding: const EdgeInsets.all(AppConstants.paddingM),
              itemBuilder: (context, index) {
                final socio = socios[index];
                return SocioCard(
                  socio: socio,
                  onTap: () => context.push('/socios/${socio.id}'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/socios/nuevo'),
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
