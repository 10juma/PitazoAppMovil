import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/patrocinador_dto.dart';

class PatrocinadorRepository {
  final Dio _dio = ApiClient.create();

  Future<PatrocinadorPortalDto?> obtenerPerfil() async {
    try {
      final response = await _dio.get('/api/patrocinador/perfil');
      return PatrocinadorPortalDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDio(e);
    }
  }

  Future<void> actualizarPerfil({
    String? logoUrl,
    String? sitioWeb,
    String? contactoNombre,
    String? contactoTelefono,
    String? contactoEmail,
  }) async {
    try {
      await _dio.put('/api/patrocinador/perfil', data: {
        'logoUrl':          logoUrl,
        'sitioWeb':         sitioWeb,
        'contactoNombre':   contactoNombre,
        'contactoTelefono': contactoTelefono,
        'contactoEmail':    contactoEmail,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<MetricasPatrocinadorDto> obtenerMetricas() async {
    try {
      final response = await _dio.get('/api/patrocinador/metricas');
      return MetricasPatrocinadorDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<FacturaPatrocinadorDto>> listarFacturas() async {
    try {
      final response = await _dio.get('/api/patrocinador/facturas');
      return (response.data as List)
          .map((e) => FacturaPatrocinadorDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
