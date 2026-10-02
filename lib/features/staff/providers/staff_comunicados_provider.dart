import 'package:flutter/material.dart';
import '../data/staff_comunicados_repository.dart';
import '../../../models/comunicado_dto.dart';

class StaffComunicadosProvider extends ChangeNotifier {
  final StaffComunicadosRepository _repo;
  StaffComunicadosProvider(this._repo);

  bool                   loading  = false;
  String?                error;
  List<ComunicadoDto>    historial = [];
  bool                   comunicacionEquiposActiva = false;
  List<TemporadaOpcion>  temporadas = [];
  List<EquipoOpcionC>    equipos    = [];

  Future<void> cargar() async {
    loading = true;
    error   = null;
    notifyListeners();
    try {
      final results = await Future.wait([_repo.listar(), _repo.opciones()]);
      historial = results[0] as List<ComunicadoDto>;
      final opts = results[1] as ({
        bool comunicacionEquiposActiva,
        List<TemporadaOpcion> temporadas,
        List<EquipoOpcionC> equipos,
      });
      comunicacionEquiposActiva = opts.comunicacionEquiposActiva;
      temporadas                = opts.temporadas;
      equipos                   = opts.equipos;
    } catch (e) {
      error = 'Error al cargar comunicados';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
