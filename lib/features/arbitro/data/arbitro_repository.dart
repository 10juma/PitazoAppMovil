import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/partido_resumen_dto.dart';

// ── DTOs ──────────────────────────────────────────────────────────────────────

class ArbitroPerfilDto {
  final String  id;
  final String  nombreCompleto;
  final String  email;
  final String? telefono;
  final String? fotoUrl;
  final String? licencia;
  final double? tarifaPorPartido;
  final int     totalPartidos;
  final int     partidosEsteAnio;
  final double  calificacionPromedio;
  final int     totalCalificaciones;

  const ArbitroPerfilDto({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    this.telefono,
    this.fotoUrl,
    this.licencia,
    this.tarifaPorPartido,
    required this.totalPartidos,
    required this.partidosEsteAnio,
    required this.calificacionPromedio,
    required this.totalCalificaciones,
  });

  factory ArbitroPerfilDto.fromJson(Map<String, dynamic> j) => ArbitroPerfilDto(
        id:                   j['id']?.toString()                         ?? '',
        nombreCompleto:       j['nombreCompleto']            as String?   ?? '',
        email:                j['email']                     as String?   ?? '',
        telefono:             j['telefono']                  as String?,
        fotoUrl:              j['fotoUrl']                   as String?,
        licencia:             j['licencia']                  as String?,
        tarifaPorPartido:     (j['tarifaPorPartido']         as num?)?.toDouble(),
        totalPartidos:        j['totalPartidos']             as int?      ?? 0,
        partidosEsteAnio:     j['partidosEsteAnio']          as int?      ?? 0,
        calificacionPromedio: (j['calificacionPromedio']     as num?)?.toDouble() ?? 0.0,
        totalCalificaciones:  j['totalCalificaciones']       as int?      ?? 0,
      );

  ArbitroPerfilDto copyWith({String? fotoUrl}) => ArbitroPerfilDto(
        id:                   id,
        nombreCompleto:       nombreCompleto,
        email:                email,
        telefono:             telefono,
        fotoUrl:              fotoUrl ?? this.fotoUrl,
        licencia:             licencia,
        tarifaPorPartido:     tarifaPorPartido,
        totalPartidos:        totalPartidos,
        partidosEsteAnio:     partidosEsteAnio,
        calificacionPromedio: calificacionPromedio,
        totalCalificaciones:  totalCalificaciones,
      );
}

class ResumenEvaluacionesDto {
  final int    total;
  final double promedioGeneral;
  final double promPuntualidad;
  final double promConocimiento;
  final double promTrato;
  final double promImparcialidad;

  const ResumenEvaluacionesDto({
    required this.total,
    required this.promedioGeneral,
    required this.promPuntualidad,
    required this.promConocimiento,
    required this.promTrato,
    required this.promImparcialidad,
  });

  factory ResumenEvaluacionesDto.fromJson(Map<String, dynamic> j) => ResumenEvaluacionesDto(
        total:             j['total']             as int?    ?? 0,
        promedioGeneral:   (j['promedioGeneral']  as num?)?.toDouble() ?? 0.0,
        promPuntualidad:   (j['promPuntualidad']  as num?)?.toDouble() ?? 0.0,
        promConocimiento:  (j['promConocimiento'] as num?)?.toDouble() ?? 0.0,
        promTrato:         (j['promTrato']        as num?)?.toDouble() ?? 0.0,
        promImparcialidad: (j['promImparcialidad']as num?)?.toDouble() ?? 0.0,
      );

  static const ResumenEvaluacionesDto vacio = ResumenEvaluacionesDto(
    total: 0, promedioGeneral: 0, promPuntualidad: 0,
    promConocimiento: 0, promTrato: 0, promImparcialidad: 0,
  );
}

class EvaluacionHistorialDto {
  final String    id;
  final String?   partidoLabel;
  final DateTime? partidoFecha;
  final String    evaluadoPorNombre;
  final String    tipoEvaluadorLabel;
  final int       puntualidad;
  final int       conocimiento;
  final int       trato;
  final int       imparcialidad;
  final double    promedio;
  final String?   comentario;
  final DateTime  creadoEn;

  const EvaluacionHistorialDto({
    required this.id,
    this.partidoLabel,
    this.partidoFecha,
    required this.evaluadoPorNombre,
    required this.tipoEvaluadorLabel,
    required this.puntualidad,
    required this.conocimiento,
    required this.trato,
    required this.imparcialidad,
    required this.promedio,
    this.comentario,
    required this.creadoEn,
  });

  factory EvaluacionHistorialDto.fromJson(Map<String, dynamic> j) => EvaluacionHistorialDto(
        id:                  j['id']?.toString()                 ?? '',
        partidoLabel:        j['partidoLabel']    as String?,
        partidoFecha:        j['partidoFecha']    != null
            ? DateTime.parse(j['partidoFecha'] as String).toLocal()
            : null,
        evaluadoPorNombre:   j['evaluadoPorNombre']  as String? ?? '',
        tipoEvaluadorLabel:  j['tipoEvaluadorLabel'] as String? ?? '',
        puntualidad:         j['puntualidad']         as int?   ?? 0,
        conocimiento:        j['conocimiento']         as int?   ?? 0,
        trato:               j['trato']                as int?   ?? 0,
        imparcialidad:       j['imparcialidad']        as int?   ?? 0,
        promedio:            (j['promedio']            as num?)?.toDouble() ?? 0.0,
        comentario:          j['comentario']           as String?,
        creadoEn:            DateTime.parse(j['creadoEn'] as String).toLocal(),
      );
}

// ── Repository ────────────────────────────────────────────────────────────────

class ArbitroRepository {
  final Dio _dio = ApiClient.create();

  Future<ArbitroPerfilDto> obtenerPerfil() async {
    try {
      final res = await _dio.get('/api/arbitro/perfil');
      return ArbitroPerfilDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<String> subirFoto(File file) async {
    try {
      final form = FormData.fromMap({'foto': await MultipartFile.fromFile(file.path)});
      final res  = await _dio.post('/api/arbitro/foto', data: form);
      return (res.data as Map<String, dynamic>)['fotoUrl'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<PartidoResumenDto>> listarPartidos({int? estado}) async {
    final params = <String, dynamic>{'limit': 200};
    if (estado != null) params['estado'] = estado;
    try {
      final res = await _dio.get('/api/arbitro/partidos', queryParameters: params);
      return (res.data as List)
          .map((e) => PartidoResumenDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<PartidoResumenDto>> listarEnVivo() async {
    try {
      final res = await _dio.get('/api/arbitro/partidos/envivo');
      return (res.data as List)
          .map((e) => PartidoResumenDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<PartidoResumenDto>> listarProximos({int cantidad = 5}) async {
    try {
      final res = await _dio.get(
        '/api/arbitro/partidos/proximos',
        queryParameters: {'cantidad': cantidad},
      );
      return (res.data as List)
          .map((e) => PartidoResumenDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> iniciarPartido(String id) async {
    try {
      await _dio.post('/api/arbitro/partidos/$id/iniciar');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ResumenEvaluacionesDto> obtenerResumen() async {
    try {
      final res = await _dio.get('/api/arbitro/evaluaciones/resumen');
      return ResumenEvaluacionesDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<EvaluacionHistorialDto>> listarEvaluaciones() async {
    try {
      final res = await _dio.get('/api/arbitro/evaluaciones');
      return (res.data as List)
          .map((e) => EvaluacionHistorialDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
