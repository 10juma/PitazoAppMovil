import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Envuelve `local_auth` para pedir Face ID/huella al sistema operativo.
/// La verificación ocurre 100% en el dispositivo (Secure Enclave / TEE) —
/// esta app nunca recibe ni procesa datos biométricos, solo un sí/no.
class BiometricService {
  static final _auth = LocalAuthentication();

  /// Código del último error de plataforma (ej. `LockedOut`, `NotAvailable`,
  /// `NotEnrolled`), o null si el último intento no falló por excepción.
  /// Útil para mostrarle al usuario por qué no se activó/usó la biometría
  /// en vez de fallar en silencio.
  static String? ultimoError;

  /// True si el dispositivo tiene hardware biométrico configurado y disponible.
  static Future<bool> disponible() async {
    try {
      final soportado = await _auth.isDeviceSupported();
      final puedeChequear = await _auth.canCheckBiometrics;
      return soportado && puedeChequear;
    } catch (e) {
      if (kDebugMode) debugPrint('[Biometric] disponible() falló: $e');
      return false;
    }
  }

  /// Muestra el diálogo nativo de Face ID/huella. True si el usuario se autenticó.
  static Future<bool> autenticar({String razon = 'Confirma tu identidad para continuar'}) async {
    ultimoError = null;
    try {
      return await _auth.authenticate(
        localizedReason: razon,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      ultimoError = e.toString();
      if (kDebugMode) debugPrint('[Biometric] autenticar() falló: $e');
      return false;
    }
  }
}
