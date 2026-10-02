import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'notificaciones_repository.dart';

/// Notificaciones push (Firebase Cloud Messaging) — pide permiso, registra el
/// token del dispositivo en el backend, y maneja los 3 estados en que puede
/// llegar un push: app abierta (foreground), en segundo plano, o cerrada.
///
/// v1: tocar la notificación simplemente abre el dashboard del rol actual
/// (no hay deep-link a una pantalla específica todavía).
class PushNotificationService {
  /// Para mostrar un banner in-app cuando llega un push con la app abierta.
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Asignados una vez desde app.dart, donde ya existen el router y la sesión.
  static GoRouter?     router;
  static AuthProvider? authProvider;

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificacionesRepository _repo = NotificacionesRepository();
  bool _tokenRegistradoEsteRun = false;

  Future<void> init() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('[Push] No se pudo pedir permiso de notificaciones: $e');
    }

    FirebaseMessaging.onMessage.listen(_mostrarBannerForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _irAlDashboard());

    final inicial = await _messaging.getInitialMessage();
    if (inicial != null) _irAlDashboard();

    _messaging.onTokenRefresh.listen(_registrarToken);
  }

  /// Llamar tras login exitoso o tras restaurar una sesión guardada — solo
  /// registra una vez por ejecución de la app (no en cada rebuild).
  Future<void> registrarTokenActual() async {
    if (_tokenRegistradoEsteRun) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _registrarToken(token);
      _tokenRegistradoEsteRun = true;
    } catch (e) {
      debugPrint('[Push] No se pudo obtener/registrar el token FCM: $e');
    }
  }

  Future<void> _registrarToken(String token) async {
    final plataforma = Platform.isIOS ? 'iOS' : 'Android';
    await _repo.registrarDispositivo(fcmToken: token, plataforma: plataforma);
  }

  void _mostrarBannerForeground(RemoteMessage message) {
    final titulo = message.notification?.title;
    final cuerpo = message.notification?.body;
    if (titulo == null && cuerpo == null) return;

    messengerKey.currentState?.showSnackBar(SnackBar(
      content: Text([titulo, cuerpo].where((s) => s != null && s.isNotEmpty).join(' — ')),
      duration: const Duration(seconds: 4),
    ));
  }

  void _irAlDashboard() {
    final home = authProvider?.homePath;
    if (home != null && home != '/login') router?.go(home);
  }
}

/// Handler de background/terminada — requisito de Firebase: debe ser una
/// función TOP-LEVEL (no un método de clase), marcada como entry-point.
/// Corre en un isolate aparte sin el resto del estado de la app, por eso no
/// hace nada más que dejar que el sistema operativo muestre la notificación
/// (el payload ya trae title/body, el SO la pinta solo).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
