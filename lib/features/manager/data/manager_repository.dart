import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/enums/estado_partido.dart';

// ── DTOs ─────────────────────────────────────────────────────────────────────

class EquipoManagerDto {
  final String  equipoId;
  final String  nombre;
  final String? logoUrl;
  final String? colorPrincipal;
  final String? participacionId;
  final String? temporadaId;
  final String? temporadaNombre;
  final String? ligaNombre;

  const EquipoManagerDto({
    required this.equipoId,
    required this.nombre,
    this.logoUrl,
    this.colorPrincipal,
    this.participacionId,
    this.temporadaId,
    this.temporadaNombre,
    this.ligaNombre,
  });

  factory EquipoManagerDto.fromJson(Map<String, dynamic> j) => EquipoManagerDto(
        equipoId:        j['equipoId']        as String,
        nombre:          j['nombre']          as String? ?? '',
        logoUrl:         j['logoUrl']         as String?,
        colorPrincipal:  j['colorPrincipal']  as String?,
        participacionId: j['participacionId'] as String?,
        temporadaId:     j['temporadaId']     as String?,
        temporadaNombre: j['temporadaNombre'] as String?,
        ligaNombre:      j['ligaNombre']      as String?,
      );
}

/// Una competencia (liga + temporada) activa en la que el equipo participa simultáneamente.
class ParticipacionResumenDto {
  final String participacionId;
  final String temporadaId;
  final String temporadaNombre;
  final String ligaId;
  final String ligaNombre;

  const ParticipacionResumenDto({
    required this.participacionId,
    required this.temporadaId,
    required this.temporadaNombre,
    required this.ligaId,
    required this.ligaNombre,
  });

  factory ParticipacionResumenDto.fromJson(Map<String, dynamic> j) => ParticipacionResumenDto(
        participacionId: j['participacionId'] as String,
        temporadaId:     j['temporadaId']     as String? ?? '',
        temporadaNombre: j['temporadaNombre'] as String? ?? '',
        ligaId:          j['ligaId']          as String? ?? '',
        ligaNombre:      j['ligaNombre']      as String? ?? '',
      );
}

class FilaPosicionDto {
  final int    posicion;
  final String nombre;
  final int    pj;
  final int    pg;
  final int    pe;
  final int    pp;
  final int    gf;
  final int    gc;
  final int    pts;
  final String racha;

  int get dg => gf - gc;

  const FilaPosicionDto({
    required this.posicion,
    required this.nombre,
    required this.pj,
    required this.pg,
    required this.pe,
    required this.pp,
    required this.gf,
    required this.gc,
    required this.pts,
    required this.racha,
  });

  factory FilaPosicionDto.fromJson(Map<String, dynamic> j) => FilaPosicionDto(
        posicion: j['posicion'] as int? ?? 0,
        nombre:   j['nombre']   as String? ?? '',
        pj:       j['pj']       as int? ?? 0,
        pg:       j['pg']       as int? ?? 0,
        pe:       j['pe']       as int? ?? 0,
        pp:       j['pp']       as int? ?? 0,
        gf:       j['gf']       as int? ?? 0,
        gc:       j['gc']       as int? ?? 0,
        pts:      j['pts']      as int? ?? 0,
        racha:    j['racha']    as String? ?? '',
      );
}

class PartidoManagerDto {
  final String         id;
  final String         equipoLocalId;
  final String         equipoLocalNombre;
  final String?        equipoLocalLogo;
  final String?        equipoLocalColor;
  final String         equipoVisitanteId;
  final String         equipoVisitanteNombre;
  final String?        equipoVisitanteLogo;
  final String?        equipoVisitanteColor;
  final String?        canchaNombre;
  final String?        arbitroId;
  final String?        arbitroNombre;
  final DateTime       fechaHora;
  final EstadoPartido  estado;
  final String         estadoLabel;
  final int            golesLocal;
  final int            golesVisitante;
  final String         ligaNombre;
  final String         temporadaNombre;
  final String         faseNombre;
  final int            jornadaNumero;

  const PartidoManagerDto({
    required this.id,
    required this.equipoLocalId,
    required this.equipoLocalNombre,
    this.equipoLocalLogo,
    this.equipoLocalColor,
    required this.equipoVisitanteId,
    required this.equipoVisitanteNombre,
    this.equipoVisitanteLogo,
    this.equipoVisitanteColor,
    this.canchaNombre,
    this.arbitroId,
    this.arbitroNombre,
    required this.fechaHora,
    required this.estado,
    required this.estadoLabel,
    required this.golesLocal,
    required this.golesVisitante,
    required this.ligaNombre,
    required this.temporadaNombre,
    required this.faseNombre,
    required this.jornadaNumero,
  });

  static EstadoPartido _parseEstado(dynamic v) => switch (v as int? ?? 0) {
        2 => EstadoPartido.enCurso,
        3 => EstadoPartido.terminado,
        4 => EstadoPartido.suspendido,
        5 => EstadoPartido.cancelado,
        _ => EstadoPartido.programado,
      };

  factory PartidoManagerDto.fromJson(Map<String, dynamic> j) => PartidoManagerDto(
        id:                    j['id']                    as String,
        equipoLocalId:         j['equipoLocalId']?.toString()       ?? '',
        equipoLocalNombre:     j['equipoLocalNombre']              as String? ?? '',
        equipoLocalLogo:       j['equipoLocalLogo']                as String?,
        equipoLocalColor:      j['equipoLocalColor']               as String?,
        equipoVisitanteId:     j['equipoVisitanteId']?.toString()   ?? '',
        equipoVisitanteNombre: j['equipoVisitanteNombre']          as String? ?? '',
        equipoVisitanteLogo:   j['equipoVisitanteLogo']            as String?,
        equipoVisitanteColor:  j['equipoVisitanteColor']           as String?,
        canchaNombre:          j['canchaNombre']                   as String?,
        arbitroId:             j['arbitroId']?.toString(),
        arbitroNombre:         j['arbitroNombre']                  as String?,
        fechaHora:             DateTime.parse(j['fechaHora'] as String).toLocal(),
        estado:                _parseEstado(j['estado']),
        estadoLabel:           j['estadoLabel']                    as String? ?? '',
        golesLocal:            j['golesLocal']                     as int? ?? 0,
        golesVisitante:        j['golesVisitante']                 as int? ?? 0,
        ligaNombre:            j['ligaNombre']                     as String? ?? '',
        temporadaNombre:       j['temporadaNombre']                as String? ?? '',
        faseNombre:            j['faseNombre']                     as String? ?? '',
        jornadaNumero:         j['jornadaNumero']                  as int? ?? 0,
      );
}

class ManagerDashboardDto {
  final List<PartidoManagerDto> enVivo;
  final List<PartidoManagerDto> proximosPartidos;
  final int     jugadoresActivos;
  final int     jugadoresSancionados;
  final int     cuotasPendientes;
  final double  montoCuotasPendientes;
  final FilaPosicionDto? posicion;
  final String? faseNombre;

  const ManagerDashboardDto({
    required this.enVivo,
    required this.proximosPartidos,
    required this.jugadoresActivos,
    required this.jugadoresSancionados,
    required this.cuotasPendientes,
    required this.montoCuotasPendientes,
    this.posicion,
    this.faseNombre,
  });

  static const vacio = ManagerDashboardDto(
    enVivo: [], proximosPartidos: [],
    jugadoresActivos: 0, jugadoresSancionados: 0,
    cuotasPendientes: 0, montoCuotasPendientes: 0,
  );

  factory ManagerDashboardDto.fromJson(Map<String, dynamic> j) => ManagerDashboardDto(
        enVivo:               (j['enVivo'] as List<dynamic>? ?? [])
            .map((e) => PartidoManagerDto.fromJson(e as Map<String, dynamic>)).toList(),
        proximosPartidos:     (j['proximosPartidos'] as List<dynamic>? ?? [])
            .map((e) => PartidoManagerDto.fromJson(e as Map<String, dynamic>)).toList(),
        jugadoresActivos:       j['jugadoresActivos']       as int? ?? 0,
        jugadoresSancionados:   j['jugadoresSancionados']   as int? ?? 0,
        cuotasPendientes:       j['cuotasPendientes']       as int? ?? 0,
        montoCuotasPendientes:  (j['montoCuotasPendientes'] as num?)?.toDouble() ?? 0,
        posicion: j['posicion'] != null
            ? FilaPosicionDto.fromJson(j['posicion'] as Map<String, dynamic>)
            : null,
        faseNombre: j['faseNombre'] as String?,
      );
}

class ConfirmacionDto {
  final String  id;
  final String  jugadorEquipoId;
  final String  nombreCompleto;
  final String? fotoUrl;
  final int?    dorsal;
  final bool?   confirma;
  final int?    motivo;
  final String? motivoLabel;

  const ConfirmacionDto({
    required this.id,
    required this.jugadorEquipoId,
    required this.nombreCompleto,
    this.fotoUrl,
    this.dorsal,
    this.confirma,
    this.motivo,
    this.motivoLabel,
  });

  factory ConfirmacionDto.fromJson(Map<String, dynamic> j) => ConfirmacionDto(
        id:              j['id']              as String,
        jugadorEquipoId: j['jugadorEquipoId']?.toString() ?? '',
        nombreCompleto:  j['nombreCompleto']  as String? ?? '',
        fotoUrl:         j['fotoUrl']         as String?,
        dorsal:          j['dorsal']          as int?,
        confirma:        j['confirma']        as bool?,
        motivo:          j['motivo']          as int?,
        motivoLabel:     j['motivoLabel']     as String?,
      );
}

class PagoJugadorDto {
  final String   id;
  final String   jugadorEquipoId;
  final String   nombreJugador;
  final String?  fotoUrl;
  final String   concepto;
  final double   monto;
  final bool     pagado;
  final DateTime? pagadoEn;
  final DateTime  venceEn;
  final bool     vencido;
  final String?  partidoId;
  final String?  partidoLabel;

  const PagoJugadorDto({
    required this.id,
    required this.jugadorEquipoId,
    required this.nombreJugador,
    this.fotoUrl,
    required this.concepto,
    required this.monto,
    required this.pagado,
    this.pagadoEn,
    required this.venceEn,
    required this.vencido,
    this.partidoId,
    this.partidoLabel,
  });

  factory PagoJugadorDto.fromJson(Map<String, dynamic> j) => PagoJugadorDto(
        id:              j['id']              as String,
        jugadorEquipoId: j['jugadorEquipoId']?.toString() ?? '',
        nombreJugador:   j['nombreJugador']   as String? ?? '',
        fotoUrl:         j['fotoUrl']         as String?,
        concepto:        j['concepto']        as String? ?? '',
        monto:           (j['monto']          as num?)?.toDouble() ?? 0,
        pagado:          j['pagado']          as bool? ?? false,
        pagadoEn:        j['pagadoEn'] != null ? DateTime.parse(j['pagadoEn'] as String).toLocal() : null,
        venceEn:         DateTime.parse(j['venceEn'] as String).toLocal(),
        vencido:         j['vencido']         as bool? ?? false,
        partidoId:       j['partidoId']?.toString(),
        partidoLabel:    j['partidoLabel']    as String?,
      );
}

class EventoPartidoDto {
  final String  id;
  final String  tipoLabel;
  final int     minuto;
  final String? jugadorNombre;
  final String? equipoNombre;

  const EventoPartidoDto({
    required this.id, required this.tipoLabel, required this.minuto,
    this.jugadorNombre, this.equipoNombre,
  });

  factory EventoPartidoDto.fromJson(Map<String, dynamic> j) => EventoPartidoDto(
        id:            j['id']            as String,
        tipoLabel:     j['tipoLabel']     as String? ?? '',
        minuto:        j['minuto']        as int? ?? 0,
        jugadorNombre: j['jugadorNombre'] as String?,
        equipoNombre:  j['equipoNombre']  as String?,
      );
}

/// Detalle completo de un partido (GET /api/partidos/{id}) — incluye eventos y cuota.
class PartidoCompletoDto extends PartidoManagerDto {
  final double?  cuotaMonto;
  final bool     pagoEquipoLocal;
  final bool     pagoEquipoVisitante;
  final List<EventoPartidoDto> eventos;

  const PartidoCompletoDto({
    required super.id,
    required super.equipoLocalId,
    required super.equipoLocalNombre,
    super.equipoLocalLogo,
    super.equipoLocalColor,
    required super.equipoVisitanteId,
    required super.equipoVisitanteNombre,
    super.equipoVisitanteLogo,
    super.equipoVisitanteColor,
    super.canchaNombre,
    super.arbitroId,
    super.arbitroNombre,
    required super.fechaHora,
    required super.estado,
    required super.estadoLabel,
    required super.golesLocal,
    required super.golesVisitante,
    required super.ligaNombre,
    required super.temporadaNombre,
    required super.faseNombre,
    required super.jornadaNumero,
    this.cuotaMonto,
    required this.pagoEquipoLocal,
    required this.pagoEquipoVisitante,
    required this.eventos,
  });

  factory PartidoCompletoDto.fromJson(Map<String, dynamic> j) {
    final base = PartidoManagerDto.fromJson(j);
    return PartidoCompletoDto(
      id: base.id,
      equipoLocalId: base.equipoLocalId, equipoLocalNombre: base.equipoLocalNombre,
      equipoLocalLogo: base.equipoLocalLogo, equipoLocalColor: base.equipoLocalColor,
      equipoVisitanteId: base.equipoVisitanteId, equipoVisitanteNombre: base.equipoVisitanteNombre,
      equipoVisitanteLogo: base.equipoVisitanteLogo, equipoVisitanteColor: base.equipoVisitanteColor,
      canchaNombre: base.canchaNombre, arbitroId: base.arbitroId, arbitroNombre: base.arbitroNombre,
      fechaHora: base.fechaHora, estado: base.estado, estadoLabel: base.estadoLabel,
      golesLocal: base.golesLocal, golesVisitante: base.golesVisitante,
      ligaNombre: base.ligaNombre, temporadaNombre: base.temporadaNombre,
      faseNombre: base.faseNombre, jornadaNumero: base.jornadaNumero,
      cuotaMonto:          (j['cuotaMonto'] as num?)?.toDouble(),
      pagoEquipoLocal:     j['pagoEquipoLocal']     as bool? ?? false,
      pagoEquipoVisitante: j['pagoEquipoVisitante'] as bool? ?? false,
      eventos: (j['eventos'] as List<dynamic>? ?? [])
          .map((e) => EventoPartidoDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ManagerPerfilDto {
  final String  nombreCompleto;
  final String  email;
  final String  fNombre;
  final String  fApellido;
  final String? fTelefono;
  final String? fotoUrl;

  const ManagerPerfilDto({
    required this.nombreCompleto, required this.email,
    required this.fNombre, required this.fApellido, this.fTelefono, this.fotoUrl,
  });

  factory ManagerPerfilDto.fromJson(Map<String, dynamic> j) => ManagerPerfilDto(
        nombreCompleto: j['nombreCompleto'] as String? ?? '',
        email:          j['email']          as String? ?? '',
        fNombre:        j['fNombre']         as String? ?? '',
        fApellido:      j['fApellido']       as String? ?? '',
        fTelefono:      j['fTelefono']       as String?,
        fotoUrl:        j['fotoUrl']         as String?,
      );

  ManagerPerfilDto copyWith({
    String? nombreCompleto, String? fNombre, String? fApellido, String? fTelefono, String? fotoUrl,
  }) => ManagerPerfilDto(
        nombreCompleto: nombreCompleto ?? this.nombreCompleto,
        email:          email,
        fNombre:        fNombre   ?? this.fNombre,
        fApellido:      fApellido ?? this.fApellido,
        fTelefono:      fTelefono ?? this.fTelefono,
        fotoUrl:        fotoUrl   ?? this.fotoUrl,
      );
}

enum ZonaJugador { titular, banca, disponible }

class JugadorAlineacion {
  final String  jugadorEquipoId;
  final String  nombreCompleto;
  final String? fotoUrl;
  final int?    dorsal;
  final String  posicionLabel;
  ZonaJugador   zona;
  double        posX;
  double        posY;
  int?          dorsalPartido;

  JugadorAlineacion({
    required this.jugadorEquipoId,
    required this.nombreCompleto,
    this.fotoUrl,
    this.dorsal,
    required this.posicionLabel,
    required this.zona,
    this.posX = 50,
    this.posY = 50,
    this.dorsalPartido,
  });

  factory JugadorAlineacion.fromJson(Map<String, dynamic> j, ZonaJugador zona) => JugadorAlineacion(
        jugadorEquipoId: j['jugadorEquipoId'] as String,
        nombreCompleto:  j['nombreCompleto']  as String? ?? '',
        fotoUrl:         j['fotoUrl']         as String?,
        dorsal:          j['dorsal']          as int?,
        posicionLabel:   j['posicionLabel']   as String? ?? '',
        zona:            zona,
        posX:            (j['posX'] as num?)?.toDouble() ?? 50,
        posY:            (j['posY'] as num?)?.toDouble() ?? 50,
        dorsalPartido:   j['dorsalPartido']   as int? ?? j['dorsal'] as int?,
      );
}

class AlineacionDto {
  final bool   editable;
  final int    jugadoresEnCampo;
  final int    suplentesPermitidos;
  final int    jugadoresMaxPorEquipo;
  final List<JugadorAlineacion> jugadores;

  const AlineacionDto({
    required this.editable,
    required this.jugadoresEnCampo,
    required this.suplentesPermitidos,
    required this.jugadoresMaxPorEquipo,
    required this.jugadores,
  });

  factory AlineacionDto.fromJson(Map<String, dynamic> j) => AlineacionDto(
        editable:              j['editable']              as bool? ?? false,
        jugadoresEnCampo:      j['jugadoresEnCampo']       as int?  ?? 7,
        suplentesPermitidos:   j['suplentesPermitidos']    as int?  ?? 0,
        jugadoresMaxPorEquipo: j['jugadoresMaxPorEquipo']  as int?  ?? 0,
        jugadores: [
          ...(j['titulares'] as List<dynamic>? ?? [])
              .map((e) => JugadorAlineacion.fromJson(e as Map<String, dynamic>, ZonaJugador.titular)),
          ...(j['banca'] as List<dynamic>? ?? [])
              .map((e) => JugadorAlineacion.fromJson(e as Map<String, dynamic>, ZonaJugador.banca)),
          ...(j['disponibles'] as List<dynamic>? ?? [])
              .map((e) => JugadorAlineacion.fromJson(e as Map<String, dynamic>, ZonaJugador.disponible)),
        ],
      );
}

// ── Repository ────────────────────────────────────────────────────────────────

class ManagerRepository {
  final Dio _dio = ApiClient.create();

  Future<ManagerPerfilDto> obtenerPerfil() async {
    try {
      final r = await _dio.get('/api/manager/perfil');
      return ManagerPerfilDto.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<void> actualizarPerfil({
    required String nombre,
    required String apellido,
    String?         telefono,
  }) async {
    try {
      await _dio.put('/api/manager/perfil', data: {
        'nombre':   nombre,
        'apellido': apellido,
        'telefono': telefono,
      });
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<List<EquipoManagerDto>> listarEquipos({String? participacionId}) async {
    try {
      final r = await _dio.get('/api/manager/equipos',
          queryParameters: participacionId != null ? {'participacionId': participacionId} : null);
      return (r.data as List<dynamic>)
          .map((e) => EquipoManagerDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  /// Competencias (liga+temporada) activas en las que el equipo participa simultáneamente.
  Future<List<ParticipacionResumenDto>> listarParticipaciones(String equipoId) async {
    try {
      final r = await _dio.get('/api/manager/$equipoId/participaciones');
      return (r.data as List<dynamic>)
          .map((e) => ParticipacionResumenDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<ManagerDashboardDto> obtenerDashboard(String equipoId, {String? participacionId}) async {
    try {
      final r = await _dio.get('/api/manager/$equipoId/dashboard',
          queryParameters: participacionId != null ? {'participacionId': participacionId} : null);
      return ManagerDashboardDto.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<String?> subirFoto(File file) async {
    try {
      final form = FormData.fromMap({'foto': await MultipartFile.fromFile(file.path, filename: 'foto.jpg')});
      final r = await _dio.post('/api/manager/foto', data: form);
      return (r.data as Map<String, dynamic>)['fotoUrl'] as String?;
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<List<PartidoManagerDto>> listarPartidos(String equipoId, {EstadoPartido? estado}) async {
    try {
      final params = estado != null ? {'estado': estado.index + 1} : null;
      final r = await _dio.get('/api/manager/$equipoId/partidos', queryParameters: params);
      return (r.data as List<dynamic>)
          .map((e) => PartidoManagerDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  /// Detalle completo del partido (marcador, cuota, eventos) — solo lectura.
  Future<PartidoCompletoDto> obtenerPartido(String partidoId) async {
    try {
      final r = await _dio.get('/api/partidos/$partidoId');
      return PartidoCompletoDto.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<List<ConfirmacionDto>> obtenerConfirmaciones(String equipoId, String partidoId) async {
    try {
      final r = await _dio.get('/api/manager/$equipoId/partidos/$partidoId/confirmaciones');
      return (r.data as List<dynamic>)
          .map((e) => ConfirmacionDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<bool> actualizarConfirmacion(String equipoId, String partidoId, {
    required String jugadorEquipoId,
    bool?           confirma,
    int?            motivo,
  }) async {
    try {
      await _dio.put('/api/manager/$equipoId/partidos/$partidoId/confirmaciones', data: {
        'jugadorEquipoId': jugadorEquipoId,
        'confirma':        confirma,
        'motivo':          motivo,
      });
      return true;
    } on DioException { return false; }
  }

  Future<List<PagoJugadorDto>> obtenerPagos(String equipoId) async {
    try {
      final r = await _dio.get('/api/manager/$equipoId/pagos');
      return (r.data as List<dynamic>)
          .map((e) => PagoJugadorDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<bool> marcarPagado(String equipoId, String pagoId, {required bool pagado}) async {
    try {
      await _dio.patch('/api/manager/$equipoId/pagos/$pagoId', data: {'pagado': pagado});
      return true;
    } on DioException { return false; }
  }

  Future<bool> eliminarPago(String equipoId, String pagoId) async {
    try {
      await _dio.delete('/api/manager/$equipoId/pagos/$pagoId');
      return true;
    } on DioException { return false; }
  }

  /// Devuelve (creados, null) en éxito, o (null, mensajeError) en falla.
  Future<(int?, String?)> crearCobrosPartido(String equipoId, {
    required String  partidoId,
    required String  concepto,
    required double  monto,
    DateTime?        venceEn,
  }) async {
    try {
      final r = await _dio.post('/api/manager/$equipoId/cobros-partido', data: {
        'partidoId': partidoId,
        'concepto':  concepto,
        'monto':     monto,
        if (venceEn != null) 'venceEn': venceEn.toIso8601String(),
      });
      return ((r.data as Map<String, dynamic>)['creados'] as int?, null);
    } on DioException catch (e) {
      return (null, ApiException.fromDio(e).message);
    }
  }

  // Returns null if not yet rated, else {calificacion, comentario}
  Future<Map<String, dynamic>?> obtenerCalificacionArbitro(String equipoId, String partidoId) async {
    try {
      final r = await _dio.get('/api/manager/$equipoId/partidos/$partidoId/calificacion-arbitro');
      return r.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDio(e);
    }
  }

  Future<String?> calificarArbitro(String equipoId, String partidoId, {
    required int    calificacion,
    String?         comentario,
  }) async {
    try {
      await _dio.post('/api/manager/$equipoId/partidos/$partidoId/calificacion-arbitro', data: {
        'calificacion': calificacion,
        'comentario':   comentario,
      });
      return null;
    } on DioException catch (e) {
      return ApiException.fromDio(e).message;
    }
  }

  Future<AlineacionDto?> obtenerAlineacion(String equipoId, String partidoId) async {
    try {
      final r = await _dio.get('/api/manager/$equipoId/partidos/$partidoId/alineacion');
      return AlineacionDto.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDio(e);
    }
  }

  Future<String?> guardarAlineacion(String equipoId, String partidoId, List<JugadorAlineacion> jugadores) async {
    try {
      await _dio.put('/api/manager/$equipoId/partidos/$partidoId/alineacion', data: {
        'jugadores': jugadores
            .where((j) => j.zona != ZonaJugador.disponible)
            .map((j) => {
                  'jugadorEquipoId': j.jugadorEquipoId,
                  'esTitular':       j.zona == ZonaJugador.titular,
                  'posX':            j.zona == ZonaJugador.titular ? j.posX : null,
                  'posY':            j.zona == ZonaJugador.titular ? j.posY : null,
                  'dorsalPartido':   j.dorsalPartido,
                })
            .toList(),
      });
      return null;
    } on DioException catch (e) {
      return ApiException.fromDio(e).message;
    }
  }
}
