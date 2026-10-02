import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../data/jugador_repository.dart';

class JugadorPerfilProvider extends ChangeNotifier {
  final _repo = JugadorRepository();
  final String? jugadorEquipoId;

  JugadorPerfilProvider({this.jugadorEquipoId});

  JugadorPerfilDto?      _data;
  String?                _fotoUrl;
  FichaTecnicaDto?       _ficha;
  bool                   _fichaCargada = false;
  bool                   _estadisticasAvanzadasActivas = false;
  bool    _loading   = false;
  bool    _guardando = false;
  String? _error;

  JugadorPerfilDto? get data      => _data;
  String?           get fotoUrl   => _fotoUrl;
  FichaTecnicaDto?  get ficha     => _ficha;
  bool              get fichaCargada => _fichaCargada;
  bool              get estadisticasAvanzadasActivas => _estadisticasAvanzadasActivas;
  bool    get loading   => _loading;
  bool    get guardando => _guardando;
  String? get error     => _error;

  Future<void> load() async {
    _loading = true; _error = null; notifyListeners();
    try {
      _data = await _repo.obtenerPerfil();
      if (jugadorEquipoId != null) {
        final (ficha, avanzadas) = await _repo.obtenerFicha(jugadorEquipoId!);
        _ficha = ficha;
        _estadisticasAvanzadasActivas = avanzadas;
        _fichaCargada = true;
        _fotoUrl ??= ficha?.fotoUrl;
      }
    } catch (e) {
      _error = e is ApiException ? e.message : 'Error al cargar perfil.';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<String?> guardar({
    required String nombre,
    required String apellido,
    String?         telefono,
  }) async {
    _guardando = true; notifyListeners();
    try {
      await _repo.actualizarPerfil(nombre: nombre, apellido: apellido, telefono: telefono);
      _data = _data?.copyWith(
        nombreCompleto: '$nombre $apellido'.trim(),
        fNombre:   nombre,
        fApellido: apellido,
        fTelefono: telefono?.isEmpty == true ? null : telefono,
      );
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Error al guardar.';
    } finally {
      _guardando = false; notifyListeners();
    }
  }

  Future<String?> subirFoto(File file) async {
    if (jugadorEquipoId == null) return 'Sin equipo activo';
    _guardando = true; notifyListeners();
    try {
      _fotoUrl = await _repo.subirFoto(jugadorEquipoId!, file);
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Error al subir foto.';
    } finally {
      _guardando = false; notifyListeners();
    }
  }
}
