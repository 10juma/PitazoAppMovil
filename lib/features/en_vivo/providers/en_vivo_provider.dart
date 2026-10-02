import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/en_vivo_dto.dart';
import '../data/en_vivo_repository.dart';

class EnVivoProvider extends ChangeNotifier {
  final String _partidoId;
  final _repo = EnVivoRepository();

  EnVivoDto? _data;
  bool       _loading         = false;
  bool       _mutating        = false;
  bool       _terminadoRemoto = false;
  String?    _error;
  String?    _errorMuta;

  EnVivoDto? get data             => _data;
  bool       get loading          => _loading;
  bool       get mutating         => _mutating;
  bool       get terminadoRemoto  => _terminadoRemoto;
  String?    get error            => _error;
  String?    get errorMuta        => _errorMuta;

  EnVivoProvider(this._partidoId);

  Future<void> load({bool silent = false}) async {
    if (_loading) return;
    if (!silent) {
      _loading = true;
      _error   = null;
      notifyListeners();
    }
    try {
      _data  = await _repo.obtener(_partidoId);
      _error = null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        _terminadoRemoto = true; // partido ya terminó, GET /envivo devuelve 404
      } else {
        _error = e.message;
      }
    } catch (_) {
      _error = 'Error al cargar el partido.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Llamado desde el callback SignalR cuando el partido termina de forma remota.
  // No hace reload (el GET /envivo devuelve 404 cuando el partido ya terminó).
  void marcarTerminadoRemoto(int golesLocal, int golesVisitante) {
    _terminadoRemoto = true;
    if (_data != null) {
      _data = EnVivoDto.fromJson({
        ..._toMap(_data!),
        'golesLocal':    golesLocal,
        'golesVisitante': golesVisitante,
      });
    }
    notifyListeners();
  }

  Future<bool> agregarEvento({
    required String equipoId,
    String? jugadorId,
    String? jugadorSecId,
    required int tipo,
    required int minuto,
    String? nota,
  }) async {
    _mutating  = true;
    _errorMuta = null;
    notifyListeners();
    try {
      await _repo.agregarEvento(_partidoId,
          equipoId: equipoId, jugadorId: jugadorId, jugadorSecId: jugadorSecId,
          tipo: tipo, minuto: minuto, nota: nota);
      await load(silent: true);
      return true;
    } on ApiException catch (e) {
      _errorMuta = e.message;
      return false;
    } catch (_) {
      _errorMuta = 'No se pudo registrar el evento.';
      return false;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  Future<bool> eliminarEvento(String eventoId) async {
    _mutating  = true;
    _errorMuta = null;
    notifyListeners();
    try {
      await _repo.eliminarEvento(_partidoId, eventoId);
      _data = EnVivoDto.fromJson({
        ..._toMap(_data!),
        'eventos': _data!.eventos.where((e) => e.id != eventoId).map(_eventoToMap).toList(),
      });
      return true;
    } on ApiException catch (e) {
      _errorMuta = e.message;
      return false;
    } catch (_) {
      _errorMuta = 'No se pudo eliminar el evento.';
      return false;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  Future<bool> terminar({
    required int golesLocal,
    required int golesVisitante,
    bool tuvoProrroga = false,
    bool tuvoPenales  = false,
    int? golesLocalPenales,
    int? golesVisitantePenales,
  }) async {
    _mutating  = true;
    _errorMuta = null;
    notifyListeners();
    try {
      await _repo.terminar(_partidoId,
          golesLocal: golesLocal, golesVisitante: golesVisitante,
          tuvoProrroga: tuvoProrroga, tuvoPenales: tuvoPenales,
          golesLocalPenales: golesLocalPenales, golesVisitantePenales: golesVisitantePenales);
      return true;
    } on ApiException catch (e) {
      _errorMuta = e.message;
      return false;
    } catch (_) {
      _errorMuta = 'No se pudo terminar el partido.';
      return false;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  // helpers para actualización optimista local al eliminar
  Map<String, dynamic> _toMap(EnVivoDto d) => {
    'id': d.id, 'equipoLocalId': d.equipoLocalId, 'equipoLocalNombre': d.equipoLocalNombre,
    'equipoVisitanteId': d.equipoVisitanteId, 'equipoVisitanteNombre': d.equipoVisitanteNombre,
    'golesLocal': d.golesLocal, 'golesVisitante': d.golesVisitante,
    'canchaNombre': d.canchaNombre, 'arbitroNombre': d.arbitroNombre,
    'ligaNombre': d.ligaNombre, 'temporadaNombre': d.temporadaNombre,
    'duracionTiempoMin': d.duracionTiempoMin, 'tieneTargetaAzul': d.tieneTargetaAzul,
    'jugadoresLocal': d.jugadoresLocal.map(_jugadorToMap).toList(),
    'jugadoresVisitante': d.jugadoresVisitante.map(_jugadorToMap).toList(),
    'eventos': d.eventos.map(_eventoToMap).toList(),
  };

  Map<String, dynamic> _jugadorToMap(JugadorEnVivoDto j) =>
      {'id': j.id, 'nombre': j.nombre, 'apellido': j.apellido, 'dorsal': j.dorsal};

  Map<String, dynamic> _eventoToMap(EventoDto e) => {
    'id': e.id, 'tipo': e.tipo, 'tipoLabel': e.tipoLabel, 'minuto': e.minuto,
    'jugadorNombre': e.jugadorNombre, 'equipoNombre': e.equipoNombre, 'nota': e.nota,
  };
}
