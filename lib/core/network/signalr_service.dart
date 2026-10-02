import 'package:signalr_netcore/signalr_client.dart';

class PartidoSignalRService {
  final String _partidoId;
  final String _hubUrl;
  HubConnection? _connection;

  PartidoSignalRService(this._partidoId, String apiBase)
      : _hubUrl = '$apiBase/hubs/partido';

  Future<void> connect({
    required void Function(int minuto, int golesLocal, int golesVisitante) onEventoAgregado,
    required void Function(int golesLocal, int golesVisitante) onEventoEliminado,
    required void Function(int golesLocal, int golesVisitante) onPartidoTerminado,
  }) async {
    _connection = HubConnectionBuilder()
        .withUrl(_hubUrl)
        .withAutomaticReconnect()
        .build();

    _connection!.on('eventoAgregado', (args) {
      final data  = _map(args);
      final ev    = data?['evento'] as Map<Object?, Object?>?;
      final min   = (ev?['minuto'] as num?)?.toInt() ?? 0;
      final gl    = (data?['golesLocal']     as num?)?.toInt() ?? 0;
      final gv    = (data?['golesVisitante'] as num?)?.toInt() ?? 0;
      onEventoAgregado(min, gl, gv);
    });

    _connection!.on('eventoEliminado', (args) {
      final data = _map(args);
      final gl   = (data?['golesLocal']     as num?)?.toInt() ?? 0;
      final gv   = (data?['golesVisitante'] as num?)?.toInt() ?? 0;
      onEventoEliminado(gl, gv);
    });

    _connection!.on('partidoTerminado', (args) {
      final data = _map(args);
      final gl   = (data?['golesLocal']     as num?)?.toInt() ?? 0;
      final gv   = (data?['golesVisitante'] as num?)?.toInt() ?? 0;
      onPartidoTerminado(gl, gv);
    });

    try {
      await _connection!.start();
      await _connection!.invoke('JoinPartido', args: [_partidoId]);
    } catch (_) {
      // Falla silencioso — polling de 60s es el fallback
    }
  }

  Future<void> dispose() async {
    try {
      await _connection?.invoke('LeavePartido', args: [_partidoId]);
      await _connection?.stop();
    } catch (_) {}
    _connection = null;
  }

  static Map<Object?, Object?>? _map(List<Object?>? args) {
    final raw = args?.firstOrNull;
    if (raw is Map) return raw as Map<Object?, Object?>;
    return null;
  }
}
