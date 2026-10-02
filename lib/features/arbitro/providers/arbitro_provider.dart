import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/partido_resumen_dto.dart';
import '../data/arbitro_repository.dart';

class ArbitroProvider extends ChangeNotifier {
  final _repo = ArbitroRepository();

  ArbitroPerfilDto?       _perfil;
  List<PartidoResumenDto> _enVivo   = [];
  List<PartidoResumenDto> _proximos = [];
  ResumenEvaluacionesDto  _resumen  = ResumenEvaluacionesDto.vacio;

  bool    _loading  = false;
  bool    _subiendo = false;
  String? _error;

  ArbitroPerfilDto?       get perfil   => _perfil;
  List<PartidoResumenDto> get enVivo   => _enVivo;
  List<PartidoResumenDto> get proximos => _proximos;
  ResumenEvaluacionesDto  get resumen  => _resumen;
  bool                    get loading  => _loading;
  bool                    get subiendo => _subiendo;
  String?                 get error    => _error;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      final perfilFut   = _repo.obtenerPerfil();
      final enVivoFut   = _repo.listarEnVivo();
      final proximosFut = _repo.listarProximos();
      final resumenFut  = _repo.obtenerResumen();
      _perfil   = await perfilFut;
      _enVivo   = await enVivoFut;
      _proximos = await proximosFut;
      _resumen  = await resumenFut;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Error al cargar el dashboard.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _perfil   = null;
    _enVivo   = [];
    _proximos = [];
    _resumen  = ResumenEvaluacionesDto.vacio;
    await load();
  }

  Future<void> loadSilent() async {
    if (_loading) return;
    _loading = true;
    try {
      final perfilFut   = _repo.obtenerPerfil();
      final enVivoFut   = _repo.listarEnVivo();
      final proximosFut = _repo.listarProximos();
      final resumenFut  = _repo.obtenerResumen();
      _perfil   = await perfilFut;
      _enVivo   = await enVivoFut;
      _proximos = await proximosFut;
      _resumen  = await resumenFut;
    } catch (_) {}
    finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> subirFoto(File file) async {
    _subiendo = true;
    notifyListeners();
    try {
      final nuevaUrl = await _repo.subirFoto(file);
      _perfil = _perfil?.copyWith(fotoUrl: nuevaUrl);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Error al subir la foto.';
    } finally {
      _subiendo = false;
      notifyListeners();
    }
  }

  Future<String?> iniciarPartido(String id) async {
    try {
      await _repo.iniciarPartido(id);
      await loadSilent();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Error al iniciar el partido.';
    }
  }
}
