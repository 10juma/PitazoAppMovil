import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/patrocinador_dto.dart';
import '../data/patrocinador_repository.dart';

class PatrocinadorProvider extends ChangeNotifier {
  final PatrocinadorRepository _repo;
  PatrocinadorProvider(this._repo);

  PatrocinadorPortalDto?       perfil;
  MetricasPatrocinadorDto?     metricas;
  List<FacturaPatrocinadorDto> facturas = [];

  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final resultados = await Future.wait([
        _repo.obtenerPerfil(),
        _repo.obtenerMetricas(),
        _repo.listarFacturas(),
      ]);
      perfil   = resultados[0] as PatrocinadorPortalDto?;
      metricas = resultados[1] as MetricasPatrocinadorDto;
      facturas = resultados[2] as List<FacturaPatrocinadorDto>;
    } catch (e) {
      error = e is ApiException ? e.message : 'No se pudo cargar tu información.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<String?> actualizarPerfil({
    String? logoUrl,
    String? sitioWeb,
    String? contactoNombre,
    String? contactoTelefono,
    String? contactoEmail,
  }) async {
    try {
      await _repo.actualizarPerfil(
        logoUrl: logoUrl,
        sitioWeb: sitioWeb,
        contactoNombre: contactoNombre,
        contactoTelefono: contactoTelefono,
        contactoEmail: contactoEmail,
      );
      await load();
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'No se pudo guardar tu información.';
    }
  }
}
