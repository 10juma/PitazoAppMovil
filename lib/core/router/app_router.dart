import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/select_tenant_screen.dart';
import '../../features/staff/screens/dashboard_screen.dart';
import '../../features/arbitro/screens/dashboard_screen.dart';
import '../../features/manager/screens/dashboard_screen.dart';
import '../../features/jugador/screens/dashboard_screen.dart';
import '../../features/patrocinador/screens/dashboard_screen.dart';
import '../../features/notificaciones/screens/bandeja_screen.dart';
import '../../features/en_vivo/screens/partido_en_vivo_screen.dart';
import '../../features/admin/screens/admin_perfil_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/arbitro/screens/arbitro_perfil_screen.dart';
import '../../features/staff/screens/staff_perfil_screen.dart';
import '../../features/manager/screens/manager_perfil_screen.dart';
import '../../features/manager/screens/manager_confirmaciones_screen.dart';
import '../../features/manager/screens/manager_partido_detalle_screen.dart';
import '../../features/manager/screens/manager_alineacion_screen.dart';
import '../../features/jugador/screens/jugador_perfil_screen.dart';
import '../../features/jugador/screens/jugador_partido_detalle_screen.dart';
import '../../features/patrocinador/screens/patrocinador_perfil_screen.dart';

class AppRouter {
  static GoRouter create(AuthProvider auth) => GoRouter(
        initialLocation: '/login',
        refreshListenable: auth,
        redirect: (context, state) {
          final loggedIn = auth.isLoggedIn;
          final onLogin  = state.matchedLocation == '/login'           ||
                           state.matchedLocation == '/forgot-password' ||
                           state.matchedLocation == '/select-tenant';
          if (!loggedIn && !onLogin) return '/login';
          if (loggedIn  &&  onLogin) return auth.homePath;
          return null;
        },
        routes: [
          GoRoute(path: '/login',           builder: (_, __) => const LoginScreen()),
          GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
          GoRoute(path: '/select-tenant',   builder: (_, __) => const SelectTenantScreen()),
          GoRoute(path: '/admin',           builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(path: '/staff',           builder: (_, __) => const StaffDashboardScreen()),
          GoRoute(path: '/staff/envivo/:id',
              builder: (_, state) => PartidoEnVivoScreen(
                  partidoId: state.pathParameters['id']!)),
          GoRoute(path: '/arbitro',         builder: (_, __) => const ArbitroDashboardScreen()),
          GoRoute(path: '/manager',         builder: (_, __) => const ManagerDashboardScreen()),
          GoRoute(path: '/jugador',         builder: (_, __) => const JugadorDashboardScreen()),
          GoRoute(path: '/patrocinador',    builder: (_, __) => const PatrocinadorDashboardScreen()),
          GoRoute(path: '/notificaciones',  builder: (_, __) => const BandejaScreen()),
          GoRoute(path: '/admin/perfil',    builder: (_, __) => const AdminPerfilScreen()),
          GoRoute(path: '/staff/perfil',    builder: (_, __) => const StaffPerfilScreen()),
          GoRoute(path: '/arbitro/perfil',  builder: (_, __) => const ArbitroPerfilScreen()),
          GoRoute(path: '/manager/perfil',  builder: (_, __) => const ManagerPerfilScreen()),
          GoRoute(path: '/jugador/perfil',  builder: (_, __) => const JugadorPerfilScreen()),
          GoRoute(path: '/patrocinador/perfil', builder: (_, __) => const PatrocinadorPerfilScreen()),
          GoRoute(
            path: '/manager/confirmaciones/:equipoId/:partidoId',
            builder: (_, state) => ManagerConfirmacionesScreen(
              equipoId:  state.pathParameters['equipoId']!,
              partidoId: state.pathParameters['partidoId']!,
            ),
          ),
          GoRoute(
            path: '/manager/partidos/:id',
            builder: (_, state) => ManagerPartidoDetalleScreen(
              partidoId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/manager/alineacion/:equipoId/:partidoId',
            builder: (_, state) => ManagerAlineacionScreen(
              equipoId:  state.pathParameters['equipoId']!,
              partidoId: state.pathParameters['partidoId']!,
            ),
          ),
          GoRoute(
            path: '/jugador/partidos/:id',
            builder: (_, state) => JugadorPartidoDetalleScreen(
              partidoId: state.pathParameters['id']!,
            ),
          ),
        ],
      );
}
