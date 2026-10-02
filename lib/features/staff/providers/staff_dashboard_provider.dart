import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/staff_dashboard_dto.dart';
import '../data/staff_dashboard_repository.dart';

class StaffDashboardProvider extends ChangeNotifier {
  final _repo = StaffDashboardRepository();

  StaffDashboardData? _data;
  bool _loading = false;
  String? _error;

  StaffDashboardData? get data          => _data;
  bool                get loading       => _loading;
  String?             get error         => _error;
  bool                get tieneReservas => _data?.reservasCanchasActiva ?? false;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      _data = await _repo.cargarDashboard();
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
    _data = null;
    await load();
  }

  Future<void> loadSilent() async {
    if (_loading) return;
    _loading = true;
    try {
      _data = await _repo.cargarDashboard();
    } catch (_) {}
    finally {
      _loading = false;
      notifyListeners();
    }
  }
}
