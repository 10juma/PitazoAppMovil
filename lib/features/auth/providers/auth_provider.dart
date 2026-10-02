import 'package:flutter/foundation.dart';
import '../../../core/auth/biometric_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../models/auth/tenant_opcion_dto.dart';
import '../../../models/auth/token_dto.dart';
import '../data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  TokenDto?              _token;
  List<TenantOpcionDto>? _pendingTenants;
  bool _biometriaActiva = false;
  bool _desbloqueado    = true;
  final _repo = AuthRepository();

  TokenDto?              get token          => _token;
  List<TenantOpcionDto>? get pendingTenants => _pendingTenants;
  bool get biometriaActiva => _biometriaActiva;

  bool get isLoggedIn => _token != null && !_token!.isExpired && _desbloqueado;

  bool get requiereDesbloqueo =>
      _biometriaActiva && _token != null && !_token!.isExpired && !_desbloqueado;

  String get homePath => switch (_token?.rol) {
        'Admin'        => '/admin',
        'Staff'        => '/staff',
        'Arbitro'      => '/arbitro',
        'Manager'      => '/manager',
        'Jugador'      => '/jugador',
        'Patrocinador' => '/patrocinador',
        _              => '/login',
      };

  Future<void> init() async {
    _token           = await SecureStorage.loadToken();
    _biometriaActiva = await SecureStorage.isBiometriaActiva();
    _desbloqueado    = !(_biometriaActiva && _token != null && !_token!.isExpired);
    notifyListeners();
  }

  /// Login con credenciales. Si el usuario pertenece a más de una liga,
  /// [pendingTenants] se llena y hay que llamar a [seleccionarTenant] para
  /// obtener el JWT. Si solo pertenece a una liga, [token] queda listo y se
  /// puede llamar a [confirmarLogin] directamente.
  /// No llama a [notifyListeners] — lo hace [confirmarLogin] para que la
  /// pantalla pueda mostrar el diálogo de biometría antes de navegar.
  Future<void> login(String email, String password, {bool recordarme = true}) async {
    final result = await _repo.login(email, password);

    if (result.requiereSeleccion) {
      _pendingTenants = result.tenants;
      return;
    }

    _token          = result.token!;
    _pendingTenants = null;
    _desbloqueado   = true;
    if (recordarme) await SecureStorage.saveToken(_token!);
  }

  /// Selecciona una liga tras un login multi-tenant. Misma semántica que
  /// [login]: no notifica hasta que se llame a [confirmarLogin].
  Future<void> seleccionarTenant(String usuarioId, String tenantId, {bool recordarme = true}) async {
    final token = await _repo.seleccionarTenant(usuarioId, tenantId);
    _token          = token;
    _pendingTenants = null;
    _desbloqueado   = true;
    if (recordarme) await SecureStorage.saveToken(token);
  }

  void confirmarLogin() => notifyListeners();

  Future<bool> desbloquearConBiometria() async {
    if (_token == null || _token!.isExpired) return false;
    final ok = await BiometricService.autenticar(
      razon: 'Confirma tu identidad para entrar a Pitazo',
    );
    if (ok) {
      _desbloqueado = true;
      notifyListeners();
    }
    return ok;
  }

  Future<void> activarBiometria() async {
    _biometriaActiva = true;
    await SecureStorage.setBiometriaActiva(true);
    notifyListeners();
  }

  Future<void> desactivarBiometria() async {
    _biometriaActiva = false;
    await SecureStorage.setBiometriaActiva(false);
    notifyListeners();
  }

  Future<void> logout() async {
    _token          = null;
    _pendingTenants = null;
    _desbloqueado   = true;
    await SecureStorage.clearToken();
    notifyListeners();
  }

  Future<void> updateFoto(String? url) async {
    if (_token == null) return;
    _token = _token!.copyWith(fotoPerfilUrl: url);
    await SecureStorage.saveToken(_token!);
    notifyListeners();
  }

  String? get rolAccentHex => _token == null
      ? null
      : RolePalettes.accentForRol(_token!.rol).toARGB32().toRadixString(16);
}
