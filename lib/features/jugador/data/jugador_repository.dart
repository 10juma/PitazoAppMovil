import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/enums/estado_partido.dart';

// ── DTOs ─────────────────────────────────────────────────────────────────────

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

class EquipoJugadorDto {
  final String  jugadorEquipoId;
  final String  equipoId;
  final String  nombre;
  final String? logoUrl;
  final String? colorPrincipal;
  final String? fotoUrl;
  final String  posicionLabel;
  final int?    dorsal;
  final String? participacionId;
  final String? temporadaId;
  final String? temporadaNombre;
  final String? ligaNombre;

  const EquipoJugadorDto({
    required this.jugadorEquipoId,
    required this.equipoId,
    required this.nombre,
    this.logoUrl,
    this.colorPrincipal,
    this.fotoUrl,
    required this.posicionLabel,
    this.dorsal,
    this.participacionId,
    this.temporadaId,
    this.temporadaNombre,
    this.ligaNombre,
  });

  factory EquipoJugadorDto.fromJson(Map<String, dynamic> j) => EquipoJugadorDto(
        jugadorEquipoId: j['jugadorEquipoId'] as String,
        equipoId:        j['equipoId']        as String,
        nombre:          j['nombre']           as String? ?? '',
        logoUrl:         j['logoUrl']          as String?,
        colorPrincipal:  j['colorPrincipal']   as String?,
        fotoUrl:         j['fotoUrl']          as String?,
        posicionLabel:   j['posicionLabel']    as String? ?? '—',
        dorsal:          j['dorsal']           as int?,
        participacionId: j['participacionId']  as String?,
        temporadaId:     j['temporadaId']      as String?,
        temporadaNombre: j['temporadaNombre']  as String?,
        ligaNombre:      j['ligaNombre']       as String?,
      );
}

class PartidoJugadorDto {
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

  const PartidoJugadorDto({
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

  factory PartidoJugadorDto.fromJson(Map<String, dynamic> j) => PartidoJugadorDto(
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

/// Detalle completo de un partido (GET /api/partidos/{id}) — incluye eventos (minuto a minuto).
class PartidoCompletoDto extends PartidoJugadorDto {
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
    required this.eventos,
  });

  factory PartidoCompletoDto.fromJson(Map<String, dynamic> j) {
    final base = PartidoJugadorDto.fromJson(j);
    return PartidoCompletoDto(
      id:                    base.id,
      equipoLocalId:         base.equipoLocalId,
      equipoLocalNombre:     base.equipoLocalNombre,
      equipoLocalLogo:       base.equipoLocalLogo,
      equipoLocalColor:      base.equipoLocalColor,
      equipoVisitanteId:     base.equipoVisitanteId,
      equipoVisitanteNombre: base.equipoVisitanteNombre,
      equipoVisitanteLogo:   base.equipoVisitanteLogo,
      equipoVisitanteColor:  base.equipoVisitanteColor,
      canchaNombre:          base.canchaNombre,
      arbitroNombre:         base.arbitroNombre,
      fechaHora:             base.fechaHora,
      estado:                base.estado,
      estadoLabel:           base.estadoLabel,
      golesLocal:            base.golesLocal,
      golesVisitante:        base.golesVisitante,
      ligaNombre:            base.ligaNombre,
      temporadaNombre:       base.temporadaNombre,
      faseNombre:            base.faseNombre,
      jornadaNumero:         base.jornadaNumero,
      eventos: (j['eventos'] as List<dynamic>? ?? [])
          .map((e) => EventoPartidoDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class JugadorDashboardDto {
  final PartidoJugadorDto? proximoPartido;
  final bool?    miConfirma;
  final int?     miMotivo;
  final int      cuotasPendientes;
  final double   montoCuotasPendientes;
  final int      overall;
  final int      pj;
  final int      goles;
  final int      asistencias;
  final List<PartidoJugadorDto> enVivoRegistrado;

  const JugadorDashboardDto({
    this.proximoPartido,
    this.miConfirma,
    this.miMotivo,
    required this.cuotasPendientes,
    required this.montoCuotasPendientes,
    required this.overall,
    required this.pj,
    required this.goles,
    required this.asistencias,
    required this.enVivoRegistrado,
  });

  factory JugadorDashboardDto.fromJson(Map<String, dynamic> j) => JugadorDashboardDto(
        proximoPartido: j['proximoPartido'] != null
            ? PartidoJugadorDto.fromJson(j['proximoPartido'] as Map<String, dynamic>)
            : null,
        miConfirma:            (j['miConfirmacion'] as Map<String, dynamic>?)?['confirma'] as bool?,
        miMotivo:              (j['miConfirmacion'] as Map<String, dynamic>?)?['motivo'] as int?,
        cuotasPendientes:      j['cuotasPendientes']      as int? ?? 0,
        montoCuotasPendientes: (j['montoCuotasPendientes'] as num?)?.toDouble() ?? 0,
        overall:               j['overall']      as int? ?? 0,
        pj:                    j['pj']           as int? ?? 0,
        goles:                 j['goles']         as int? ?? 0,
        asistencias:           j['asistencias']   as int? ?? 0,
        enVivoRegistrado: (j['enVivoRegistrado'] as List<dynamic>? ?? [])
            .map((e) => PartidoJugadorDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FichaTecnicaDto {
  final String  nombre;
  final String? fotoUrl;
  final String  posicionLabel;
  final int?    dorsal;
  final int     ritmo;
  final int     tiro;
  final int     pase;
  final int     regate;
  final int     defensa;
  final int     fisico;
  final int     overall;

  const FichaTecnicaDto({
    required this.nombre, this.fotoUrl, required this.posicionLabel, this.dorsal,
    required this.ritmo, required this.tiro, required this.pase,
    required this.regate, required this.defensa, required this.fisico,
    required this.overall,
  });

  factory FichaTecnicaDto.fromJson(Map<String, dynamic> j) => FichaTecnicaDto(
        nombre:        j['nombre']        as String? ?? '',
        fotoUrl:       j['fotoUrl']       as String?,
        posicionLabel: j['posicionLabel'] as String? ?? '—',
        dorsal:        j['dorsal']        as int?,
        ritmo:         j['ritmo']         as int? ?? 50,
        tiro:          j['tiro']          as int? ?? 50,
        pase:          j['pase']          as int? ?? 50,
        regate:        j['regate']        as int? ?? 50,
        defensa:       j['defensa']       as int? ?? 50,
        fisico:        j['fisico']        as int? ?? 50,
        overall:       j['overall']       as int? ?? 50,
      );
}

class EstadisticasJugadorDto {
  final int    pj;
  final int    goles;
  final int    asistencias;
  final int    tarjetasAmarillas;
  final int    tarjetasRojas;
  final int    penalesMarcados;
  final int    penalesFallados;
  final int    lesiones;
  final double golesPorPartido;
  final int    minutosJugados;
  final int    partidosConvocado;
  final int    porcentajeAsistencia;

  const EstadisticasJugadorDto({
    required this.pj, required this.goles, required this.asistencias,
    required this.tarjetasAmarillas, required this.tarjetasRojas,
    required this.penalesMarcados, required this.penalesFallados,
    required this.lesiones, required this.golesPorPartido,
    required this.minutosJugados, required this.partidosConvocado,
    required this.porcentajeAsistencia,
  });

  factory EstadisticasJugadorDto.fromJson(Map<String, dynamic> j) => EstadisticasJugadorDto(
        pj:                   j['pj']                as int? ?? 0,
        goles:                j['goles']              as int? ?? 0,
        asistencias:          j['asistencias']        as int? ?? 0,
        tarjetasAmarillas:    j['tarjetasAmarillas']  as int? ?? 0,
        tarjetasRojas:        j['tarjetasRojas']      as int? ?? 0,
        penalesMarcados:      j['penalesMarcados']    as int? ?? 0,
        penalesFallados:      j['penalesFallados']    as int? ?? 0,
        lesiones:             j['lesiones']           as int? ?? 0,
        golesPorPartido:      (j['golesPorPartido'] as num?)?.toDouble() ?? 0,
        minutosJugados:       j['minutosJugados']     as int? ?? 0,
        partidosConvocado:    j['partidosConvocado']  as int? ?? 0,
        porcentajeAsistencia: j['porcentajeAsistencia'] as int? ?? 0,
      );
}

class FilaPosicionJugadorDto {
  final int    posicion;
  final String nombre;
  final int    pj, pg, pe, pp, gf, gc, pts;
  int get dg => gf - gc;

  const FilaPosicionJugadorDto({
    required this.posicion, required this.nombre,
    required this.pj, required this.pg, required this.pe, required this.pp,
    required this.gf, required this.gc, required this.pts,
  });

  factory FilaPosicionJugadorDto.fromJson(Map<String, dynamic> j) => FilaPosicionJugadorDto(
        posicion: j['posicion'] as int? ?? 0,
        nombre:   j['nombre']   as String? ?? '',
        pj: j['pj'] as int? ?? 0, pg: j['pg'] as int? ?? 0, pe: j['pe'] as int? ?? 0,
        pp: j['pp'] as int? ?? 0, gf: j['gf'] as int? ?? 0, gc: j['gc'] as int? ?? 0,
        pts: j['pts'] as int? ?? 0,
      );
}

class TablaPosicionesJugadorDto {
  final String faseNombre;
  final String? grupoNombre;
  final List<FilaPosicionJugadorDto> filas;

  const TablaPosicionesJugadorDto({required this.faseNombre, this.grupoNombre, required this.filas});

  factory TablaPosicionesJugadorDto.fromJson(Map<String, dynamic> j) => TablaPosicionesJugadorDto(
        faseNombre:  j['faseNombre']  as String? ?? '',
        grupoNombre: j['grupoNombre'] as String?,
        filas: (j['filas'] as List<dynamic>? ?? [])
            .map((e) => FilaPosicionJugadorDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ComunicadoJugadorDto {
  final String   id;
  final String   titulo;
  final String   cuerpo;
  final bool     leida;
  final DateTime creadaEn;

  const ComunicadoJugadorDto({
    required this.id, required this.titulo, required this.cuerpo,
    required this.leida, required this.creadaEn,
  });

  factory ComunicadoJugadorDto.fromJson(Map<String, dynamic> j) => ComunicadoJugadorDto(
        id:       j['id']       as String,
        titulo:   j['titulo']   as String? ?? '',
        cuerpo:   j['cuerpo']   as String? ?? '',
        leida:    j['leida']    as bool?   ?? false,
        creadaEn: DateTime.parse(j['creadaEn'] as String).toLocal(),
      );
}

class JugadorPerfilDto {
  final String  nombreCompleto;
  final String  email;
  final String  fNombre;
  final String  fApellido;
  final String? fTelefono;

  const JugadorPerfilDto({
    required this.nombreCompleto, required this.email,
    required this.fNombre, required this.fApellido, this.fTelefono,
  });

  factory JugadorPerfilDto.fromJson(Map<String, dynamic> j) => JugadorPerfilDto(
        nombreCompleto: j['nombreCompleto'] as String? ?? '',
        email:          j['email']          as String? ?? '',
        fNombre:        j['fNombre']         as String? ?? '',
        fApellido:      j['fApellido']       as String? ?? '',
        fTelefono:      j['fTelefono']       as String?,
      );

  JugadorPerfilDto copyWith({String? nombreCompleto, String? fNombre, String? fApellido, String? fTelefono}) =>
      JugadorPerfilDto(
        nombreCompleto: nombreCompleto ?? this.nombreCompleto,
        email:          email,
        fNombre:        fNombre   ?? this.fNombre,
        fApellido:      fApellido ?? this.fApellido,
        fTelefono:      fTelefono ?? this.fTelefono,
      );
}

// ── Repository ────────────────────────────────────────────────────────────────

class JugadorRepository {
  final Dio _dio = ApiClient.create();

  Future<List<EquipoJugadorDto>> listarEquipos({String? participacionId}) async {
    try {
      final r = await _dio.get('/api/jugador/equipos',
          queryParameters: participacionId != null ? {'participacionId': participacionId} : null);
      return (r.data as List<dynamic>)
          .map((e) => EquipoJugadorDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  /// Competencias (liga+temporada) activas en las que el equipo participa simultáneamente.
  Future<List<ParticipacionResumenDto>> listarParticipaciones(String jugadorEquipoId) async {
    try {
      final r = await _dio.get('/api/jugador/$jugadorEquipoId/participaciones');
      return (r.data as List<dynamic>)
          .map((e) => ParticipacionResumenDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<JugadorDashboardDto> obtenerDashboard(String jugadorEquipoId, {String? participacionId}) async {
    try {
      final r = await _dio.get('/api/jugador/$jugadorEquipoId/dashboard',
          queryParameters: participacionId != null ? {'participacionId': participacionId} : null);
      return JugadorDashboardDto.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<List<PartidoJugadorDto>> listarPartidos(String jugadorEquipoId, {EstadoPartido? estado, String? participacionId}) async {
    try {
      final params = <String, dynamic>{
        if (estado != null) 'estado': estado.index + 1,
        if (participacionId != null) 'participacionId': participacionId,
      };
      final r = await _dio.get('/api/jugador/$jugadorEquipoId/partidos',
          queryParameters: params.isEmpty ? null : params);
      return (r.data as List<dynamic>)
          .map((e) => PartidoJugadorDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  /// Detalle completo de un partido (marcador final + minuto a minuto).
  Future<PartidoCompletoDto> obtenerPartido(String partidoId) async {
    try {
      final r = await _dio.get('/api/partidos/$partidoId');
      return PartidoCompletoDto.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  /// Devuelve (confirma, motivo) — ambos null si no ha respondido.
  Future<(bool?, int?)> obtenerConfirmacion(String jugadorEquipoId, String partidoId) async {
    try {
      final r = await _dio.get('/api/jugador/$jugadorEquipoId/partidos/$partidoId/confirmacion');
      final data = r.data as Map<String, dynamic>;
      return (data['confirma'] as bool?, data['motivo'] as int?);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<String?> confirmar(String jugadorEquipoId, String partidoId, {bool? confirma, int? motivo}) async {
    try {
      await _dio.post('/api/jugador/$jugadorEquipoId/partidos/$partidoId/confirmacion', data: {
        'jugadorEquipoId': jugadorEquipoId,
        'confirma':        confirma,
        'motivo':          motivo,
      });
      return null;
    } on DioException catch (e) {
      return ApiException.fromDio(e).message;
    }
  }

  Future<String?> subirFoto(String jugadorEquipoId, File file) async {
    try {
      final form = FormData.fromMap({'foto': await MultipartFile.fromFile(file.path, filename: 'foto.jpg')});
      final r = await _dio.post('/api/jugador/$jugadorEquipoId/foto', data: form);
      return (r.data as Map<String, dynamic>)['fotoUrl'] as String?;
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  /// Devuelve (ficha, estadisticasAvanzadasActivas).
  Future<(FichaTecnicaDto?, bool)> obtenerFicha(String jugadorEquipoId) async {
    try {
      final r = await _dio.get('/api/jugador/$jugadorEquipoId/ficha');
      final data = r.data as Map<String, dynamic>;
      return (
        FichaTecnicaDto.fromJson(data['ficha'] as Map<String, dynamic>),
        data['estadisticasAvanzadasActivas'] as bool? ?? false,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return (null, false);
      throw ApiException.fromDio(e);
    }
  }

  /// Devuelve (stats, estadisticasAvanzadasActivas).
  Future<(EstadisticasJugadorDto?, bool)> obtenerEstadisticas(String jugadorEquipoId, {String? participacionId}) async {
    try {
      final r = await _dio.get('/api/jugador/$jugadorEquipoId/estadisticas',
          queryParameters: participacionId != null ? {'participacionId': participacionId} : null);
      final data = r.data as Map<String, dynamic>;
      return (
        EstadisticasJugadorDto.fromJson(data['stats'] as Map<String, dynamic>),
        data['estadisticasAvanzadasActivas'] as bool? ?? false,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return (null, false);
      throw ApiException.fromDio(e);
    }
  }

  Future<List<TablaPosicionesJugadorDto>> obtenerTablas(String jugadorEquipoId, {String? participacionId}) async {
    try {
      final r = await _dio.get('/api/jugador/$jugadorEquipoId/tablas',
          queryParameters: participacionId != null ? {'participacionId': participacionId} : null);
      return (r.data as List<dynamic>)
          .map((e) => TablaPosicionesJugadorDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<List<ComunicadoJugadorDto>> listarComunicados() async {
    try {
      final r = await _dio.get('/api/jugador/comunicados');
      return (r.data as List<dynamic>)
          .map((e) => ComunicadoJugadorDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<bool> marcarComunicadoLeido(String notificacionId) async {
    try {
      await _dio.post('/api/jugador/comunicados/$notificacionId/leido');
      return true;
    } on DioException {
      return false;
    }
  }

  Future<JugadorPerfilDto> obtenerPerfil() async {
    try {
      final r = await _dio.get('/api/jugador/perfil');
      return JugadorPerfilDto.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }

  Future<void> actualizarPerfil({required String nombre, required String apellido, String? telefono}) async {
    try {
      await _dio.put('/api/jugador/perfil', data: {
        'nombre':   nombre,
        'apellido': apellido,
        'telefono': telefono,
      });
    } on DioException catch (e) { throw ApiException.fromDio(e); }
  }
}
