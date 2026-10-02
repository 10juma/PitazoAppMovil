class TenantOpcionDto {
  final String  usuarioId;
  final String  tenantId;
  final String  tenantNombre;
  final String  tenantSlug;
  final String? tenantLogoUrl;
  final String  rol;

  const TenantOpcionDto({
    required this.usuarioId,
    required this.tenantId,
    required this.tenantNombre,
    required this.tenantSlug,
    this.tenantLogoUrl,
    required this.rol,
  });

  factory TenantOpcionDto.fromJson(Map<String, dynamic> json) => TenantOpcionDto(
        usuarioId:     json['usuarioId']     as String,
        tenantId:      json['tenantId']      as String,
        tenantNombre:  json['tenantNombre']  as String,
        tenantSlug:    json['tenantSlug']    as String,
        tenantLogoUrl: json['tenantLogoUrl'] as String?,
        rol:           json['rol']           as String,
      );
}
