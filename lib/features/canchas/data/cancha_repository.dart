import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/cancha.dart';

class CanchaRepository {
  final Dio _dio = ApiClient.create();

  // ── Admin: lista + cambiar estado ─────────────────────────────────────────

  Future<({List<CanchaDto> canchas, int limite})> listar() async {
    try {
      final res = await _dio.get('/api/canchas');
      final data = res.data as Map<String, dynamic>;
      return (
        canchas: (data['canchas'] as List)
            .map((e) => CanchaDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        limite: data['limite'] as int? ?? 0,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> cambiarEstado(String canchaId, String estado) async {
    try {
      await _dio.patch('/api/canchas/$canchaId/estado',
          data: {'estado': estado});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Staff + Admin: estado en tiempo real ──────────────────────────────────

  Future<List<EstadoCanchaStaffDto>> obtenerEstado() async {
    try {
      final res = await _dio.get('/api/canchas/estado');
      return (res.data as List)
          .map((e) => EstadoCanchaStaffDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ── Staff + Admin: mantenimiento ──────────────────────────────────────────

  Future<RegistroMantenimientoDto> iniciarMantenimiento(
      String canchaId, {
      required int categoria,
      required String descripcion,
      double? costoEstimado,
      String? proveedor,
    }) async {
    try {
      final res = await _dio.post('/api/canchas/$canchaId/mantenimiento', data: {
        'categoria':     categoria,
        'descripcion':   descripcion,
        if (costoEstimado != null) 'costoEstimado': costoEstimado,
        if (proveedor     != null) 'proveedor':     proveedor,
      });
      return RegistroMantenimientoDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> resolverMantenimiento(
      String registroId, {
      double? costoReal,
      String? observacion,
    }) async {
    try {
      await _dio.patch('/api/canchas/mantenimiento/$registroId/resolver', data: {
        if (costoReal   != null) 'costoReal':          costoReal,
        if (observacion != null) 'observacionCierre':  observacion,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<RegistroMantenimientoDto>> historial(String canchaId) async {
    try {
      final res = await _dio.get('/api/canchas/$canchaId/mantenimiento/historial');
      return (res.data as List)
          .map((e) => RegistroMantenimientoDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
