import 'package:flutter/material.dart';

// ─── Enum ────────────────────────────────────────────────────────────────────

enum EstadoReserva { pendiente, confirmada, cancelada, completada, noShow }

extension EstadoReservaExt on EstadoReserva {
  String get label => switch (this) {
    EstadoReserva.pendiente  => 'Pendiente',
    EstadoReserva.confirmada => 'Confirmada',
    EstadoReserva.cancelada  => 'Cancelada',
    EstadoReserva.completada => 'Completada',
    EstadoReserva.noShow     => 'No Show',
  };

  int get valor => switch (this) {
    EstadoReserva.pendiente  => 1,
    EstadoReserva.confirmada => 2,
    EstadoReserva.cancelada  => 3,
    EstadoReserva.completada => 4,
    EstadoReserva.noShow     => 5,
  };

  Color get color => switch (this) {
    EstadoReserva.pendiente  => const Color(0xFFB45309),
    EstadoReserva.confirmada => const Color(0xFF16A34A),
    EstadoReserva.cancelada  => const Color(0xFFDC2626),
    EstadoReserva.completada => const Color(0xFF475569),
    EstadoReserva.noShow     => const Color(0xFF9333EA),
  };

  Color get bg => switch (this) {
    EstadoReserva.pendiente  => const Color(0xFFFEF3C7),
    EstadoReserva.confirmada => const Color(0xFFDCFCE7),
    EstadoReserva.cancelada  => const Color(0xFFFEE2E2),
    EstadoReserva.completada => const Color(0xFFF1F5F9),
    EstadoReserva.noShow     => const Color(0xFFF3E8FF),
  };
}

EstadoReserva _parseEstado(dynamic v) {
  if (v is int) {
    return switch (v) {
      2 => EstadoReserva.confirmada,
      3 => EstadoReserva.cancelada,
      4 => EstadoReserva.completada,
      5 => EstadoReserva.noShow,
      _ => EstadoReserva.pendiente,
    };
  }
  return EstadoReserva.pendiente;
}

// ─── Helpers para dropdowns ──────────────────────────────────────────────────

class CanchaSimple {
  final String  id;
  final String  nombre;
  final String? clave;

  const CanchaSimple({required this.id, required this.nombre, this.clave});

  String get display => clave != null ? '$clave — $nombre' : nombre;

  factory CanchaSimple.fromJson(Map<String, dynamic> j) => CanchaSimple(
        id:     j['id'].toString(),
        nombre: j['nombre'] as String? ?? '',
        clave:  j['claveInterna'] as String?,
      );
}

class EquipoSimpleR {
  final String id;
  final String nombre;

  const EquipoSimpleR({required this.id, required this.nombre});

  factory EquipoSimpleR.fromJson(Map<String, dynamic> j) => EquipoSimpleR(
        id:     j['id'].toString(),
        nombre: j['nombre'] as String? ?? '',
      );
}

// ─── DTO principal ───────────────────────────────────────────────────────────

class ReservaDto {
  final String        id;
  final String        canchaId;
  final String        nombreCancha;
  final String?       claveCancha;
  final String        fecha;        // "yyyy-MM-dd"
  final String        horaInicio;   // "HH:mm:ss"
  final String        horaFin;      // "HH:mm:ss"
  final int           duracionMin;
  final String        nombreCliente;
  final String?       telefonoCliente;
  final String?       emailCliente;
  final String?       equipoId;
  final String?       nombreEquipo;
  final double        total;
  final double?       deposito;
  final bool          depositoPagado;
  final bool          totalPagado;
  final int?          metodoPago;
  final String?       metodoPagoLabel;
  final EstadoReserva estado;
  final String?       notaCliente;
  final String?       notaInterna;
  final String?       motivoCancel;

  String get horaInicioDisplay => horaInicio.length >= 5 ? horaInicio.substring(0, 5) : horaInicio;
  String get horaFinDisplay    => horaFin.length >= 5 ? horaFin.substring(0, 5) : horaFin;
  int get horaInicioNum        => int.tryParse(horaInicio.split(':').first) ?? 0;
  int get duracionHoras        => (duracionMin / 60).round().clamp(1, 24);

  const ReservaDto({
    required this.id,
    required this.canchaId,
    required this.nombreCancha,
    this.claveCancha,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.duracionMin,
    required this.nombreCliente,
    this.telefonoCliente,
    this.emailCliente,
    this.equipoId,
    this.nombreEquipo,
    required this.total,
    this.deposito,
    required this.depositoPagado,
    required this.totalPagado,
    this.metodoPago,
    this.metodoPagoLabel,
    required this.estado,
    this.notaCliente,
    this.notaInterna,
    this.motivoCancel,
  });

  factory ReservaDto.fromJson(Map<String, dynamic> j) => ReservaDto(
        id:              j['id'].toString(),
        canchaId:        j['canchaId'].toString(),
        nombreCancha:    j['nombreCancha']    as String? ?? '',
        claveCancha:     j['claveCancha']     as String?,
        fecha:           j['fecha']           as String? ?? '',
        horaInicio:      j['horaInicio']      as String? ?? '',
        horaFin:         j['horaFin']         as String? ?? '',
        duracionMin:     j['duracionMin']     as int? ?? 60,
        nombreCliente:   j['nombreCliente']   as String? ?? '',
        telefonoCliente: j['telefonoCliente'] as String?,
        emailCliente:    j['emailCliente']    as String?,
        equipoId:        j['equipoId']?.toString(),
        nombreEquipo:    j['nombreEquipo']    as String?,
        total:           (j['total']          as num? ?? 0).toDouble(),
        deposito:        (j['deposito']       as num?)?.toDouble(),
        depositoPagado:  j['depositoPagado']  as bool? ?? false,
        totalPagado:     j['totalPagado']     as bool? ?? false,
        metodoPago:      j['metodoPago']      as int?,
        metodoPagoLabel: j['metodoPagoLabel'] as String?,
        estado:          _parseEstado(j['estado']),
        notaCliente:     j['notaCliente']     as String?,
        notaInterna:     j['notaInterna']     as String?,
        motivoCancel:    j['motivoCancel']    as String?,
      );
}
