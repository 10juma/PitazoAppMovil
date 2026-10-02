import 'package:flutter/foundation.dart';
import '../../../models/notificacion_dto.dart';
import '../data/notificaciones_repository.dart';

class NotificacionesProvider extends ChangeNotifier {
  final NotificacionesBandejaRepository _repo;
  NotificacionesProvider(this._repo);

  List<NotificacionDto> _notificaciones = [];
  int  _noLeidas = 0;
  bool _loading  = false;

  List<NotificacionDto> get notificaciones => _notificaciones;
  int  get noLeidas => _noLeidas;
  bool get loading  => _loading;

  Future<void> cargar() async {
    _loading = true;
    notifyListeners();
    try {
      _notificaciones = await _repo.listar();
      _noLeidas = _notificaciones.where((n) => !n.leida).length;
    } catch (_) {
      // Silencioso — la bandeja no es crítica para el flujo de la app.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Solo refresca el conteo (para el badge), sin cargar la lista completa.
  Future<void> actualizarConteo() async {
    _noLeidas = await _repo.contarNoLeidas();
    notifyListeners();
  }

  Future<void> marcarLeida(String id) async {
    final i = _notificaciones.indexWhere((n) => n.id == id);
    if (i == -1 || _notificaciones[i].leida) return;

    await _repo.marcarLeida(id);
    _notificaciones[i] = NotificacionDto(
      id: _notificaciones[i].id,
      titulo: _notificaciones[i].titulo,
      cuerpo: _notificaciones[i].cuerpo,
      leida: true,
      creadaEn: _notificaciones[i].creadaEn,
    );
    _noLeidas = _notificaciones.where((n) => !n.leida).length;
    notifyListeners();
  }
}
