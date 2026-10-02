import '../shared/enums/estado_equipo.dart';
import '../shared/enums/estado_jugador.dart';

// ─── Manager ─────────────────────────────────────────────────────────────────

class ManagerEquipoDto {
  final String  id;
  final String  nombre;
  final String  apellido;
  final String  telefono;
  final String? email;
  final String? fotoUrl;
  final bool    activo;
  final bool    tieneAcceso;

  String get nombreCompleto => '$nombre $apellido'.trim();

  /// URL wa.me con mensaje opcional
  String whatsAppUrl([String? mensaje]) {
    final tel = telefono.replaceAll(RegExp(r'[+\s\-]'), '');
    if (mensaje == null) return 'https://wa.me/$tel';
    final enc = Uri.encodeComponent(mensaje);
    return 'https://wa.me/$tel?text=$enc';
  }

  const ManagerEquipoDto({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    this.email,
    this.fotoUrl,
    required this.activo,
    required this.tieneAcceso,
  });

  factory ManagerEquipoDto.fromJson(Map<String, dynamic> j) => ManagerEquipoDto(
        id:          j['id'].toString(),
        nombre:      j['nombre']      as String? ?? '',
        apellido:    j['apellido']    as String? ?? '',
        telefono:    j['telefono']    as String? ?? '',
        email:       j['email']       as String?,
        fotoUrl:     j['fotoUrl']     as String?,
        activo:      j['activo']      as bool? ?? true,
        tieneAcceso: j['tieneAcceso'] as bool? ?? false,
      );
}

// ─── Jugador ─────────────────────────────────────────────────────────────────

class JugadorEquipoDto {
  final String         id;
  final String         equipoId;
  final String         nombre;
  final String         apellido;
  final String?        fechaNacimiento;
  final int?           dorsalBase;
  final String?        posicionLabel;
  final String?        fotoUrl;
  final String?        identificadorUnico;
  final String?        email;
  final bool           tieneAcceso;
  final EstadoJugador  estado;
  final String         estadoLabel;
  final bool           tieneSancionActiva;

  String get nombreCompleto => '$nombre $apellido'.trim();

  int? get edad {
    if (fechaNacimiento == null) return null;
    try {
      final fn = DateTime.parse(fechaNacimiento!);
      final hoy = DateTime.now();
      int anios = hoy.year - fn.year;
      if (hoy.month < fn.month || (hoy.month == fn.month && hoy.day < fn.day)) anios--;
      return anios;
    } catch (_) { return null; }
  }

  const JugadorEquipoDto({
    required this.id,
    required this.equipoId,
    required this.nombre,
    required this.apellido,
    this.fechaNacimiento,
    this.dorsalBase,
    this.posicionLabel,
    this.fotoUrl,
    this.identificadorUnico,
    this.email,
    required this.tieneAcceso,
    required this.estado,
    required this.estadoLabel,
    required this.tieneSancionActiva,
  });

  static EstadoJugador _parseEstado(dynamic v) {
    if (v is int) {
      return switch (v) {
        2 => EstadoJugador.inactivo,
        3 => EstadoJugador.suspendido,
        4 => EstadoJugador.lesionado,
        _ => EstadoJugador.activo,
      };
    }
    final s = v?.toString().toLowerCase() ?? '';
    return switch (s) {
      'suspendido' => EstadoJugador.suspendido,
      'lesionado'  => EstadoJugador.lesionado,
      'inactivo'   => EstadoJugador.inactivo,
      _            => EstadoJugador.activo,
    };
  }

  factory JugadorEquipoDto.fromJson(Map<String, dynamic> j) => JugadorEquipoDto(
        id:                 j['id'].toString(),
        equipoId:           j['equipoId']?.toString() ?? '',
        nombre:             j['nombre']             as String? ?? '',
        apellido:           j['apellido']           as String? ?? '',
        fechaNacimiento:    j['fechaNacimiento']    as String?,
        dorsalBase:         j['dorsalBase']         as int?,
        posicionLabel:      j['posicionLabel']      as String?,
        fotoUrl:            j['fotoUrl']            as String?,
        identificadorUnico: j['identificadorUnico'] as String?,
        email:              j['email']              as String?,
        tieneAcceso:        j['tieneAcceso']        as bool? ?? false,
        estado:             _parseEstado(j['estado']),
        estadoLabel:        j['estadoLabel']        as String? ?? '',
        tieneSancionActiva: j['tieneSancionActiva'] as bool? ?? false,
      );
}

// ─── Equipo ───────────────────────────────────────────────────────────────────

class EquipoDto {
  final String              id;
  final String              nombre;
  final String?             logoUrl;
  final String?             colorPrincipal;
  final String?             colorSecundario;
  final String?             fechaFundacion;
  final String              tipoLabel;
  final EstadoEquipo        estado;
  final String              estadoLabel;
  final int                 totalJugadores;
  final int                 totalActivos;
  final ManagerEquipoDto?   manager;
  final List<JugadorEquipoDto> jugadores;

  const EquipoDto({
    required this.id,
    required this.nombre,
    this.logoUrl,
    this.colorPrincipal,
    this.colorSecundario,
    this.fechaFundacion,
    required this.tipoLabel,
    required this.estado,
    required this.estadoLabel,
    required this.totalJugadores,
    required this.totalActivos,
    this.manager,
    this.jugadores = const [],
  });

  static EstadoEquipo _parseEstado(dynamic v) {
    if (v is int) {
      return switch (v) {
        2 => EstadoEquipo.inactivo,
        3 => EstadoEquipo.disuelto,
        _ => EstadoEquipo.activo,
      };
    }
    final s = v?.toString().toLowerCase() ?? '';
    return switch (s) {
      'inactivo' => EstadoEquipo.inactivo,
      'disuelto' => EstadoEquipo.disuelto,
      _          => EstadoEquipo.activo,
    };
  }

  factory EquipoDto.fromJson(Map<String, dynamic> j) => EquipoDto(
        id:              j['id'].toString(),
        nombre:          j['nombre']          as String? ?? '',
        logoUrl:         j['logoUrl']         as String?,
        colorPrincipal:  j['colorPrincipal']  as String?,
        colorSecundario: j['colorSecundario'] as String?,
        fechaFundacion:  j['fechaFundacion']  as String?,
        tipoLabel:       j['tipoLabel']       as String? ?? '',
        estado:          _parseEstado(j['estado']),
        estadoLabel:     j['estadoLabel']     as String? ?? '',
        totalJugadores:  j['totalJugadores']  as int? ?? 0,
        totalActivos:    j['totalActivos']    as int? ?? 0,
        manager: j['manager'] == null
            ? null
            : ManagerEquipoDto.fromJson(j['manager'] as Map<String, dynamic>),
        jugadores: (j['jugadores'] as List? ?? [])
            .map((e) => JugadorEquipoDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
