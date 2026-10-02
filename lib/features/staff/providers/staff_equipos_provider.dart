import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/equipo_dto.dart';
import '../../../shared/enums/estado_equipo.dart';
import '../data/staff_equipos_repository.dart';

class StaffEquiposProvider extends ChangeNotifier {
  final StaffEquiposRepository _repo;
  StaffEquiposProvider(this._repo);

  List<EquipoDto>  _todos      = [];
  bool             loading     = false;
  String?          error;
  bool             _cargado    = false;
  bool             tieneWhatsApp = false;

  // Filtros
  EstadoEquipo? estadoFiltro;
  String        busqueda = '';

  List<EquipoDto> get filtrados {
    var list = _todos;
    if (estadoFiltro != null) list = list.where((e) => e.estado == estadoFiltro).toList();
    if (busqueda.isNotEmpty) {
      final q = busqueda.toLowerCase();
      list = list.where((e) =>
          e.nombre.toLowerCase().contains(q) ||
          (e.manager?.nombreCompleto.toLowerCase().contains(q) ?? false) ||
          e.tipoLabel.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  Future<void> cargar() async {
    if (_cargado) return;
    loading = true;
    error   = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.listar(),
        _repo.tieneWhatsApp(),
      ]);
      _todos        = results[0] as List<EquipoDto>;
      tieneWhatsApp = results[1] as bool;
      _cargado      = true;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Error al cargar equipos.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> recargar() async {
    _cargado = false;
    _todos   = [];
    await cargar();
  }

  void setEstado(EstadoEquipo? e) { estadoFiltro = e; notifyListeners(); }
  void setBusqueda(String q)      { busqueda     = q; notifyListeners(); }

  void actualizarEquipoLocal(EquipoDto equipo) {
    final i = _todos.indexWhere((e) => e.id == equipo.id);
    if (i >= 0) { _todos[i] = equipo; notifyListeners(); }
  }
}
