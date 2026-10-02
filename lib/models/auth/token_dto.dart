class TokenDto {
  final String token;
  final String nombre;
  final String email;
  final String rol;
  final String usuarioId;
  final String? tenantId;
  final String tenantNombre;
  final String tenantSlug;
  final String? tenantLogoUrl;
  final String? fotoPerfilUrl;
  final DateTime expira;

  const TokenDto({
    required this.token,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.usuarioId,
    this.tenantId,
    required this.tenantNombre,
    required this.tenantSlug,
    this.tenantLogoUrl,
    this.fotoPerfilUrl,
    required this.expira,
  });

  factory TokenDto.fromJson(Map<String, dynamic> json) => TokenDto(
        token:          json['token']         as String,
        nombre:         json['nombre']        as String,
        email:          json['email']         as String,
        rol:            json['rol']           as String,
        usuarioId:      json['usuarioId']     as String,
        tenantId:       json['tenantId']      as String?,
        tenantNombre:   json['tenantNombre']  as String? ?? '',
        tenantSlug:     json['tenantSlug']    as String? ?? '',
        tenantLogoUrl:  json['tenantLogoUrl'] as String?,
        fotoPerfilUrl:  json['avatarUrl']     as String?,
        expira:         DateTime.parse(json['expira'] as String),
      );

  Map<String, dynamic> toJson() => {
        'token':         token,
        'nombre':        nombre,
        'email':         email,
        'rol':           rol,
        'usuarioId':     usuarioId,
        'tenantId':      tenantId,
        'tenantNombre':  tenantNombre,
        'tenantSlug':    tenantSlug,
        'tenantLogoUrl': tenantLogoUrl,
        'avatarUrl':     fotoPerfilUrl,
        'expira':        expira.toIso8601String(),
      };

  TokenDto copyWith({String? fotoPerfilUrl}) => TokenDto(
        token:         token,
        nombre:        nombre,
        email:         email,
        rol:           rol,
        usuarioId:     usuarioId,
        tenantId:      tenantId,
        tenantNombre:  tenantNombre,
        tenantSlug:    tenantSlug,
        tenantLogoUrl: tenantLogoUrl,
        fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
        expira:        expira,
      );

  bool get isExpired => expira.isBefore(DateTime.now());
}
