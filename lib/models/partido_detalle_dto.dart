import '../shared/enums/estado_partido.dart';

class CanchaSimpleDto {
  final String id;
  final String nombre;
  const CanchaSimpleDto(this.id, this.nombre);
  factory CanchaSimpleDto.fromJson(Map<String, dynamic> j) =>
      CanchaSimpleDto(j['id'].toString(), j['nombre'] as String? ?? '');
}

class ArbitroSimpleDto {
  final String id;
  final String nombre;
  const ArbitroSimpleDto(this.id, this.nombre);
  factory ArbitroSimpleDto.fromJson(Map<String, dynamic> j) =>
      ArbitroSimpleDto(j['id'].toString(), j['nombreCompleto'] as String? ?? '');
}

class PartidoPreInicioDto {
  final String?              arbitroActualId;
  final String?              canchaNombre;
  final DateTime             fechaHora;
  final int                  jugadoresLocalActivos;
  final String               equipoLocalNombre;
  final int                  jugadoresVisitanteActivos;
  final String               equipoVisitanteNombre;
  final int                  jugadoresEnCampo;
  final double?              cuotaMonto;
  final bool                 pagoEquipoLocal;
  final bool                 pagoEquipoVisitante;
  final List<ArbitroSimpleDto> arbitros;

  const PartidoPreInicioDto({
    required this.arbitroActualId,
    required this.canchaNombre,
    required this.fechaHora,
    required this.jugadoresLocalActivos,
    required this.equipoLocalNombre,
    required this.jugadoresVisitanteActivos,
    required this.equipoVisitanteNombre,
    required this.jugadoresEnCampo,
    required this.cuotaMonto,
    required this.pagoEquipoLocal,
    required this.pagoEquipoVisitante,
    required this.arbitros,
  });

  factory PartidoPreInicioDto.fromJson(Map<String, dynamic> j) =>
      PartidoPreInicioDto(
        arbitroActualId:          j['arbitroId']?.toString(),
        canchaNombre:             j['canchaNombre']              as String?,
        fechaHora:                DateTime.parse(j['fechaHora'] as String).toLocal(),
        jugadoresLocalActivos:    j['jugadoresLocalActivos']     as int? ?? 0,
        equipoLocalNombre:        j['equipoLocalNombre']         as String? ?? '',
        jugadoresVisitanteActivos:j['jugadoresVisitanteActivos'] as int? ?? 0,
        equipoVisitanteNombre:    j['equipoVisitanteNombre']     as String? ?? '',
        jugadoresEnCampo:         j['jugadoresEnCampo']          as int? ?? 7,
        cuotaMonto:               (j['cuotaMonto'] as num?)?.toDouble(),
        pagoEquipoLocal:          j['pagoEquipoLocal']           as bool? ?? false,
        pagoEquipoVisitante:      j['pagoEquipoVisitante']       as bool? ?? false,
        arbitros:                 (j['arbitros'] as List? ?? [])
            .map((e) => ArbitroSimpleDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PartidoDetalleDto {
  final String         id;
  final String         jornadaId;
  final String         jornadaNombre;
  final String         faseId;
  final String         faseNombre;
  final String         ligaNombre;
  final String         temporadaNombre;
  final String         equipoLocalId;
  final String         equipoLocalNombre;
  final String?        equipoLocalColor;
  final String         equipoVisitanteId;
  final String         equipoVisitanteNombre;
  final String?        equipoVisitanteColor;
  final String?        canchaId;
  final String?        canchaNombre;
  final String?        arbitroId;
  final String?        arbitroNombre;
  final DateTime       fechaHora;
  final EstadoPartido  estado;
  final String         estadoLabel;
  final int            golesLocal;
  final int            golesVisitante;
  final bool           tuvoProrroga;
  final bool           tuvoPenales;
  final int?           golesLocalPenales;
  final int?           golesVisitantePenales;
  final String         resultadoTexto;
  final bool           resultadoBloqueado;
  final double?        cuotaMonto;
  final bool           pagoEquipoLocal;
  final bool           pagoEquipoVisitante;

  bool get tieneArbitro => arbitroId != null && arbitroId!.isNotEmpty;

  const PartidoDetalleDto({
    required this.id,
    required this.jornadaId,
    required this.jornadaNombre,
    required this.faseId,
    required this.faseNombre,
    required this.ligaNombre,
    required this.temporadaNombre,
    required this.equipoLocalId,
    required this.equipoLocalNombre,
    this.equipoLocalColor,
    required this.equipoVisitanteId,
    required this.equipoVisitanteNombre,
    this.equipoVisitanteColor,
    this.canchaId,
    this.canchaNombre,
    this.arbitroId,
    this.arbitroNombre,
    required this.fechaHora,
    required this.estado,
    required this.estadoLabel,
    required this.golesLocal,
    required this.golesVisitante,
    required this.tuvoProrroga,
    required this.tuvoPenales,
    this.golesLocalPenales,
    this.golesVisitantePenales,
    required this.resultadoTexto,
    required this.resultadoBloqueado,
    this.cuotaMonto,
    required this.pagoEquipoLocal,
    required this.pagoEquipoVisitante,
  });

  static EstadoPartido _parseEstado(dynamic v) => switch (v as int? ?? 0) {
        2 => EstadoPartido.enCurso,
        3 => EstadoPartido.terminado,
        4 => EstadoPartido.suspendido,
        5 => EstadoPartido.cancelado,
        _ => EstadoPartido.programado,
      };

  factory PartidoDetalleDto.fromJson(Map<String, dynamic> j) => PartidoDetalleDto(
        id:                    j['id']                    as String,
        jornadaId:             j['jornadaId']?.toString() ?? '',
        jornadaNombre:         j['jornadaNombre']         as String? ?? '',
        faseId:                j['faseId']?.toString()    ?? '',
        faseNombre:            j['faseNombre']            as String? ?? '',
        ligaNombre:            j['ligaNombre']            as String? ?? '',
        temporadaNombre:       j['temporadaNombre']       as String? ?? '',
        equipoLocalId:         j['equipoLocalId']?.toString() ?? '',
        equipoLocalNombre:     j['equipoLocalNombre']     as String? ?? '',
        equipoLocalColor:      j['equipoLocalColor']      as String?,
        equipoVisitanteId:     j['equipoVisitanteId']?.toString() ?? '',
        equipoVisitanteNombre: j['equipoVisitanteNombre'] as String? ?? '',
        equipoVisitanteColor:  j['equipoVisitanteColor']  as String?,
        canchaId:              j['canchaId']?.toString(),
        canchaNombre:          j['canchaNombre']          as String?,
        arbitroId:             j['arbitroId']?.toString(),
        arbitroNombre:         j['arbitroNombre']         as String?,
        fechaHora:             DateTime.parse(j['fechaHora'] as String).toLocal(),
        estado:                _parseEstado(j['estado']),
        estadoLabel:           j['estadoLabel']           as String? ?? '',
        golesLocal:            j['golesLocal']            as int? ?? 0,
        golesVisitante:        j['golesVisitante']        as int? ?? 0,
        tuvoProrroga:          j['tuvoProrroga']          as bool? ?? false,
        tuvoPenales:           j['tuvoPenales']           as bool? ?? false,
        golesLocalPenales:     j['golesLocalPenales']     as int?,
        golesVisitantePenales: j['golesVisitantePenales'] as int?,
        resultadoTexto:        j['resultadoTexto']        as String? ?? '',
        resultadoBloqueado:    j['resultadoBloqueado']    as bool? ?? false,
        cuotaMonto:            (j['cuotaMonto'] as num?)?.toDouble(),
        pagoEquipoLocal:       j['pagoEquipoLocal']       as bool? ?? false,
        pagoEquipoVisitante:   j['pagoEquipoVisitante']   as bool? ?? false,
      );
}
