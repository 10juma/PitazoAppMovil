import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/cancha.dart';
import '../data/cancha_repository.dart';

class CanchasEstadoProvider extends ChangeNotifier {
  final _repo = CanchaRepository();

  bool    _disposed = false;
  List<EstadoCanchaStaffDto> _canchas = [];
  bool    _loading  = false;
  bool    _mutating = false;
  String? _error;
  String? _errorMuta;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() { if (!_disposed) notifyListeners(); }

  List<EstadoCanchaStaffDto> get canchas  => _canchas;
  bool    get loading  => _loading;
  bool    get mutating => _mutating;
  String? get error    => _error;
  String? get errorMuta => _errorMuta;

  Future<void> cargar({bool silent = false}) async {
    if (_loading) return;
    if (!silent) {
      _loading = true;
      _error   = null;
      _notify();
    }
    try {
      _canchas = await _repo.obtenerEstado();
      _error   = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Error al cargar el estado de canchas.';
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<bool> iniciarMantenimiento(
    String canchaId, {
    required int categoria,
    required String descripcion,
    double? costoEstimado,
    String? proveedor,
  }) async {
    _mutating  = true;
    _errorMuta = null;
    _notify();
    try {
      await _repo.iniciarMantenimiento(canchaId,
          categoria:     categoria,
          descripcion:   descripcion,
          costoEstimado: costoEstimado,
          proveedor:     proveedor);
      await cargar(silent: true);
      return true;
    } on ApiException catch (e) {
      _errorMuta = e.message;
      return false;
    } catch (_) {
      _errorMuta = 'Error al iniciar mantenimiento.';
      return false;
    } finally {
      _mutating = false;
      _notify();
    }
  }

  Future<bool> resolverMantenimiento(
    String registroId, {
    double? costoReal,
    String? observacion,
  }) async {
    _mutating  = true;
    _errorMuta = null;
    _notify();
    try {
      await _repo.resolverMantenimiento(registroId,
          costoReal:   costoReal,
          observacion: observacion);
      await cargar(silent: true);
      return true;
    } on ApiException catch (e) {
      _errorMuta = e.message;
      return false;
    } catch (_) {
      _errorMuta = 'Error al resolver mantenimiento.';
      return false;
    } finally {
      _mutating = false;
      _notify();
    }
  }

  Future<List<RegistroMantenimientoDto>> historial(String canchaId) async {
    try {
      return await _repo.historial(canchaId);
    } catch (_) {
      return [];
    }
  }
}
