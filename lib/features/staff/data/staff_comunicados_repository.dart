import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/comunicado_dto.dart';

class StaffComunicadosRepository {
  final Dio _dio = ApiClient.create();

  Future<List<ComunicadoDto>> listar() async {
    try {
      final res = await _dio.get('/api/comunicados');
      return (res.data as List)
          .map((e) => ComunicadoDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<({
    bool               comunicacionEquiposActiva,
    List<TemporadaOpcion> temporadas,
    List<EquipoOpcionC>   equipos,
  })> opciones() async {
    try {
      final res = await _dio.get('/api/comunicados/opciones');
      final d   = res.data as Map<String, dynamic>;
      return (
        comunicacionEquiposActiva: d['comunicacionEquiposActiva'] as bool? ?? false,
        temporadas: (d['temporadas'] as List? ?? [])
            .map((e) => TemporadaOpcion.fromJson(e as Map<String, dynamic>))
            .toList(),
        equipos: (d['equipos'] as List? ?? [])
            .map((e) => EquipoOpcionC.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> enviar({
    required String titulo,
    required String cuerpo,
    required int    audiencia,
    int?            audienciaRol,
    String?         audienciaTemporadaId,
    String?         audienciaEquipoId,
    int?            filtroJugadores,
  }) async {
    try {
      await _dio.post('/api/comunicados', data: {
        'titulo':                titulo,
        'cuerpo':                cuerpo,
        'audiencia':             audiencia,
        'audienciaRol':          audienciaRol,
        'audienciaTemporadaId':  audienciaTemporadaId,
        'audienciaEquipoId':     audienciaEquipoId,
        'filtroJugadores':       filtroJugadores,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
