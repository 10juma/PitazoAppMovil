import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/en_vivo_dto.dart';

class EnVivoRepository {
  final Dio _dio = ApiClient.create();

  Future<EnVivoDto> obtener(String partidoId) async {
    try {
      final res = await _dio.get('/api/partidos/$partidoId/envivo');
      return EnVivoDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> agregarEvento(String partidoId, {
    required String equipoId,
    String? jugadorId,
    String? jugadorSecId,
    required int tipo,
    required int minuto,
    String? nota,
  }) async {
    try {
      await _dio.post('/api/partidos/$partidoId/envivo/eventos', data: {
        'equipoId':  equipoId,
        if (jugadorId    != null) 'jugadorId':    jugadorId,
        if (jugadorSecId != null) 'jugadorSecId': jugadorSecId,
        'tipo':      tipo,
        'minuto':    minuto,
        if (nota != null) 'nota': nota,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> eliminarEvento(String partidoId, String eventoId) async {
    try {
      await _dio.delete('/api/partidos/$partidoId/envivo/eventos/$eventoId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> terminar(String partidoId, {
    required int golesLocal,
    required int golesVisitante,
    bool tuvoProrroga = false,
    bool tuvoPenales  = false,
    int? golesLocalPenales,
    int? golesVisitantePenales,
  }) async {
    try {
      await _dio.post('/api/partidos/$partidoId/envivo/terminar', data: {
        'golesLocal':            golesLocal,
        'golesVisitante':        golesVisitante,
        'tuvoProrroga':          tuvoProrroga,
        'tuvoPenales':           tuvoPenales,
        if (golesLocalPenales    != null) 'golesLocalPenales':    golesLocalPenales,
        if (golesVisitantePenales != null) 'golesVisitantePenales': golesVisitantePenales,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
