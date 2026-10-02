// ── CanchaDto ─────────────────────────────────────────────────────────────────

class CanchaDto {
  final String  id;
  final String  nombre;
  final String? claveInterna;
  final String? descripcion;
  final String? fotoPortadaUrl;
  final String  superficieDisplay;
  final bool    tieneIluminacion;
  final double? precioBaseHora;
  final String  estadoCancha;      // "Activa" | "Inactiva" | "EnMantenimiento"
  final bool    disponibleReservas;
  final bool    disponibleLigas;
  final bool    visiblePublico;
  final String  horarioResumen;

  const CanchaDto({
    required this.id,
    required this.nombre,
    this.claveInterna,
    this.descripcion,
    this.fotoPortadaUrl,
    required this.superficieDisplay,
    required this.tieneIluminacion,
    this.precioBaseHora,
    required this.estadoCancha,
    required this.disponibleReservas,
    required this.disponibleLigas,
    required this.visiblePublico,
    required this.horarioResumen,
  });

  factory CanchaDto.fromJson(Map<String, dynamic> j) => CanchaDto(
        id:                j['id']               as String,
        nombre:            j['nombre']            as String,
        claveInterna:      j['claveInterna']      as String?,
        descripcion:       j['descripcion']       as String?,
        fotoPortadaUrl:    j['fotoPortadaUrl']    as String?,
        superficieDisplay: j['superficieDisplay'] as String? ?? '',
        tieneIluminacion:  j['tieneIluminacion']  as bool?   ?? false,
        precioBaseHora:    (j['precioBaseHora'] as num?)?.toDouble(),
        estadoCancha:      j['estadoCancha']?.toString() ?? 'Activa',
        disponibleReservas: j['disponibleReservas'] as bool? ?? false,
        disponibleLigas:    j['disponibleLigas']    as bool? ?? false,
        visiblePublico:     j['visiblePublico']     as bool? ?? false,
        horarioResumen:     j['horarioResumen']     as String? ?? '',
      );

  String get estadoLabel => switch (estadoCancha) {
    'Activa'          => 'Activa',
    'Inactiva'        => 'Inactiva',
    'EnMantenimiento' => 'En mantenimiento',
    _ => estadoCancha,
  };

  bool get esActiva          => estadoCancha == 'Activa';
  bool get esInactiva        => estadoCancha == 'Inactiva';
  bool get esEnMantenimiento => estadoCancha == 'EnMantenimiento';
}

// ── RegistroMantenimientoDto ──────────────────────────────────────────────────

class RegistroMantenimientoDto {
  final String   id;
  final String   canchaId;
  final String   categoriaLabel;
  final String   descripcion;
  final double?  costoEstimado;
  final double?  costoReal;
  final String?  proveedor;
  final String?  observacionCierre;
  final String   registradoPorNombre;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final bool     resuelto;

  const RegistroMantenimientoDto({
    required this.id,
    required this.canchaId,
    required this.categoriaLabel,
    required this.descripcion,
    this.costoEstimado,
    this.costoReal,
    this.proveedor,
    this.observacionCierre,
    required this.registradoPorNombre,
    required this.fechaInicio,
    this.fechaFin,
    required this.resuelto,
  });

  factory RegistroMantenimientoDto.fromJson(Map<String, dynamic> j) =>
      RegistroMantenimientoDto(
        id:                  j['id']                  as String,
        canchaId:            j['canchaId']            as String,
        categoriaLabel:      j['categoriaLabel']      as String? ?? '',
        descripcion:         j['descripcion']         as String? ?? '',
        costoEstimado:       (j['costoEstimado']  as num?)?.toDouble(),
        costoReal:           (j['costoReal']       as num?)?.toDouble(),
        proveedor:            j['proveedor']           as String?,
        observacionCierre:    j['observacionCierre']   as String?,
        registradoPorNombre:  j['registradoPorNombre'] as String? ?? '',
        fechaInicio:  DateTime.parse(j['fechaInicio'] as String),
        fechaFin:     j['fechaFin'] != null
                          ? DateTime.parse(j['fechaFin'] as String)
                          : null,
        resuelto:     j['resuelto'] as bool? ?? false,
      );
}

// ── EstadoCanchaStaffDto ──────────────────────────────────────────────────────

class EstadoCanchaStaffDto {
  final String  canchaId;
  final String  nombre;
  final String? clave;

  /// "libre" | "partido" | "reserva" | "mantenimiento"
  final String  estadoActual;

  final String?  eventoActual;
  final String?  eventoActualHasta;
  final String?  proximoEvento;
  final DateTime? proximoEventoHora;

  final RegistroMantenimientoDto? mantenimientoActivo;

  const EstadoCanchaStaffDto({
    required this.canchaId,
    required this.nombre,
    this.clave,
    required this.estadoActual,
    this.eventoActual,
    this.eventoActualHasta,
    this.proximoEvento,
    this.proximoEventoHora,
    this.mantenimientoActivo,
  });

  factory EstadoCanchaStaffDto.fromJson(Map<String, dynamic> j) =>
      EstadoCanchaStaffDto(
        canchaId:          j['canchaId']    as String,
        nombre:            j['nombre']      as String,
        clave:             j['clave']       as String?,
        estadoActual:      j['estadoActual'] as String? ?? 'libre',
        eventoActual:      j['eventoActual']      as String?,
        eventoActualHasta: j['eventoActualHasta'] as String?,
        proximoEvento:     j['proximoEvento']     as String?,
        proximoEventoHora: j['proximoEventoHora'] != null
                               ? DateTime.parse(j['proximoEventoHora'] as String)
                               : null,
        mantenimientoActivo: j['mantenimientoActivo'] != null
            ? RegistroMantenimientoDto.fromJson(
                j['mantenimientoActivo'] as Map<String, dynamic>)
            : null,
      );

  bool get esLibre          => estadoActual == 'libre';
  bool get esPartido        => estadoActual == 'partido';
  bool get esReserva        => estadoActual == 'reserva';
  bool get esMantenimiento  => estadoActual == 'mantenimiento';
}
