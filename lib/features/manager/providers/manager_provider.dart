import 'package:flutter/foundation.dart';
import '../data/manager_repository.dart';

class ManagerProvider extends ChangeNotifier {
  final _repo = ManagerRepository();

  List<EquipoManagerDto> _equipos     = [];
  EquipoManagerDto?      _equipoActivo;
  ManagerDashboardDto?   _dashboard;
  List<ParticipacionResumenDto> _participaciones = [];
  bool _loading = false;

  List<EquipoManagerDto>        get equipos         => _equipos;
  EquipoManagerDto?              get equipoActivo    => _equipoActivo;
  ManagerDashboardDto?           get dashboard       => _dashboard;
  List<ParticipacionResumenDto>  get participaciones => _participaciones;
  bool                           get loading         => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _equipos = await _repo.listarEquipos();
      if (_equipos.isNotEmpty) {
        _equipoActivo ??= _equipos.first;
        await _cargarParticipaciones();
        _dashboard = await _repo.obtenerDashboard(
          _equipoActivo!.equipoId,
          participacionId: _equipoActivo!.participacionId,
        );
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> cambiarEquipo(String equipoId) async {
    _equipoActivo = _equipos.firstWhere(
      (e) => e.equipoId == equipoId,
      orElse: () => _equipos.first,
    );
    _dashboard = null;
    _participaciones = [];
    notifyListeners();
    try {
      await _cargarParticipaciones();
      _dashboard = await _repo.obtenerDashboard(
        equipoId,
        participacionId: _equipoActivo!.participacionId,
      );
    } catch (_) {}
    notifyListeners();
  }

  /// Cambia la competencia (liga+temporada) activa cuando el equipo participa en varias a la vez.
  Future<void> cambiarParticipacion(String participacionId) async {
    if (_equipoActivo == null) return;
    final equipoId = _equipoActivo!.equipoId;
    _dashboard = null;
    notifyListeners();
    try {
      final equipos = await _repo.listarEquipos(participacionId: participacionId);
      final actualizado = equipos.firstWhere((e) => e.equipoId == equipoId, orElse: () => _equipoActivo!);
      _equipoActivo = actualizado;
      final idx = _equipos.indexWhere((e) => e.equipoId == equipoId);
      if (idx != -1) _equipos[idx] = actualizado;

      _dashboard = await _repo.obtenerDashboard(equipoId, participacionId: actualizado.participacionId);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _cargarParticipaciones() async {
    if (_equipoActivo == null) return;
    try {
      _participaciones = await _repo.listarParticipaciones(_equipoActivo!.equipoId);
    } catch (_) {
      _participaciones = [];
    }
  }

  Future<void> loadSilent() async {
    if (_equipoActivo == null) return;
    try {
      _dashboard = await _repo.obtenerDashboard(
        _equipoActivo!.equipoId,
        participacionId: _equipoActivo!.participacionId,
      );
      notifyListeners();
    } catch (_) {}
  }
}
