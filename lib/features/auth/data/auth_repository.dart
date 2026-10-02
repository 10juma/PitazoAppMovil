import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/auth/login_result_dto.dart';
import '../../../models/auth/token_dto.dart';

class AuthRepository {
  final Dio _dio = ApiClient.create();

  Future<LoginResultDto> login(String email, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      return LoginResultDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TokenDto> seleccionarTenant(String usuarioId, String tenantId) async {
    try {
      final response = await _dio.post('/api/auth/seleccionar-tenant', data: {
        'usuarioId': usuarioId,
        'tenantId':  tenantId,
      });
      return TokenDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Siempre regresa sin error (mensaje genérico) — el backend nunca revela
  /// si el correo existe. `verificacionId` viene null si no hay nada que
  /// continuar (correo no encontrado).
  Future<String?> olvidePassword(String email) async {
    try {
      final response = await _dio.post('/api/auth/olvide-password', data: {'email': email});
      return response.data['verificacionId'] as String?;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> reenviarCodigoRecuperacion(String verificacionId) async {
    try {
      await _dio.post('/api/auth/reenviar-codigo-recuperacion', data: {'verificacionId': verificacionId});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> restablecerPassword(String verificacionId, String codigo, String nuevaPassword) async {
    try {
      await _dio.post('/api/auth/restablecer-password', data: {
        'verificacionId': verificacionId,
        'codigo': codigo,
        'nuevaPassword': nuevaPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> cambiarPassword(String actual, String nueva) async {
    try {
      await _dio.post('/api/auth/cambiar-password', data: {'actual': actual, 'nueva': nueva});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
