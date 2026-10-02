import 'package:flutter/foundation.dart';
import '../data/jugador_repository.dart';
import '../../../shared/enums/estado_partido.dart';

class JugadorProvider extends ChangeNotifier {
  final _repo = JugadorRepository();

  List<EquipoJugadorDto> _equipos      = [];
  EquipoJugadorDto?      _equipoActivo;
  JugadorDashboardDto?   _dashboard;
  List<PartidoJugadorDto> _proximos    = [];
  List<ParticipacionResumenDto> _participaciones = [];
  bool _loading = false;

  List<EquipoJugadorDto>        get equipos         => _equipos;
  EquipoJugadorDto?              get equipoActivo    => _equipoActivo;
  JugadorDashboardDto?           get dashboard       => _dashboard;
  List<PartidoJugadorDto>        get proximos        => _proximos;
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
        await _cargarDatos();
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> cambiarEquipo(String jugadorEquipoId) async {
    _equipoActivo = _equipos.firstWhere(
      (e) => e.jugadorEquipoId == jugadorEquipoId,
      orElse: () => _equipos.first,
    );
    _dashboard = null;
    _proximos = [];
    _participaciones = [];
    notifyListeners();
    try {
      await _cargarParticipaciones();
      await _cargarDatos();
    } catch (_) {}
    notifyListeners();
  }

  /// Cambia la competencia (liga+temporada) activa cuando el equipo participa en varias a la vez.
  Future<void> cambiarParticipacion(String participacionId) async {
    if (_equipoActivo == null) return;
    final jugadorEquipoId = _equipoActivo!.jugadorEquipoId;
    _dashboard = null;
    notifyListeners();
    try {
      final equipos = await _repo.listarEquipos(participacionId: participacionId);
      final actualizado = equipos.firstWhere((e) => e.jugadorEquipoId == jugadorEquipoId, orElse: () => _equipoActivo!);
      _equipoActivo = actualizado;
      final idx = _equipos.indexWhere((e) => e.jugadorEquipoId == jugadorEquipoId);
      if (idx != -1) _equipos[idx] = actualizado;

      await _cargarDatos();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _cargarParticipaciones() async {
    if (_equipoActivo == null) return;
    try {
      _participaciones = await _repo.listarParticipaciones(_equipoActivo!.jugadorEquipoId);
    } catch (_) {
      _participaciones = [];
    }
  }

  Future<void> loadSilent() async {
    if (_equipoActivo == null) return;
    try {
      await _cargarDatos();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _cargarDatos() async {
    final id = _equipoActivo!.jugadorEquipoId;
    final participacionId = _equipoActivo!.participacionId;
    _dashboard = await _repo.obtenerDashboard(id, participacionId: participacionId);
    _proximos  = await _repo.listarPartidos(id, estado: EstadoPartido.programado);
  }
}
