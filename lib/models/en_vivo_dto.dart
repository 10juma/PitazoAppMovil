enum FasePartido { primerTiempo, descanso, segundoTiempo, tiempoExtra, penales, terminado }

class JugadorEnVivoDto {
  final String  id;
  final String  nombre;
  final String  apellido;
  final int?    dorsal;

  const JugadorEnVivoDto({
    required this.id,
    required this.nombre,
    required this.apellido,
    this.dorsal,
  });

  factory JugadorEnVivoDto.fromJson(Map<String, dynamic> j) => JugadorEnVivoDto(
        id:       j['id']       as String,
        nombre:   j['nombre']   as String,
        apellido: j['apellido'] as String,
        dorsal:   j['dorsal']   as int?,
      );

  String get nombreCorto => '${nombre[0]}. $apellido';
  String get nombreCompleto => '$nombre $apellido';
  String get etiqueta => dorsal != null ? '#$dorsal $nombreCorto' : nombreCorto;
}

class EventoDto {
  final String  id;
  final int     tipo;
  final String  tipoLabel;
  final int     minuto;
  final String? jugadorNombre;
  final String? equipoNombre;
  final String? nota;

  const EventoDto({
    required this.id,
    required this.tipo,
    required this.tipoLabel,
    required this.minuto,
    this.jugadorNombre,
    this.equipoNombre,
    this.nota,
  });

  factory EventoDto.fromJson(Map<String, dynamic> j) => EventoDto(
        id:            j['id']            as String,
        tipo:          j['tipo']          as int,
        tipoLabel:     j['tipoLabel']     as String,
        minuto:        j['minuto']        as int,
        jugadorNombre: j['jugadorNombre'] as String?,
        equipoNombre:  j['equipoNombre']  as String?,
        nota:          j['nota']          as String?,
      );

  bool get esGol       => tipo == 1 || tipo == 2;
  bool get esPropia    => tipo == 2;
  bool get esAmarilla  => tipo == 3;
  bool get esRoja      => tipo == 4;
  bool get esAzul      => tipo == 5;
  bool get esTarjeta   => tipo >= 3 && tipo <= 5;
}

class EnVivoDto {
  final String  id;
  final String  equipoLocalId;
  final String  equipoLocalNombre;
  final String  equipoVisitanteId;
  final String  equipoVisitanteNombre;
  final int     golesLocal;
  final int     golesVisitante;
  final String? canchaNombre;
  final String? arbitroNombre;
  final String? ligaNombre;
  final String? temporadaNombre;
  final int     duracionTiempoMin;
  final bool    tieneTargetaAzul;
  final List<JugadorEnVivoDto> jugadoresLocal;
  final List<JugadorEnVivoDto> jugadoresVisitante;
  final List<EventoDto>        eventos;

  const EnVivoDto({
    required this.id,
    required this.equipoLocalId,
    required this.equipoLocalNombre,
    required this.equipoVisitanteId,
    required this.equipoVisitanteNombre,
    required this.golesLocal,
    required this.golesVisitante,
    this.canchaNombre,
    this.arbitroNombre,
    this.ligaNombre,
    this.temporadaNombre,
    this.duracionTiempoMin = 25,
    this.tieneTargetaAzul  = false,
    required this.jugadoresLocal,
    required this.jugadoresVisitante,
    required this.eventos,
  });

  factory EnVivoDto.fromJson(Map<String, dynamic> j) => EnVivoDto(
        id:                    j['id']                    as String,
        equipoLocalId:         j['equipoLocalId']         as String,
        equipoLocalNombre:     j['equipoLocalNombre']     as String,
        equipoVisitanteId:     j['equipoVisitanteId']     as String,
        equipoVisitanteNombre: j['equipoVisitanteNombre'] as String,
        golesLocal:            j['golesLocal']            as int,
        golesVisitante:        j['golesVisitante']        as int,
        canchaNombre:          j['canchaNombre']          as String?,
        arbitroNombre:         j['arbitroNombre']         as String?,
        ligaNombre:            j['ligaNombre']            as String?,
        temporadaNombre:       j['temporadaNombre']       as String?,
        duracionTiempoMin:     j['duracionTiempoMin']     as int? ?? 25,
        tieneTargetaAzul:      j['tieneTargetaAzul']      as bool? ?? false,
        jugadoresLocal: (j['jugadoresLocal'] as List)
            .map((e) => JugadorEnVivoDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        jugadoresVisitante: (j['jugadoresVisitante'] as List)
            .map((e) => JugadorEnVivoDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        eventos: (j['eventos'] as List)
            .map((e) => EventoDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get minutoActual {
    if (eventos.isEmpty) return 0;
    final relevant = eventos.where((e) => e.minuto > 0);
    return relevant.isEmpty ? 0 : relevant.map((e) => e.minuto).reduce((a, b) => a > b ? a : b);
  }

  FasePartido get fase {
    const rank = {11: 1, 15: 2, 16: 3, 13: 4, 14: 5, 12: 6};

    // Si hay eventos de tanda de penales y el partido no terminó → penales.
    // Esto es más confiable que depender del evento TiempoExtraFin, que puede
    // no haberse registrado si la sesión web falló silenciosamente.
    const penalTipos = {8, 9, 10};
    final tienePartidoFin = eventos.any((e) => e.tipo == 12);
    if (!tienePartidoFin && eventos.any((e) => penalTipos.contains(e.tipo))) {
      return FasePartido.penales;
    }

    final controlEvs = eventos.where((e) => rank.containsKey(e.tipo)).toList();
    if (controlEvs.isEmpty) return FasePartido.primerTiempo;
    controlEvs.sort((a, b) => (rank[b.tipo] ?? 0).compareTo(rank[a.tipo] ?? 0));
    return switch (controlEvs.first.tipo) {
      11 => FasePartido.primerTiempo,
      15 => FasePartido.descanso,
      16 => FasePartido.segundoTiempo,
      13 => FasePartido.tiempoExtra,
      14 => FasePartido.penales,
      12 => FasePartido.terminado,
      _  => FasePartido.primerTiempo,
    };
  }
}
