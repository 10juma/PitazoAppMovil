import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class AdminPerfilDto {
  final String  nombreCompleto;
  final String  email;
  final String? fotoUrl;
  final String  fNombre;
  final String  fApellido;
  final String? fTelefono;

  const AdminPerfilDto({
    required this.nombreCompleto,
    required this.email,
    this.fotoUrl,
    required this.fNombre,
    required this.fApellido,
    this.fTelefono,
  });

  factory AdminPerfilDto.fromJson(Map<String, dynamic> j) => AdminPerfilDto(
        nombreCompleto: j['nombreCompleto'] as String? ?? '',
        email:          j['email']          as String? ?? '',
        fotoUrl:        j['fotoUrl']        as String?,
        fNombre:        j['fNombre']        as String? ?? '',
        fApellido:      j['fApellido']      as String? ?? '',
        fTelefono:      j['fTelefono']      as String?,
      );

  AdminPerfilDto copyWith({
    String? nombreCompleto,
    String? email,
    String? fotoUrl,
    String? fNombre,
    String? fApellido,
    String? fTelefono,
    bool clearFoto = false,
  }) => AdminPerfilDto(
        nombreCompleto: nombreCompleto ?? this.nombreCompleto,
        email:          email          ?? this.email,
        fotoUrl:        clearFoto ? null : (fotoUrl ?? this.fotoUrl),
        fNombre:        fNombre        ?? this.fNombre,
        fApellido:      fApellido      ?? this.fApellido,
        fTelefono:      fTelefono      ?? this.fTelefono,
      );
}

class AdminPerfilRepository {
  final Dio _dio = ApiClient.create();

  Future<AdminPerfilDto> obtener() async {
    try {
      final res = await _dio.get('/api/admin/perfil');
      return AdminPerfilDto.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> actualizar({
    required String  nombre,
    required String  apellido,
    String?          telefono,
  }) async {
    try {
      await _dio.put('/api/admin/perfil', data: {
        'nombre':   nombre,
        'apellido': apellido,
        'telefono': telefono,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<String> subirFoto(File file) async {
    try {
      final form = FormData.fromMap({
        'foto': await MultipartFile.fromFile(file.path),
      });
      final res = await _dio.post('/api/admin/perfil/foto', data: form);
      return (res.data as Map<String, dynamic>)['fotoUrl'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
