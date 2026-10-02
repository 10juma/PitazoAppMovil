import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/partido_detalle_dto.dart';
import '../../../models/partido_resumen_dto.dart';

class EvaluacionArbitroDto {
  final String  id;
  final int     puntualidad;
  final int     conocimiento;
  final int     trato;
  final int     imparcialidad;
  final double  promedio;
  final String? comentario;
  final String  evaluadoPorNombre;

  const EvaluacionArbitroDto({
    required this.id,
    required this.puntualidad,
    required this.conocimiento,
    required this.trato,
    required this.imparcialidad,
    required this.promedio,
    this.comentario,
    required this.evaluadoPorNombre,
  });

  factory EvaluacionArbitroDto.fromJson(Map<String, dynamic> j) => EvaluacionArbitroDto(
        id:                j['id']?.toString()        ?? '',
        puntualidad:       j['puntualidad']            as int? ?? 0,
        conocimiento:      j['conocimiento']           as int? ?? 0,
        trato:             j['trato']                  as int? ?? 0,
        imparcialidad:     j['imparcialidad']          as int? ?? 0,
        promedio:          (j['promedio'] as num?)?.toDouble() ?? 0,
        comentario:        j['comentario']             as String?,
        evaluadoPorNombre: j['evaluadoPorNombre']      as String? ?? '',
      );
}

class StaffPartidosRepository {
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

  Future<PartidoDetalleDto> obtenerDetalle(String id) async {
    try {
      final res = await _dio.get('/api/partidos/$id');
      return PartidoDetalleDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<PartidoPreInicioDto> obtenerPreInicio(String id) async {
    try {
      final res = await _dio.get('/api/partidos/$id/pre-inicio');
      return PartidoPreInicioDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<CanchaSimpleDto>> listarCanchas() async {
    try {
      final res = await _dio.get('/api/staff-portal/canchas');
      final data = res.data as Map<String, dynamic>;
      final canchas = data['canchas'] as List? ?? [];
      return canchas
          .map((e) => CanchaSimpleDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> iniciar(
    String id, {
    required String arbitroId,
    required bool pagoLocal,
    required bool pagoVisitante,
  }) async {
    try {
      await _dio.post('/api/partidos/$id/iniciar', data: {
        'arbitroId':       arbitroId,
        'pagoLocal':       pagoLocal,
        'pagoVisitante':   pagoVisitante,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> registrarResultado(
    String id, {
    required int golesLocal,
    required int golesVisitante,
    required bool tuvoProrroga,
    required bool tuvoPenales,
    int? golesLocalPenales,
    int? golesVisitantePenales,
  }) async {
    try {
      await _dio.post('/api/partidos/$id/resultado', data: {
        'partidoId':             id,
        'golesLocal':            golesLocal,
        'golesVisitante':        golesVisitante,
        'tuvoProrroga':          tuvoProrroga,
        'tuvoPenales':           tuvoPenales,
        'golesLocalPenales':     golesLocalPenales,
        'golesVisitantePenales': golesVisitantePenales,
        'eventos':               [],
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> actualizarGenerales(
    String id, {
    required DateTime fechaHora,
    String? canchaId,
  }) async {
    try {
      await _dio.put('/api/partidos/$id/generales-staff', data: {
        'fechaHora': fechaHora.toUtc().toIso8601String(),
        'canchaId':  canchaId,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> cambiarEstado(String id, String estado) async {
    try {
      await _dio.patch('/api/partidos/$id/estado', data: {'estado': estado});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> cambiarEstadoStaff(String id, String estado) async {
    try {
      await _dio.patch('/api/partidos/$id/estado-staff', data: {'estado': estado});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> marcarPagoCuota(
    String id, {
    required bool pagoLocal,
    required bool pagoVisitante,
  }) async {
    try {
      await _dio.patch('/api/partidos/$id/pago-cuota', data: {
        'pagoLocal':     pagoLocal,
        'pagoVisitante': pagoVisitante,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<EvaluacionArbitroDto?> obtenerEvaluacionArbitro(String id) async {
    try {
      final res = await _dio.get('/api/partidos/$id/evaluacion-arbitro');
      final data = res.data;
      if (data == null || data is! Map<String, dynamic>) return null;
      return EvaluacionArbitroDto.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDio(e);
    }
  }

  Future<void> evaluarArbitro(
    String id, {
    required int    puntualidad,
    required int    conocimiento,
    required int    trato,
    required int    imparcialidad,
    String?         comentario,
  }) async {
    try {
      await _dio.post('/api/partidos/$id/evaluacion-arbitro', data: {
        'puntualidad':   puntualidad,
        'conocimiento':  conocimiento,
        'trato':         trato,
        'imparcialidad': imparcialidad,
        'comentario':    comentario,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<PartidoResumenDto>> listarPorFecha(DateTime fecha) async {
    final desde = DateTime(fecha.year, fecha.month, fecha.day);
    final hasta = desde.add(const Duration(hours: 23, minutes: 59, seconds: 59));
    try {
      final res = await _dio.get('/api/partidos/filtrados', queryParameters: {
        'desde': desde.toUtc().toIso8601String(),
        'hasta': hasta.toUtc().toIso8601String(),
        'limit': 200,
      });
      final list = (res.data as List)
          .map((e) => PartidoResumenDto.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
      return list;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
