import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/socios/socio_list_screen.dart';
import '../screens/socios/socio_detail_screen.dart';
import '../screens/socios/socio_form_screen.dart';
import '../screens/asistencia/qr_scanner_screen.dart';
import '../screens/pagos/pagos_screen.dart';
import '../screens/pagos/multas_screen.dart';
import '../screens/pagos/pago_form_screen.dart';
import '../screens/reportes/reportes_screen.dart';
import '../screens/reportes/reporte_socio_screen.dart';
import '../screens/config/config_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/socios',
        name: 'socios',
        builder: (context, state) => const SocioListScreen(),
        routes: [
          GoRoute(
            path: 'nuevo',
            name: 'socio-nuevo',
            builder: (context, state) => const SocioFormScreen(),
          ),
          GoRoute(
            path: ':id',
            name: 'socio-detalle',
            builder: (context, state) => SocioDetailScreen(socioId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'editar',
                name: 'socio-editar',
                builder: (context, state) => SocioFormScreen(socioId: state.pathParameters['id']),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/qr-scanner',
        name: 'qr-scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/pagos',
        name: 'pagos',
        builder: (context, state) => const PagosScreen(),
        routes: [
          GoRoute(
            path: 'multas',
            name: 'multas',
            builder: (context, state) => const MultasScreen(),
          ),
          GoRoute(
            path: 'pagar',
            name: 'pago-pagar',
            builder: (context, state) {
              final multa = state.extra as dynamic;
              return PagoFormScreen(multa: multa);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/reportes',
        name: 'reportes',
        builder: (context, state) => const ReportesScreen(),
        routes: [
          GoRoute(
            path: 'socio',
            name: 'reporte-socio',
            builder: (context, state) => const ReporteSocioScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const ConfigScreen(),
      ),
    ],
  );
}