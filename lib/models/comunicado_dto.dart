// ─── Enums ───────────────────────────────────────────────────────────────────

const _kRoles = [
  (valor: 2, label: 'Administrador'),
  (valor: 3, label: 'Staff'),
  (valor: 4, label: 'Árbitro'),
  (valor: 5, label: 'Manager'),
  (valor: 6, label: 'Jugador'),
  (valor: 8, label: 'Patrocinador'),
];
List<({int valor, String label})> get rolesDisponibles => _kRoles;

// ─── Opciones de audiencia ────────────────────────────────────────────────────

class TemporadaOpcion {
  final String id;
  final String etiqueta;
  const TemporadaOpcion({required this.id, required this.etiqueta});

  factory TemporadaOpcion.fromJson(Map<String, dynamic> j) =>
      TemporadaOpcion(id: j['id'].toString(), etiqueta: j['etiqueta'] as String? ?? '');
}

class EquipoOpcionC {
  final String id;
  final String nombre;
  const EquipoOpcionC({required this.id, required this.nombre});

  factory EquipoOpcionC.fromJson(Map<String, dynamic> j) =>
      EquipoOpcionC(id: j['id'].toString(), nombre: j['nombre'] as String? ?? '');
}

// ─── DTO principal ───────────────────────────────────────────────────────────

class ComunicadoDto {
  final String   id;
  final String   titulo;
  final String   cuerpo;
  final int      audienciaValor;
  final String   audienciaLabel;
  final String?  audienciaRolLabel;
  final String?  audienciaTemporadaNombre;
  final String?  audienciaEquipoNombre;
  final String?  filtroJugadoresLabel;
  final int      totalDestinatarios;
  final DateTime creadoEn;
  final String?  creadoPorNombre;

  const ComunicadoDto({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.audienciaValor,
    required this.audienciaLabel,
    this.audienciaRolLabel,
    this.audienciaTemporadaNombre,
    this.audienciaEquipoNombre,
    this.filtroJugadoresLabel,
    required this.totalDestinatarios,
    required this.creadoEn,
    this.creadoPorNombre,
  });

  String get audienciaResumen {
    final buf = StringBuffer(audienciaLabel);
    if (audienciaRolLabel != null)          buf.write(' — $audienciaRolLabel');
    if (audienciaTemporadaNombre != null)   buf.write(' — $audienciaTemporadaNombre');
    if (audienciaEquipoNombre != null)      buf.write(' — $audienciaEquipoNombre');
    if (filtroJugadoresLabel != null)       buf.write(' (${filtroJugadoresLabel!})');
    return buf.toString();
  }

  String get fechaFormateada {
    final d = creadoEn.toLocal();
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}  '
        '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }

  factory ComunicadoDto.fromJson(Map<String, dynamic> j) => ComunicadoDto(
        id:                       j['id'].toString(),
        titulo:                   j['titulo']              as String? ?? '',
        cuerpo:                   j['cuerpo']              as String? ?? '',
        audienciaValor:           j['audiencia']           as int? ?? 1,
        audienciaLabel:           j['audienciaLabel']      as String? ?? '',
        audienciaRolLabel:        j['audienciaRolLabel']   as String?,
        audienciaTemporadaNombre: j['audienciaTemporadaNombre'] as String?,
        audienciaEquipoNombre:    j['audienciaEquipoNombre']    as String?,
        filtroJugadoresLabel:     j['filtroJugadoresLabel']     as String?,
        totalDestinatarios:       j['totalDestinatarios']  as int? ?? 0,
        creadoEn:                 DateTime.parse(j['creadoEn'] as String),
        creadoPorNombre:          j['creadoPorNombre']     as String?,
      );
}
