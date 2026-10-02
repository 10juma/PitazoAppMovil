import 'package:flutter/material.dart';
import '../data/staff_reservas_repository.dart';
import '../../../models/reserva_dto.dart';

class StaffReservasProvider extends ChangeNotifier {
  final StaffReservasRepository _repo;

  StaffReservasProvider(this._repo);

  bool               loading  = false;
  String?            error;
  bool               activa   = false;
  List<ReservaDto>   listado  = [];
  List<CanchaSimple> canchas  = [];
  List<EquipoSimpleR> equipos = [];
  DateTime           fecha    = DateTime.now();
  String?            canchaFiltro;
  EstadoReserva?     estadoFiltro;

  String get fechaStr {
    final f = fecha;
    return '${f.year}-${f.month.toString().padLeft(2,'0')}-${f.day.toString().padLeft(2,'0')}';
  }

  String get fechaLabel {
    final hoy    = DateUtils.dateOnly(DateTime.now());
    final target = DateUtils.dateOnly(fecha);
    if (target == hoy)                        return 'Hoy';
    if (target == hoy.add(const Duration(days: 1))) return 'Mañana';
    if (target == hoy.subtract(const Duration(days: 1))) return 'Ayer';
    const dias   = ['', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const meses  = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dias[target.weekday]} ${target.day} ${meses[target.month]}';
  }

  bool get esHoy => DateUtils.dateOnly(fecha) == DateUtils.dateOnly(DateTime.now());

  Future<void> cargar() async {
    loading = true;
    error   = null;
    notifyListeners();
    try {
      final r = await _repo.cargar(
        fecha:    fechaStr,
        canchaId: canchaFiltro,
        estado:   estadoFiltro?.valor,
      );
      activa  = r.activa;
      listado = r.listado;
      canchas = r.canchas;
      equipos = r.equipos;
    } catch (e) {
      error = 'Error al cargar reservas';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void irFecha(DateTime nueva) {
    fecha = nueva;
    cargar();
  }

  void irHoy() => irFecha(DateTime.now());

  void irAnterior() => irFecha(fecha.subtract(const Duration(days: 1)));

  void irSiguiente() => irFecha(fecha.add(const Duration(days: 1)));

  void setFiltroCancha(String? id) {
    canchaFiltro = id;
    cargar();
  }

  void setFiltroEstado(EstadoReserva? e) {
    estadoFiltro = e;
    cargar();
  }
}
