import 'reserva_dto.dart';

class PartidoEnVivoDto {
  final String id;
  final String equipoLocalNombre;
  final String equipoVisitanteNombre;
  final String? canchaNombre;
  final int golesLocal;
  final int golesVisitante;
  final DateTime fechaHora;

  const PartidoEnVivoDto({
    required this.id,
    required this.equipoLocalNombre,
    required this.equipoVisitanteNombre,
    this.canchaNombre,
    required this.golesLocal,
    required this.golesVisitante,
    required this.fechaHora,
  });

  factory PartidoEnVivoDto.fromJson(Map<String, dynamic> j) => PartidoEnVivoDto(
        id:                   j['id']                   as String,
        equipoLocalNombre:    j['equipoLocalNombre']    as String,
        equipoVisitanteNombre:j['equipoVisitanteNombre']as String,
        canchaNombre:         j['canchaNombre']         as String?,
        golesLocal:           j['golesLocal']           as int,
        golesVisitante:       j['golesVisitante']       as int,
        fechaHora:            DateTime.parse(j['fechaHora'] as String).toLocal(),
      );

  int get minuto => DateTime.now().difference(fechaHora).inMinutes.clamp(0, 120);
}

class PartidoProximoDto {
  final String id;
  final String equipoLocalNombre;
  final String equipoVisitanteNombre;
  final String? canchaNombre;
  final String ligaNombre;
  final DateTime fechaHora;

  const PartidoProximoDto({
    required this.id,
    required this.equipoLocalNombre,
    required this.equipoVisitanteNombre,
    this.canchaNombre,
    required this.ligaNombre,
    required this.fechaHora,
  });

  factory PartidoProximoDto.fromJson(Map<String, dynamic> j) => PartidoProximoDto(
        id:                    j['id']                   as String,
        equipoLocalNombre:     j['equipoLocalNombre']    as String,
        equipoVisitanteNombre: j['equipoVisitanteNombre']as String,
        canchaNombre:          j['canchaNombre']         as String?,
        ligaNombre:            j['ligaNombre']           as String,
        fechaHora:             DateTime.parse(j['fechaHora'] as String).toLocal(),
      );

  String get horaFormateada {
    final h = fechaHora;
    return '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';
  }
}

class StaffDashboardData {
  final List<PartidoEnVivoDto>  partidosEnVivo;
  final List<PartidoProximoDto> proximosPartidos;
  final List<ReservaDto>        reservasHoy;
  final int  totalPartidos;
  final int  enCurso;
  final int  porIniciar;
  final int  terminados;
  final int  totalCanchas;
  final int  totalLigas;
  final int  totalEquipos;
  final int  totalJugadores;
  final bool reservasCanchasActiva;

  const StaffDashboardData({
    required this.partidosEnVivo,
    required this.proximosPartidos,
    required this.reservasHoy,
    required this.totalPartidos,
    required this.enCurso,
    required this.porIniciar,
    required this.terminados,
    required this.totalCanchas,
    required this.totalLigas,
    required this.totalEquipos,
    required this.totalJugadores,
    required this.reservasCanchasActiva,
  });

  factory StaffDashboardData.fromJson(Map<String, dynamic> j) => StaffDashboardData(
        partidosEnVivo: (j['partidosEnVivo'] as List)
            .map((e) => PartidoEnVivoDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        proximosPartidos: (j['proximosPartidos'] as List)
            .map((e) => PartidoProximoDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        reservasHoy: (j['reservasHoy'] as List? ?? [])
            .map((e) => ReservaDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalPartidos:         j['totalPartidos']         as int? ?? 0,
        enCurso:               j['enCurso']               as int? ?? 0,
        porIniciar:            j['porIniciar']            as int? ?? 0,
        terminados:            j['terminados']            as int? ?? 0,
        totalCanchas:          j['totalCanchas']          as int? ?? 0,
        totalLigas:            j['totalLigas']            as int? ?? 0,
        totalEquipos:          j['totalEquipos']          as int? ?? 0,
        totalJugadores:        j['totalJugadores']        as int? ?? 0,
        reservasCanchasActiva: j['reservasCanchasActiva'] as bool? ?? false,
      );
}
