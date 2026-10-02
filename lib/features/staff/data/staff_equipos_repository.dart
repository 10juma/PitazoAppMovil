import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/equipo_dto.dart';
import '../../../shared/enums/estado_equipo.dart';
import '../../../shared/enums/estado_jugador.dart';

class StaffEquiposRepository {
  final Dio _dio = ApiClient.create();

  Future<List<EquipoDto>> listar() async {
    try {
      final res = await _dio.get('/api/equipos');
      return (res.data as List)
          .map((e) => EquipoDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<EquipoDto> obtener(String id) async {
    try {
      final res = await _dio.get('/api/equipos/$id');
      return EquipoDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<bool> tieneWhatsApp() async {
    try {
      final res = await _dio.get('/api/tenant/addons');
      return (res.data as Map<String, dynamic>)['tieneWhatsApp'] as bool? ?? false;
    } catch (_) {
      return false; // safe default: no mostrar WA si falla
    }
  }

  Future<void> actualizarEquipo(
    String id, {
    required String nombre,
    String? logoUrl,
    required EstadoEquipo estado,
  }) async {
    try {
      await _dio.put('/api/equipos/$id', data: {
        'nombre':  nombre,
        'logoUrl': logoUrl,
        'estado':  _estadoInt(estado),
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> actualizarManager(
    String equipoId, {
    required String nombre,
    required String apellido,
    required String telefono,
    String? email,
  }) async {
    try {
      await _dio.put('/api/equipos/$equipoId/manager', data: {
        'nombre':   nombre,
        'apellido': apellido,
        'telefono': telefono,
        'email':    email,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> cambiarEstado(String id, EstadoEquipo estado) async {
    try {
      await _dio.patch('/api/equipos/$id/estado', data: {'estado': _estadoStr(estado)});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> agregarJugador(
    String equipoId, {
    required String nombre,
    required String apellido,
    required String fechaNacimiento,
    int? dorsal,
    String? posicion,
    String? identificadorUnico,
  }) async {
    try {
      await _dio.post('/api/equipos/$equipoId/jugadores', data: {
        'nombre':             nombre,
        'apellido':           apellido,
        'fechaNacimiento':    fechaNacimiento,
        'dorsalBase':         dorsal,
        'posicion':           _posicionInt(posicion), // int requerido por API
        'identificadorUnico': identificadorUnico,
        'estado':             1, // EstadoJugador.Activo = 1
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static int? _posicionInt(String? s) => switch (s) {
    'Portero'       => 1,
    'Defensa'       => 2,
    'Mediocampista' => 3,
    'Delantero'     => 4,
    _               => null,
  };

  Future<void> cambiarEstadoJugador(
    String equipoId, String jugadorId, EstadoJugador estado,
  ) async {
    try {
      await _dio.patch(
        '/api/equipos/$equipoId/jugadores/$jugadorId/estado',
        data: {'estado': _estadoJugadorStr(estado)},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static int _estadoInt(EstadoEquipo e) => switch (e) {
        EstadoEquipo.activo   => 1,
        EstadoEquipo.inactivo => 2,
        EstadoEquipo.disuelto => 3,
      };

  static String _estadoStr(EstadoEquipo e) => switch (e) {
        EstadoEquipo.inactivo => 'Inactivo',
        EstadoEquipo.disuelto => 'Disuelto',
        _                     => 'Activo',
      };

  static String _estadoJugadorStr(EstadoJugador e) => switch (e) {
        EstadoJugador.suspendido => 'Suspendido',
        EstadoJugador.lesionado  => 'Lesionado',
        EstadoJugador.inactivo   => 'Inactivo',
        _                        => 'Activo',
      };
}
