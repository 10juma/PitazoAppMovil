import '../shared/enums/estado_partido.dart';

class PartidoResumenDto {
  final String         id;
  final String         ligaId;
  final String         ligaNombre;
  final String         temporadaId;
  final String         temporadaNombre;
  final String         faseNombre;
  final String         jornadaNombre;
  final String         equipoLocalNombre;
  final String         equipoVisitanteNombre;
  final String?        canchaNombre;
  final DateTime       fechaHora;
  final EstadoPartido  estado;
  final String         estadoLabel;
  final int            golesLocal;
  final int            golesVisitante;
  final String         resultadoTexto;

  const PartidoResumenDto({
    required this.id,
    required this.ligaId,
    required this.ligaNombre,
    required this.temporadaId,
    required this.temporadaNombre,
    required this.faseNombre,
    required this.jornadaNombre,
    required this.equipoLocalNombre,
    required this.equipoVisitanteNombre,
    this.canchaNombre,
    required this.fechaHora,
    required this.estado,
    required this.estadoLabel,
    required this.golesLocal,
    required this.golesVisitante,
    required this.resultadoTexto,
  });

  // El API serializa EstadoPartido como entero: Programado=1, EnCurso=2, Terminado=3, Suspendido=4, Cancelado=5
  static EstadoPartido _parseEstado(dynamic v) => switch (v as int? ?? 0) {
        2 => EstadoPartido.enCurso,
        3 => EstadoPartido.terminado,
        4 => EstadoPartido.suspendido,
        5 => EstadoPartido.cancelado,
        _ => EstadoPartido.programado,
      };

  factory PartidoResumenDto.fromJson(Map<String, dynamic> j) => PartidoResumenDto(
        id:                    j['id']                    as String,
        ligaId:                j['ligaId']?.toString()    ?? '',
        ligaNombre:            j['ligaNombre']            as String? ?? '',
        temporadaId:           j['temporadaId']?.toString() ?? '',
        temporadaNombre:       j['temporadaNombre']       as String? ?? '',
        faseNombre:            j['faseNombre']            as String? ?? '',
        jornadaNombre:         j['jornadaNombre']         as String? ?? '',
        equipoLocalNombre:     j['equipoLocalNombre']     as String? ?? '',
        equipoVisitanteNombre: j['equipoVisitanteNombre'] as String? ?? '',
        canchaNombre:          j['canchaNombre']          as String?,
        fechaHora:             DateTime.parse(j['fechaHora'] as String).toLocal(),
        estado:                _parseEstado(j['estado']),
        estadoLabel:           j['estadoLabel']           as String? ?? '',
        golesLocal:            j['golesLocal']            as int? ?? 0,
        golesVisitante:        j['golesVisitante']        as int? ?? 0,
        resultadoTexto:        j['resultadoTexto']        as String? ?? '',
      );

  String get fechaFormateada {
    final d = fechaHora;
    final meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${d.day} ${meses[d.month - 1]} · ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }
}
