class PatrocinadorPortalDto {
  final String  id;
  final String  nombre;
  final String? logoUrl;
  final String? sitioWeb;
  final String? contactoNombre;
  final String? contactoTelefono;
  final String? contactoEmail;
  final String  nivelLabel;
  final double? montoAcuerdo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool    activo;
  final String  estadoLabel;
  final String  tenantNombre;
  final String  tenantSlug;

  PatrocinadorPortalDto({
    required this.id,
    required this.nombre,
    this.logoUrl,
    this.sitioWeb,
    this.contactoNombre,
    this.contactoTelefono,
    this.contactoEmail,
    required this.nivelLabel,
    this.montoAcuerdo,
    this.fechaInicio,
    this.fechaFin,
    required this.activo,
    required this.estadoLabel,
    required this.tenantNombre,
    required this.tenantSlug,
  });

  factory PatrocinadorPortalDto.fromJson(Map<String, dynamic> json) => PatrocinadorPortalDto(
        id:               json['id'] as String,
        nombre:           json['nombre'] as String? ?? '',
        logoUrl:          json['logoUrl'] as String?,
        sitioWeb:         json['sitioWeb'] as String?,
        contactoNombre:   json['contactoNombre'] as String?,
        contactoTelefono: json['contactoTelefono'] as String?,
        contactoEmail:    json['contactoEmail'] as String?,
        nivelLabel:       json['nivelLabel'] as String? ?? '',
        montoAcuerdo:     (json['montoAcuerdo'] as num?)?.toDouble(),
        fechaInicio:      json['fechaInicio'] != null ? DateTime.parse(json['fechaInicio'] as String) : null,
        fechaFin:         json['fechaFin']    != null ? DateTime.parse(json['fechaFin']    as String) : null,
        activo:           json['activo'] as bool? ?? false,
        estadoLabel:      json['estadoLabel'] as String? ?? '',
        tenantNombre:     json['tenantNombre'] as String? ?? '',
        tenantSlug:       json['tenantSlug'] as String? ?? '',
      );
}

class VistaDiariaDto {
  final DateTime fecha;
  final int      vistas;

  VistaDiariaDto({required this.fecha, required this.vistas});

  factory VistaDiariaDto.fromJson(Map<String, dynamic> json) => VistaDiariaDto(
        fecha:  DateTime.parse(json['fecha'] as String),
        vistas: json['vistas'] as int? ?? 0,
      );
}

class MetricasPatrocinadorDto {
  final int hoy;
  final int ultimos7Dias;
  final int ultimos30Dias;
  final int total;
  final List<VistaDiariaDto> serie;

  MetricasPatrocinadorDto({
    required this.hoy,
    required this.ultimos7Dias,
    required this.ultimos30Dias,
    required this.total,
    required this.serie,
  });

  factory MetricasPatrocinadorDto.fromJson(Map<String, dynamic> json) => MetricasPatrocinadorDto(
        hoy:           json['hoy'] as int? ?? 0,
        ultimos7Dias:  json['ultimos7Dias'] as int? ?? 0,
        ultimos30Dias: json['ultimos30Dias'] as int? ?? 0,
        total:         json['total'] as int? ?? 0,
        serie: (json['serie'] as List? ?? [])
            .map((e) => VistaDiariaDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FacturaPatrocinadorDto {
  final String   id;
  final String   concepto;
  final double   monto;
  final bool     pagado;
  final DateTime? pagadoEn;
  final DateTime venceEn;
  final String?  notas;
  final DateTime creadoEn;
  final String   estadoLabel;

  FacturaPatrocinadorDto({
    required this.id,
    required this.concepto,
    required this.monto,
    required this.pagado,
    this.pagadoEn,
    required this.venceEn,
    this.notas,
    required this.creadoEn,
    required this.estadoLabel,
  });

  factory FacturaPatrocinadorDto.fromJson(Map<String, dynamic> json) => FacturaPatrocinadorDto(
        id:          json['id'] as String,
        concepto:    json['concepto'] as String? ?? '',
        monto:       (json['monto'] as num?)?.toDouble() ?? 0,
        pagado:      json['pagado'] as bool? ?? false,
        pagadoEn:    json['pagadoEn'] != null ? DateTime.parse(json['pagadoEn'] as String) : null,
        venceEn:     DateTime.parse(json['venceEn'] as String),
        notas:       json['notas'] as String?,
        creadoEn:    DateTime.parse(json['creadoEn'] as String),
        estadoLabel: json['estadoLabel'] as String? ?? '',
      );
}
