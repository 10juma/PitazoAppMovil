import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/partido_resumen_dto.dart';
import '../../../shared/enums/estado_partido.dart';
import '../data/admin_partidos_repository.dart';

class OpcionFiltro {
  final String id;
  final String nombre;
  const OpcionFiltro(this.id, this.nombre);
}

/// Estado del listado de partidos del dashboard de Admin — independiente de
/// `StaffPartidosProvider` a propósito (mismo criterio de filtrado hoy, pero
/// con la libertad de divergir mañana sin tocar el otro rol).
class AdminPartidosProvider extends ChangeNotifier {
  final AdminPartidosRepository _repo;
  AdminPartidosProvider(this._repo);

  List<PartidoResumenDto>  _todos    = [];
  bool                     loading   = false;
  String?                  error;
  bool                     _cargado  = false;

  // Filtros activos
  String?         ligaFiltro;
  String?         temporadaFiltro;
  EstadoPartido?  estadoFiltro;
  String          busqueda = '';

  List<OpcionFiltro> get ligasOpciones {
    final seen = <String>{};
    final out  = <OpcionFiltro>[];
    for (final p in _todos) {
      if (seen.add(p.ligaId)) out.add(OpcionFiltro(p.ligaId, p.ligaNombre));
    }
    return out;
  }

  List<OpcionFiltro> get temporadasOpciones {
    final seen = <String>{};
    final out  = <OpcionFiltro>[];
    for (final p in _todos) {
      if (ligaFiltro != null && p.ligaId != ligaFiltro) continue;
      if (seen.add(p.temporadaId)) out.add(OpcionFiltro(p.temporadaId, p.temporadaNombre));
    }
    return out;
  }

  List<PartidoResumenDto> get filtrados {
    var list = _todos;
    if (ligaFiltro      != null) list = list.where((p) => p.ligaId      == ligaFiltro).toList();
    if (temporadaFiltro != null) list = list.where((p) => p.temporadaId == temporadaFiltro).toList();
    // Sin filtro explícito de estado, los Cancelados quedan ocultos por default
    // (mismo criterio que la web) — seleccionar el estado "Cancelado" sí los muestra.
    if (estadoFiltro    != null) {
      list = list.where((p) => p.estado == estadoFiltro).toList();
    } else {
      list = list.where((p) => p.estado != EstadoPartido.cancelado).toList();
    }
    if (busqueda.isNotEmpty) {
      final q = busqueda.toLowerCase();
      list = list.where((p) =>
          p.equipoLocalNombre.toLowerCase().contains(q)     ||
          p.equipoVisitanteNombre.toLowerCase().contains(q) ||
          p.ligaNombre.toLowerCase().contains(q)            ||
          p.temporadaNombre.toLowerCase().contains(q)       ||
          (p.canchaNombre?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    return list;
  }

  /// Ventana por default: igual que la web (Admin/Partidos) — desde ayer hasta
  /// 30 días adelante. Evita traer el histórico completo del tenant de una vez.
  (DateTime, DateTime) _ventanaDefault() {
    final hoy = DateTime.now();
    final diaHoy = DateTime(hoy.year, hoy.month, hoy.day);
    return (diaHoy.subtract(const Duration(days: 1)), diaHoy.add(const Duration(days: 30)));
  }

  Future<void> cargar() async {
    if (_cargado) return;
    loading = true;
    error   = null;
    notifyListeners();
    try {
      final (desde, hasta) = _ventanaDefault();
      _todos   = await _repo.listar(desde: desde, hasta: hasta);
      _cargado = true;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Error al cargar partidos.';
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

  void setLiga(String? id) {
    ligaFiltro      = id;
    temporadaFiltro = null;
    notifyListeners();
  }

  void setTemporada(String? id) {
    temporadaFiltro = id;
    notifyListeners();
  }

  void setEstado(EstadoPartido? e) {
    estadoFiltro = e;
    notifyListeners();
  }

  void setBusqueda(String q) {
    busqueda = q;
    notifyListeners();
  }
}
