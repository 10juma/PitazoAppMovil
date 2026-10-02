import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/auth/token_dto.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyToken           = 'pitazo_token';
  static const _keyBiometriaActiva = 'pitazo_biometria_activa';

  static Future<void> saveToken(TokenDto token) async {
    await _storage.write(key: _keyToken, value: jsonEncode(token.toJson()));
  }

  static Future<TokenDto?> loadToken() async {
    final data = await _storage.read(key: _keyToken);
    if (data == null) return null;
    try {
      return TokenDto.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _keyToken);
  }

  /// Preferencia del usuario: desbloquear la app con Face ID/huella en vez de
  /// re-escribir la contraseña, mientras la sesión guardada siga vigente.
  static Future<void> setBiometriaActiva(bool activa) async {
    await _storage.write(key: _keyBiometriaActiva, value: activa.toString());
  }

  static Future<bool> isBiometriaActiva() async {
    final v = await _storage.read(key: _keyBiometriaActiva);
    return v == 'true';
  }
}
