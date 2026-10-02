import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/notificacion_dto.dart';

class NotificacionesBandejaRepository {
  final Dio _dio = ApiClient.create();

  Future<List<NotificacionDto>> listar() async {
    try {
      final response = await _dio.get('/api/notificaciones');
      return (response.data as List)
          .map((e) => NotificacionDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<int> contarNoLeidas() async {
    try {
      final response = await _dio.get('/api/notificaciones/no-leidas/conteo');
      return response.data['conteo'] as int;
    } on DioException {
      return 0;
    }
  }

  Future<void> marcarLeida(String id) async {
    try {
      await _dio.post('/api/notificaciones/$id/leer');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
