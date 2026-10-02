import 'tenant_opcion_dto.dart';
import 'token_dto.dart';

class LoginResultDto {
  final TokenDto?            token;
  final List<TenantOpcionDto>? tenants;

  bool get requiereSeleccion => tenants != null;

  const LoginResultDto({this.token, this.tenants});

  factory LoginResultDto.fromJson(Map<String, dynamic> json) {
    if (json['requiereSeleccion'] == true) {
      return LoginResultDto(
        tenants: (json['tenants'] as List)
            .map((t) => TenantOpcionDto.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
    }
    return LoginResultDto(token: TokenDto.fromJson(json));
  }
}
