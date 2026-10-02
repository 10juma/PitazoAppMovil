import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../data/manager_repository.dart';

class ManagerPerfilProvider extends ChangeNotifier {
  final _repo = ManagerRepository();

  ManagerPerfilDto? _data;
  bool    _loading   = false;
  bool    _guardando = false;
  String? _error;

  ManagerPerfilDto? get data      => _data;
  String?           get fotoUrl   => _data?.fotoUrl;
  bool    get loading   => _loading;
  bool    get guardando => _guardando;
  String? get error     => _error;

  Future<void> load() async {
    _loading = true; _error = null; notifyListeners();
    try {
      _data = await _repo.obtenerPerfil();
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
    _guardando = true; notifyListeners();
    try {
      final url = await _repo.subirFoto(file);
      _data = _data?.copyWith(fotoUrl: url);
      return null;
    } catch (e) {
      return e is ApiException ? e.message : 'Error al subir foto.';
    } finally {
      _guardando = false; notifyListeners();
    }
  }
}
