import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException({this.statusCode, required this.message});

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    final msg = (data is Map && data['mensaje'] != null)
        ? data['mensaje'] as String
        : _defaultMessage(e.response?.statusCode);
    return ApiException(statusCode: e.response?.statusCode, message: msg);
  }

  static String _defaultMessage(int? code) => switch (code) {
        400 => 'Solicitud inválida.',
        401 => 'Credenciales incorrectas.',
        403 => 'No tienes permiso para esta acción.',
        404 => 'Recurso no encontrado.',
        500 => 'Error en el servidor. Intenta más tarde.',
        null => 'Sin conexión. Verifica tu internet.',
        _ => 'Error inesperado.',
      };

  @override
  String toString() => message;
}
