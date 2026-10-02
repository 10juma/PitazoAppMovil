import 'package:dio/dio.dart';
import '../network/api_client.dart';

/// Registro del token de push del dispositivo — el backend resuelve el
/// usuario dueño del token a partir del JWT (Authorization header), por eso
/// aquí solo se manda el token y la plataforma.
class NotificacionesRepository {
  final Dio _dio = ApiClient.create();

  Future<void> registrarDispositivo({required String fcmToken, required String plataforma}) async {
    try {
      await _dio.post('/api/notificaciones/dispositivo', data: {
        'fcmToken':   fcmToken,
        'plataforma': plataforma,
      });
    } on DioException {
      // Fire-and-forget — si falla el registro del token, no debe bloquear el login.
    }
  }
}
