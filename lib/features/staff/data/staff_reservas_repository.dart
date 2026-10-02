import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/reserva_dto.dart';

class StaffReservasRepository {
  final Dio _dio = ApiClient.create();

  Future<({
    bool                  activa,
    List<ReservaDto>      listado,
    List<CanchaSimple>    canchas,
    List<EquipoSimpleR>   equipos,
  })> cargar({String? fecha, String? canchaId, int? estado}) async {
    try {
      final res = await _dio.get('/api/staff-portal/reservas', queryParameters: {
        if (fecha     != null) 'fecha':    fecha,
        if (canchaId  != null) 'canchaId': canchaId,
        if (estado    != null) 'estado':   estado,
      });
      final d = res.data as Map<String, dynamic>;
      return (
        activa:   d['reservasCanchasActiva'] as bool? ?? false,
        listado:  (d['listado']  as List? ?? []).map((e) => ReservaDto.fromJson(e as Map<String, dynamic>)).toList(),
        canchas:  (d['canchas']  as List? ?? []).map((e) => CanchaSimple.fromJson(e as Map<String, dynamic>)).toList(),
        equipos:  (d['equipos']  as List? ?? []).map((e) => EquipoSimpleR.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ReservaDto> obtenerDetalle(String id) async {
    try {
      final res = await _dio.get('/api/staff-portal/reservas/$id');
      return ReservaDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> crear({
    required String canchaId,
    required String fecha,
    required int    horaInicio,
    required int    duracionHoras,
    required String nombreCliente,
    String?         telefono,
    String?         email,
    String?         equipoId,
    int?            metodoPago,
    bool            depositoPagado = false,
    bool            totalPagado    = false,
    String?         notaInterna,
    String?         notaCliente,
  }) async {
    try {
      await _dio.post('/api/staff-portal/reservas', data: {
        'canchaId':        canchaId,
        'fecha':           fecha,
        'horaInicio':      '${horaInicio.toString().padLeft(2, '0')}:00:00',
        'duracionMin':     duracionHoras * 60,
        'nombreCliente':   nombreCliente,
        'telefonoCliente': telefono?.trim().isEmpty == true ? null : telefono?.trim(),
        'emailCliente':    email?.trim().isEmpty == true ? null : email?.trim(),
        'equipoId':        equipoId?.isEmpty == true ? null : equipoId,
        'metodoPago':      metodoPago,
        'depositoPagado':  depositoPagado,
        'totalPagado':     totalPagado,
        'notaInterna':     notaInterna?.trim().isEmpty == true ? null : notaInterna?.trim(),
        'notaCliente':     notaCliente?.trim().isEmpty == true ? null : notaCliente?.trim(),
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> actualizar(
    String id, {
    required String canchaId,
    required String fecha,
    required int    horaInicio,
    required int    duracionHoras,
    required String nombreCliente,
    String?         telefono,
    String?         email,
    String?         equipoId,
    int?            metodoPago,
    bool            depositoPagado = false,
    bool            totalPagado    = false,
    String?         notaInterna,
    String?         notaCliente,
  }) async {
    try {
      await _dio.put('/api/staff-portal/reservas/$id', data: {
        'canchaId':        canchaId,
        'fecha':           fecha,
        'horaInicio':      '${horaInicio.toString().padLeft(2, '0')}:00:00',
        'duracionMin':     duracionHoras * 60,
        'nombreCliente':   nombreCliente,
        'telefonoCliente': telefono?.trim().isEmpty == true ? null : telefono?.trim(),
        'emailCliente':    email?.trim().isEmpty == true ? null : email?.trim(),
        'equipoId':        equipoId?.isEmpty == true ? null : equipoId,
        'metodoPago':      metodoPago,
        'depositoPagado':  depositoPagado,
        'totalPagado':     totalPagado,
        'notaInterna':     notaInterna?.trim().isEmpty == true ? null : notaInterna?.trim(),
        'notaCliente':     notaCliente?.trim().isEmpty == true ? null : notaCliente?.trim(),
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> cambiarEstado(String id, EstadoReserva estado, {String? motivo}) async {
    try {
      await _dio.patch('/api/staff-portal/reservas/$id/estado', data: {
        'estado': estado.valor,
        'motivo': motivo,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
