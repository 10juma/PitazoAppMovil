import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/partido_resumen_dto.dart';

/// Listado de partidos para el dashboard de Admin — deliberadamente separado
/// de `StaffPartidosRepository` (aunque hoy comparten la misma lógica de
/// filtrado/ventana) para poder evolucionar cada uno sin afectar al otro.
/// Las operaciones sobre un partido (iniciar, registrar resultado, etc.) siguen
/// viviendo en `StaffPartidosRepository`, usadas por el sheet de detalle
/// compartido — eso sí es lógica de negocio común a ambos roles.
class AdminPartidosRepository {
  final Dio _dio = ApiClient.create();

  Future<List<PartidoResumenDto>> listar({
    String?   ligaId,
    String?   temporadaId,
    String?   estado,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final params = <String, dynamic>{'limit': 100};
    if (ligaId != null)      params['ligaId']      = ligaId;
    if (temporadaId != null) params['temporadaId'] = temporadaId;
    if (estado != null)      params['estado']      = estado;
    if (desde != null)       params['desde']       = desde.toUtc().toIso8601String();
    if (hasta != null)       params['hasta']       = hasta.toUtc().toIso8601String();

    try {
      final res = await _dio.get('/api/partidos/filtrados', queryParameters: params);
      return (res.data as List)
          .map((e) => PartidoResumenDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
