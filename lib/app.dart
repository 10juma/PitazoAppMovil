import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/data/admin_partidos_repository.dart';
import 'features/admin/providers/admin_partidos_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/arbitro/providers/arbitro_provider.dart';
import 'features/manager/providers/manager_provider.dart';
import 'features/jugador/providers/jugador_provider.dart';
import 'features/notificaciones/data/notificaciones_repository.dart';
import 'features/notificaciones/providers/notificaciones_provider.dart';
import 'features/patrocinador/data/patrocinador_repository.dart';
import 'features/patrocinador/providers/patrocinador_provider.dart';
import 'features/staff/data/staff_equipos_repository.dart';
import 'features/staff/data/staff_partidos_repository.dart';
import 'features/staff/data/staff_comunicados_repository.dart';
import 'features/staff/data/staff_reservas_repository.dart';
import 'features/staff/providers/staff_comunicados_provider.dart';
import 'features/staff/providers/staff_dashboard_provider.dart';
import 'features/staff/providers/staff_equipos_provider.dart';
import 'features/staff/providers/staff_partidos_provider.dart';
import 'features/staff/providers/staff_reservas_provider.dart';

class PitazoApp extends StatefulWidget {
  const PitazoApp({super.key});

  @override
  State<PitazoApp> createState() => _PitazoAppState();
}

class _PitazoAppState extends State<PitazoApp> {
  late final AuthProvider _auth;
  late final GoRouter     _router;
  final _push = PushNotificationService();
  final _notificaciones = NotificacionesProvider(NotificacionesBandejaRepository());

  @override
  void initState() {
    super.initState();
    _auth   = AuthProvider();
    _router = AppRouter.create(_auth);

    PushNotificationService.router       = _router;
    PushNotificationService.authProvider = _auth;
    _push.init();

    // Cada vez que hay sesión activa (login nuevo o restaurada), registra el
    // token del dispositivo — la propia función no repite si ya lo hizo.
    _auth.addListener(_registrarPushSiHaySesion);
    _auth.addListener(_actualizarConteoNotificacionesSiHaySesion);
    _auth.init();
  }

  void _registrarPushSiHaySesion() {
    if (_auth.isLoggedIn) _push.registrarTokenActual();
  }

  void _actualizarConteoNotificacionesSiHaySesion() {
    if (_auth.isLoggedIn) _notificaciones.actualizarConteo();
  }

  @override
  void dispose() {
    _auth.removeListener(_registrarPushSiHaySesion);
    _auth.removeListener(_actualizarConteoNotificacionesSiHaySesion);
    _auth.dispose();
    _notificaciones.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _notificaciones),
        ChangeNotifierProvider(create: (_) => ArbitroProvider()),
        ChangeNotifierProvider(create: (_) => ManagerProvider()),
        ChangeNotifierProvider(create: (_) => JugadorProvider()),
        ChangeNotifierProvider(create: (_) => PatrocinadorProvider(PatrocinadorRepository())),
        ChangeNotifierProvider(create: (_) => StaffDashboardProvider()),
        ChangeNotifierProvider(create: (_) => StaffPartidosProvider(StaffPartidosRepository())),
        ChangeNotifierProvider(create: (_) => AdminPartidosProvider(AdminPartidosRepository())),
        ChangeNotifierProvider(create: (_) => StaffEquiposProvider(StaffEquiposRepository())),
        Provider(create: (_) => StaffReservasRepository()),
        ChangeNotifierProxyProvider<StaffReservasRepository, StaffReservasProvider>(
          create: (ctx) => StaffReservasProvider(ctx.read<StaffReservasRepository>()),
          update: (_, repo, prev) => prev ?? StaffReservasProvider(repo),
        ),
        Provider(create: (_) => StaffComunicadosRepository()),
        ChangeNotifierProxyProvider<StaffComunicadosRepository, StaffComunicadosProvider>(
          create: (ctx) => StaffComunicadosProvider(ctx.read<StaffComunicadosRepository>()),
          update: (_, repo, prev) => prev ?? StaffComunicadosProvider(repo),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) => MaterialApp.router(
          title: 'Pitazo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.forRol(auth.token?.rol),
          scaffoldMessengerKey: PushNotificationService.messengerKey,
          routerConfig: _router,
        ),
      ),
    );
  }
}
