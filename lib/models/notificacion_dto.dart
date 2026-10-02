class NotificacionDto {
  final String   id;
  final String   titulo;
  final String   cuerpo;
  final bool     leida;
  final DateTime creadaEn;

  NotificacionDto({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.leida,
    required this.creadaEn,
  });

  factory NotificacionDto.fromJson(Map<String, dynamic> json) => NotificacionDto(
        id:       json['id'] as String,
        titulo:   json['titulo'] as String? ?? '',
        cuerpo:   json['cuerpo'] as String? ?? '',
        leida:    json['leida'] as bool? ?? false,
        creadaEn: DateTime.parse(json['creadaEn'] as String),
      );
}
