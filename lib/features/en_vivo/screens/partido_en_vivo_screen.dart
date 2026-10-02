import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/config/env.dart';
import '../../../core/network/signalr_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/en_vivo_dto.dart';
import '../providers/en_vivo_provider.dart';

// ── Entrada pública ────────────────────────────────────────────────────────────

class PartidoEnVivoScreen extends StatefulWidget {
  final String partidoId;
  const PartidoEnVivoScreen({super.key, required this.partidoId});

  @override
  State<PartidoEnVivoScreen> createState() => _PartidoEnVivoScreenState();
}

class _PartidoEnVivoScreenState extends State<PartidoEnVivoScreen> {
  late final EnVivoProvider _provider;
  late final PartidoSignalRService _signalR;
  Timer? _timer;
  final bool _terminoLocal = false;

  @override
  void initState() {
    super.initState();
    _provider = EnVivoProvider(widget.partidoId);
    _provider.load();

    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _provider.load(silent: true),
    );

    _signalR = PartidoSignalRService(widget.partidoId, Env.apiUrl);
    _signalR.connect(
      onEventoAgregado:   (_, __, ___) => _provider.load(silent: true),
      onEventoEliminado:  (__, ___) => _provider.load(silent: true),
      onPartidoTerminado: (gl, gv) {
        if (_terminoLocal) return;
        _provider.marcarTerminadoRemoto(gl, gv);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El partido fue marcado como terminado'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _signalR.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EnVivoProvider>.value(
      value: _provider,
      child: const _EnVivoScaffold(),
    );
  }
}

// ── Scaffold principal ─────────────────────────────────────────────────────────

class _EnVivoScaffold extends StatelessWidget {
  const _EnVivoScaffold();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<EnVivoProvider>();
    final data = prov.data;

    String title = 'En Vivo';
    if (data != null) {
      final l = _abr(data.equipoLocalNombre);
      final v = _abr(data.equipoVisitanteNombre);
      title = '$l vs $v';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          tooltip: '',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        actions: [
          if (prov.loading && data == null)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: _LiveBadge(pulsing: prov.loading),
            ),
        ],
      ),
      body: _buildBody(context, prov, data),
    );
  }

  Widget _buildBody(BuildContext context, EnVivoProvider prov, EnVivoDto? data) {
    if (prov.loading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (prov.error != null && data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(prov.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<EnVivoProvider>().load(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (data == null) return const SizedBox.shrink();

    final terminado = prov.terminadoRemoto || data.fase == FasePartido.terminado;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<EnVivoProvider>().load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
        children: [
          if (!terminado) ...[
            _ScoreCard(data: data),
            const SizedBox(height: 10),
          ],
          if (terminado) ...[
            _TerminadoBanner(data: data),
            const SizedBox(height: 16),
          ] else ...[
            if (prov.errorMuta != null) _ErrorBanner(mensaje: prov.errorMuta!),
            _FaseControls(data: data),
            const SizedBox(height: 8),
            if (data.fase == FasePartido.penales)
              _TandaPenalesPanel(data: data)
            else
              _AccionesGrid(data: data),
            const SizedBox(height: 8),
            _TerminarButton(data: data),
            const SizedBox(height: 8),
          ],
          _Timeline(data: data),
        ],
      ),
    );
  }

  static String _abr(String nombre) {
    if (nombre.length <= 14) return nombre;
    final words = nombre.split(' ');
    if (words.length == 1) return nombre.substring(0, 14);
    return words.take(2).join(' ');
  }
}

// ── Badge EN VIVO ──────────────────────────────────────────────────────────────

class _LiveBadge extends StatefulWidget {
  final bool pulsing;
  const _LiveBadge({required this.pulsing});

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _ctrl,
          child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFFDC2626))),
        ),
        const SizedBox(width: 5),
        const Text('EN VIVO',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
                letterSpacing: 0.5)),
      ],
    );
  }
}

// ── Tarjeta de marcador ────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final EnVivoDto data;
  const _ScoreCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final minuto = data.minutoActual;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
      child: Column(
        children: [
          if (data.ligaNombre != null || data.canchaNombre != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                [data.ligaNombre, data.canchaNombre]
                    .whereType<String>()
                    .join(' · '),
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  data.equipoLocalNombre,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _ScoreBox(
                  golesLocal: data.golesLocal,
                  golesVisitante: data.golesVisitante),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.equipoVisitanteNombre,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "$minuto'",
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626)),
          ),
          if (data.arbitroNombre != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports, size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(data.arbitroNombre!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final int golesLocal, golesVisitante;
  const _ScoreBox({required this.golesLocal, required this.golesVisitante});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$golesLocal',
              style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('—',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textHint,
                    height: 1)),
          ),
          Text('$golesVisitante',
              style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1)),
        ],
      ),
    );
  }
}

// ── Error banner inline ────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String mensaje;
  const _ErrorBanner({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensaje,
                style: const TextStyle(fontSize: 12, color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Controles de fase ──────────────────────────────────────────────────────────

class _FaseControls extends StatelessWidget {
  final EnVivoDto data;
  const _FaseControls({required this.data});

  @override
  Widget build(BuildContext context) {
    final fase    = data.fase;
    final mutating = context.watch<EnVivoProvider>().mutating;

    final (faseLabel, btnLabel, nextTipo) = switch (fase) {
      FasePartido.primerTiempo  => ('1er Tiempo',  'Fin del 1er Tiempo →', 15),
      FasePartido.descanso      => ('Descanso',     'Iniciar 2do Tiempo →', 16),
      FasePartido.segundoTiempo => ('2do Tiempo',   'Iniciar Prórroga →',   13),
      FasePartido.tiempoExtra   => ('Prórroga',     'Fin de Prórroga →',    14),
      FasePartido.penales       => ('Penales',      '',                       0),
      FasePartido.terminado     => ('Terminado',    '',                       0),
    };

    final showBtn = nextTipo > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _faseColor(fase).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _faseColor(fase).withValues(alpha: 0.35), width: 0.5),
            ),
            child: Text(faseLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _faseColor(fase))),
          ),
          const Spacer(),
          if (showBtn)
            GestureDetector(
              onTap: mutating ? null : () => _registrarFase(context, nextTipo, data),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: mutating ? 0.4 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _faseColor(fase).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _faseColor(fase).withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text(btnLabel,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _faseColor(fase))),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _faseColor(FasePartido fase) => switch (fase) {
        FasePartido.primerTiempo  => AppColors.primary,
        FasePartido.descanso      => const Color(0xFFB45309),
        FasePartido.segundoTiempo => AppColors.primary,
        FasePartido.tiempoExtra   => const Color(0xFF7C3AED),
        FasePartido.penales       => const Color(0xFF7C3AED),
        FasePartido.terminado     => AppColors.textHint,
      };

  Future<void> _registrarFase(BuildContext context, int tipo, EnVivoDto data) async {
    final prov = context.read<EnVivoProvider>();
    await prov.agregarEvento(
      equipoId: data.equipoLocalId,
      tipo: tipo,
      minuto: data.minutoActual > 0 ? data.minutoActual : 1,
    );
  }
}

// ── Banner partido terminado ───────────────────────────────────────────────────

class _TerminadoBanner extends StatelessWidget {
  final EnVivoDto data;
  const _TerminadoBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.flag_rounded, size: 14, color: AppColors.textHint),
              SizedBox(width: 6),
              Text('PARTIDO TERMINADO',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(data.equipoLocalNombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('${data.golesLocal}  —  ${data.golesVisitante}',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1)),
              ),
              Expanded(
                child: Text(data.equipoVisitanteNombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Volver'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid de acciones ───────────────────────────────────────────────────────────

class _AccionesGrid extends StatelessWidget {
  final EnVivoDto data;
  const _AccionesGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final mutating = context.watch<EnVivoProvider>().mutating;
    final prov     = context.read<EnVivoProvider>();

    void abrir(String equipoId, String equipoNombre,
        List<JugadorEnVivoDto> jugadores, _EventoMode mode) {
      if (mutating) return;
      _mostrarSheetEvento(context,
          prov: prov,
          data: data,
          equipoId: equipoId,
          equipoNombre: equipoNombre,
          jugadores: jugadores,
          mode: mode,
          tieneAzul: data.tieneTargetaAzul);
    }

    final l    = data.equipoLocalNombre;
    final v    = data.equipoVisitanteNombre;
    final jL   = data.jugadoresLocal;
    final jV   = data.jugadoresVisitante;
    final lId  = data.equipoLocalId;
    final vId  = data.equipoVisitanteId;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: [
        // Gol
        _ActionBtn(icon: Icons.sports_soccer, label: 'Gol ${_s(l)}',
            color: AppColors.success, disabled: mutating,
            onTap: () => abrir(lId, l, jL, _EventoMode.gol)),
        _ActionBtn(icon: Icons.sports_soccer, label: 'Gol ${_s(v)}',
            color: AppColors.success, disabled: mutating,
            onTap: () => abrir(vId, v, jV, _EventoMode.gol)),
        // Tarjeta
        _ActionBtn(icon: Icons.style_rounded, label: 'Tarjeta ${_s(l)}',
            color: const Color(0xFFB45309), disabled: mutating,
            onTap: () => abrir(lId, l, jL, _EventoMode.tarjeta)),
        _ActionBtn(icon: Icons.style_rounded, label: 'Tarjeta ${_s(v)}',
            color: const Color(0xFFB45309), disabled: mutating,
            onTap: () => abrir(vId, v, jV, _EventoMode.tarjeta)),
        // Cambio
        _ActionBtn(icon: Icons.swap_horiz_rounded, label: 'Cambio ${_s(l)}',
            color: AppColors.primary, disabled: mutating,
            onTap: () => abrir(lId, l, jL, _EventoMode.cambio)),
        _ActionBtn(icon: Icons.swap_horiz_rounded, label: 'Cambio ${_s(v)}',
            color: AppColors.primary, disabled: mutating,
            onTap: () => abrir(vId, v, jV, _EventoMode.cambio)),
        // Falta
        _ActionBtn(icon: Icons.warning_amber_rounded, label: 'Falta ${_s(l)}',
            color: const Color(0xFF6B7280), disabled: mutating,
            onTap: () => abrir(lId, l, jL, _EventoMode.falta)),
        _ActionBtn(icon: Icons.warning_amber_rounded, label: 'Falta ${_s(v)}',
            color: const Color(0xFF6B7280), disabled: mutating,
            onTap: () => abrir(vId, v, jV, _EventoMode.falta)),
        // Lesión
        _ActionBtn(icon: Icons.personal_injury_rounded, label: 'Lesión ${_s(l)}',
            color: const Color(0xFF9F1239), disabled: mutating,
            onTap: () => abrir(lId, l, jL, _EventoMode.lesion)),
        _ActionBtn(icon: Icons.personal_injury_rounded, label: 'Lesión ${_s(v)}',
            color: const Color(0xFF9F1239), disabled: mutating,
            onTap: () => abrir(vId, v, jV, _EventoMode.lesion)),
        // Penal en juego (partido regular)
        _ActionBtn(icon: Icons.sports_score_rounded, label: 'Penal ${_s(l)}',
            color: const Color(0xFF7C3AED), disabled: mutating,
            onTap: () => abrir(lId, l, jL, _EventoMode.penal)),
        _ActionBtn(icon: Icons.sports_score_rounded, label: 'Penal ${_s(v)}',
            color: const Color(0xFF7C3AED), disabled: mutating,
            onTap: () => abrir(vId, v, jV, _EventoMode.penal)),
      ],
    );
  }

  static String _s(String nombre) =>
      nombre.length <= 10 ? nombre : nombre.split(' ').first;
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: color),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Panel tanda de penales ─────────────────────────────────────────────────────

class _TandaPenalesPanel extends StatelessWidget {
  final EnVivoDto data;
  const _TandaPenalesPanel({required this.data});

  @override
  Widget build(BuildContext context) {
    final mutating = context.watch<EnVivoProvider>().mutating;
    final prov     = context.read<EnVivoProvider>();

    final tirosL = data.eventos
        .where((e) => _esTiro(e.tipo) && e.equipoNombre == data.equipoLocalNombre)
        .toList();
    final tirosV = data.eventos
        .where((e) => _esTiro(e.tipo) && e.equipoNombre == data.equipoVisitanteNombre)
        .toList();

    final marcL = tirosL.where((e) => e.tipo == 8).length;
    final marcV = tirosV.where((e) => e.tipo == 8).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_score_rounded, size: 14, color: Color(0xFF7C3AED)),
              SizedBox(width: 6),
              Text('TANDA DE PENALES',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7C3AED),
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          // Marcador de tanda
          Text('$marcL  —  $marcV',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          // Dots local
          _TandaTeamRow(nombre: data.equipoLocalNombre, tiros: tirosL),
          const SizedBox(height: 6),
          // Dots visitante
          _TandaTeamRow(nombre: data.equipoVisitanteNombre, tiros: tirosV),
          const SizedBox(height: 14),
          // Botones de tiro
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  icon: Icons.sports_score_rounded,
                  label: 'Tiro ${_s(data.equipoLocalNombre)}',
                  color: const Color(0xFF7C3AED),
                  disabled: mutating,
                  onTap: () => _mostrarSheetEvento(context,
                      prov: prov,
                      data: data,
                      equipoId: data.equipoLocalId,
                      equipoNombre: data.equipoLocalNombre,
                      jugadores: data.jugadoresLocal,
                      mode: _EventoMode.penal),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.sports_score_rounded,
                  label: 'Tiro ${_s(data.equipoVisitanteNombre)}',
                  color: const Color(0xFF7C3AED),
                  disabled: mutating,
                  onTap: () => _mostrarSheetEvento(context,
                      prov: prov,
                      data: data,
                      equipoId: data.equipoVisitanteId,
                      equipoNombre: data.equipoVisitanteNombre,
                      jugadores: data.jugadoresVisitante,
                      mode: _EventoMode.penal),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static bool _esTiro(int tipo) => tipo == 8 || tipo == 9 || tipo == 10;
  static String _s(String n) => n.length <= 10 ? n : n.split(' ').first;
}

class _TandaTeamRow extends StatelessWidget {
  final String nombre;
  final List<EventoDto> tiros;
  const _TandaTeamRow({required this.nombre, required this.tiros});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(nombre.split(' ').first,
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: tiros.isEmpty
                ? [const Text('—', style: TextStyle(fontSize: 11, color: AppColors.textHint))]
                : tiros.map((t) => _TandaDot(tipo: t.tipo)).toList(),
          ),
        ),
      ],
    );
  }
}

class _TandaDot extends StatelessWidget {
  final int tipo;
  const _TandaDot({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final color = switch (tipo) {
      8 => const Color(0xFF16A34A), // marcado
      9 => const Color(0xFFDC2626), // fallado
      _ => const Color(0xFF7C3AED), // atajado
    };
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Botón terminar ─────────────────────────────────────────────────────────────

class _TerminarButton extends StatelessWidget {
  final EnVivoDto data;
  const _TerminarButton({required this.data});

  @override
  Widget build(BuildContext context) {
    final mutating = context.watch<EnVivoProvider>().mutating;

    return GestureDetector(
      onTap: mutating
          ? null
          : () => _mostrarDialogTerminar(context,
              prov: context.read<EnVivoProvider>(), data: data),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: mutating ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag_rounded, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 7),
              Text('Terminar partido',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Timeline de eventos ────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  final EnVivoDto data;
  const _Timeline({required this.data});

  @override
  Widget build(BuildContext context) {
    final eventos = data.eventos.toList()
      ..sort((a, b) => b.minuto.compareTo(a.minuto));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Incidencias',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(width: 8),
            Text('(${eventos.length})',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ],
        ),
        const SizedBox(height: 8),
        if (eventos.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Center(
              child: Text('Sin incidencias registradas',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: eventos.asMap().entries.map((entry) {
                final idx = entry.key;
                final ev  = entry.value;
                return Column(
                  children: [
                    if (idx > 0)
                      const Divider(
                          height: 0,
                          thickness: 0.5,
                          indent: 14,
                          endIndent: 14,
                          color: AppColors.border),
                    _EventoTile(evento: ev),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _EventoTile extends StatelessWidget {
  final EventoDto evento;
  const _EventoTile({required this.evento});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<EnVivoProvider>();

    return Dismissible(
      key: Key(evento.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.errorBg,
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 20),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Eliminar evento',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                content: Text(
                    'Eliminar "${evento.tipoLabel}" del min. ${evento.minuto}?',
                    style: const TextStyle(fontSize: 13)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Eliminar')),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => prov.eliminarEvento(evento.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text("${evento.minuto}'",
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint)),
            ),
            _EventoIcon(evento: evento),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(evento.tipoLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  if (evento.jugadorNombre != null || evento.equipoNombre != null)
                    Text(
                      [evento.jugadorNombre, evento.equipoNombre]
                          .whereType<String>()
                          .join(' · '),
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                ],
              ),
            ),
            const Icon(Icons.swipe_left_outlined, size: 13, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}

class _EventoIcon extends StatelessWidget {
  final EventoDto evento;
  const _EventoIcon({required this.evento});

  @override
  Widget build(BuildContext context) {
    if (evento.esGol) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.sports_soccer, size: 13, color: AppColors.success),
      );
    }
    if (evento.esTarjeta) {
      final color = evento.esRoja
          ? AppColors.error
          : evento.esAzul
              ? const Color(0xFF1D4ED8)
              : const Color(0xFFF59E0B);
      return Container(
        width: 14,
        height: 18,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      );
    }
    // Penal: dot colored by tipo
    if (evento.tipo == 8 || evento.tipo == 9 || evento.tipo == 10) {
      final color = evento.tipo == 8
          ? const Color(0xFF16A34A)
          : evento.tipo == 9
              ? AppColors.error
              : const Color(0xFF7C3AED);
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.textHint.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.circle, size: 8, color: AppColors.textHint),
    );
  }
}

// ── Sheet: registrar evento ────────────────────────────────────────────────────

enum _EventoMode { gol, tarjeta, cambio, falta, lesion, penal }

void _mostrarSheetEvento(
  BuildContext context, {
  required EnVivoProvider prov,
  required EnVivoDto data,
  required String equipoId,
  required String equipoNombre,
  required List<JugadorEnVivoDto> jugadores,
  required _EventoMode mode,
  bool tieneAzul = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SheetEvento(
      prov: prov,
      data: data,
      equipoId: equipoId,
      equipoNombre: equipoNombre,
      jugadores: jugadores,
      mode: mode,
      tieneAzul: tieneAzul,
    ),
  );
}

class _SheetEvento extends StatefulWidget {
  final EnVivoProvider         prov;
  final EnVivoDto              data;
  final String                 equipoId;
  final String                 equipoNombre;
  final List<JugadorEnVivoDto> jugadores;
  final _EventoMode            mode;
  final bool                   tieneAzul;

  const _SheetEvento({
    required this.prov,
    required this.data,
    required this.equipoId,
    required this.equipoNombre,
    required this.jugadores,
    required this.mode,
    this.tieneAzul = false,
  });

  @override
  State<_SheetEvento> createState() => _SheetEventoState();
}

class _SheetEventoState extends State<_SheetEvento> {
  late int                _tipo;
  JugadorEnVivoDto?       _jugador;      // principal (o Sale en cambio)
  JugadorEnVivoDto?       _jugadorEntra; // solo para cambio
  late final TextEditingController _minCtrl;
  bool    _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tipo = switch (widget.mode) {
      _EventoMode.gol    => 1,
      _EventoMode.tarjeta => 3,
      _EventoMode.cambio  => 6,
      _EventoMode.falta   => 20,
      _EventoMode.lesion  => 18,
      _EventoMode.penal   => 8,
    };
    _minCtrl = TextEditingController(text: '${widget.data.minutoActual}');
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    super.dispose();
  }

  List<_TipoOption> get _opciones => switch (widget.mode) {
    _EventoMode.gol    => const [
        _TipoOption(tipo: 1, label: 'Gol'),
        _TipoOption(tipo: 2, label: 'En propia'),
      ],
    _EventoMode.tarjeta => [
        const _TipoOption(tipo: 3, label: 'Amarilla'),
        const _TipoOption(tipo: 4, label: 'Roja'),
        if (widget.tieneAzul) const _TipoOption(tipo: 5, label: 'Azul'),
      ],
    _EventoMode.penal  => const [
        _TipoOption(tipo: 8,  label: 'Marcado'),
        _TipoOption(tipo: 9,  label: 'Fallado'),
        _TipoOption(tipo: 10, label: 'Atajado'),
      ],
    _ => [], // cambio, falta, lesion: tipo fijo
  };

  String get _titulo => switch (widget.mode) {
    _EventoMode.gol    => 'Gol — ${widget.equipoNombre}',
    _EventoMode.tarjeta => 'Tarjeta — ${widget.equipoNombre}',
    _EventoMode.cambio  => 'Cambio — ${widget.equipoNombre}',
    _EventoMode.falta   => 'Falta — ${widget.equipoNombre}',
    _EventoMode.lesion  => 'Lesión — ${widget.equipoNombre}',
    _EventoMode.penal   => 'Penal — ${widget.equipoNombre}',
  };

  @override
  Widget build(BuildContext context) {
    final kbHeight = MediaQuery.of(context).viewInsets.bottom;
    final opts     = _opciones;
    final esCambio = widget.mode == _EventoMode.cambio;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + kbHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_titulo,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          // Chips de tipo (gol, tarjeta, penal)
          if (opts.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              children: opts
                  .map((opt) => ChoiceChip(
                        label: Text(opt.label),
                        selected: _tipo == opt.tipo,
                        onSelected: (_) => setState(() => _tipo = opt.tipo),
                        tooltip: '',
                        selectedColor: AppColors.primary.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _tipo == opt.tipo
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
          ],
          // Cambio: Sale + Entra
          if (esCambio && widget.jugadores.isNotEmpty) ...[
            const Text('Sale', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 6),
            DropdownButtonFormField<JugadorEnVivoDto>(
              initialValue: _jugador,
              isExpanded: true,
              decoration: _inputDec('Jugador que sale'),
              onChanged: (v) => setState(() => _jugador = v),
              items: [
                const DropdownMenuItem(
                    value: null,
                    child: Text('— Sin seleccionar —',
                        style: TextStyle(fontSize: 13, color: AppColors.textHint))),
                ...widget.jugadores.map((j) => DropdownMenuItem(
                    value: j,
                    child: Text(j.etiqueta, style: const TextStyle(fontSize: 13)))),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Entra', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            const SizedBox(height: 6),
            DropdownButtonFormField<JugadorEnVivoDto>(
              initialValue: _jugadorEntra,
              isExpanded: true,
              decoration: _inputDec('Jugador que entra'),
              onChanged: (v) => setState(() => _jugadorEntra = v),
              items: [
                const DropdownMenuItem(
                    value: null,
                    child: Text('— Sin seleccionar —',
                        style: TextStyle(fontSize: 13, color: AppColors.textHint))),
                ...widget.jugadores.map((j) => DropdownMenuItem(
                    value: j,
                    child: Text(j.etiqueta, style: const TextStyle(fontSize: 13)))),
              ],
            ),
            const SizedBox(height: 14),
          ]
          // Resto de modos: un jugador opcional
          else if (!esCambio && widget.jugadores.isNotEmpty) ...[
            Text(
              widget.mode == _EventoMode.penal ? 'Pateador (opcional)' : 'Jugador (opcional)',
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<JugadorEnVivoDto>(
              initialValue: _jugador,
              isExpanded: true,
              decoration: _inputDec('Sin seleccionar'),
              onChanged: (v) => setState(() => _jugador = v),
              items: [
                const DropdownMenuItem(
                    value: null,
                    child: Text('— Sin jugador —',
                        style: TextStyle(fontSize: 13, color: AppColors.textHint))),
                ...widget.jugadores.map((j) => DropdownMenuItem(
                    value: j,
                    child: Text(j.etiqueta, style: const TextStyle(fontSize: 13)))),
              ],
            ),
            const SizedBox(height: 14),
          ],
          // Minuto
          const Text('Minuto', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _minCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDec('Ej. 25'),
            style: const TextStyle(fontSize: 14),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Registrar evento',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    final minuto = int.tryParse(_minCtrl.text.trim());
    if (minuto == null) {
      setState(() => _error = 'Ingresa un minuto válido.');
      return;
    }
    setState(() { _guardando = true; _error = null; });

    final ok = await widget.prov.agregarEvento(
      equipoId:     widget.equipoId,
      jugadorId:    _jugador?.id,
      jugadorSecId: widget.mode == _EventoMode.cambio ? _jugadorEntra?.id : null,
      tipo:         _tipo,
      minuto:       minuto,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _guardando = false;
        _error = widget.prov.errorMuta ?? 'Error al registrar.';
      });
    }
  }
}

class _TipoOption {
  final int tipo;
  final String label;
  const _TipoOption({required this.tipo, required this.label});
}

InputDecoration _inputDec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.background,
    );

// ── Dialog: terminar partido ───────────────────────────────────────────────────

void _mostrarDialogTerminar(
  BuildContext context, {
  required EnVivoProvider prov,
  required EnVivoDto data,
}) {
  showDialog(
    context: context,
    builder: (_) => _DialogTerminar(prov: prov, data: data),
  );
}

class _DialogTerminar extends StatefulWidget {
  final EnVivoProvider prov;
  final EnVivoDto data;
  const _DialogTerminar({required this.prov, required this.data});

  @override
  State<_DialogTerminar> createState() => _DialogTerminarState();
}

class _DialogTerminarState extends State<_DialogTerminar> {
  late final TextEditingController _localCtrl;
  late final TextEditingController _visitanteCtrl;
  late final TextEditingController _localPenCtrl;
  late final TextEditingController _visitantePenCtrl;
  bool    _prorroga  = false;
  bool    _penales   = false;
  bool    _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _localCtrl       = TextEditingController(text: '${widget.data.golesLocal}');
    _visitanteCtrl   = TextEditingController(text: '${widget.data.golesVisitante}');
    _localPenCtrl    = TextEditingController(text: '0');
    _visitantePenCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _localCtrl.dispose();
    _visitanteCtrl.dispose();
    _localPenCtrl.dispose();
    _visitantePenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.flag_rounded, size: 18, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Text('Terminar partido',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Marcador final',
                style: TextStyle(fontSize: 12, color: AppColors.textHint)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.data.equipoLocalNombre,
                          style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _localCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        decoration: _inputDec('0'),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Text('—',
                      style: TextStyle(
                          fontSize: 20,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w300)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.data.equipoVisitanteNombre,
                          style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _visitanteCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        decoration: _inputDec('0'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SwitchRow(
              label: 'Hubo prórroga',
              value: _prorroga,
              onChanged: (v) => setState(() => _prorroga = v),
            ),
            const SizedBox(height: 6),
            _SwitchRow(
              label: 'Hubo tanda de penales',
              value: _penales,
              onChanged: (v) => setState(() => _penales = v),
            ),
            if (_penales) ...[
              const SizedBox(height: 12),
              const Text('Penales',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _localPenCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      decoration: _inputDec('0'),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('—',
                        style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w300)),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _visitantePenCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      decoration: _inputDec('0'),
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            minimumSize: const Size(100, 40),
          ),
          onPressed: _guardando ? null : _terminar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Terminar',
                  style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Future<void> _terminar() async {
    final gl = int.tryParse(_localCtrl.text.trim());
    final gv = int.tryParse(_visitanteCtrl.text.trim());
    final lp = int.tryParse(_localPenCtrl.text.trim());
    final vp = int.tryParse(_visitantePenCtrl.text.trim());

    if (gl == null || gv == null) {
      setState(() => _error = 'Ingresa el marcador final.');
      return;
    }
    if (_penales && (lp == null || vp == null)) {
      setState(() => _error = 'Ingresa los penales.');
      return;
    }

    setState(() { _guardando = true; _error = null; });

    final ok = await widget.prov.terminar(
      golesLocal:            gl,
      golesVisitante:        gv,
      tuvoProrroga:          _prorroga,
      tuvoPenales:           _penales,
      golesLocalPenales:     _penales ? lp : null,
      golesVisitantePenales: _penales ? vp : null,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      setState(() {
        _guardando = false;
        _error = widget.prov.errorMuta ?? 'Error al terminar.';
      });
    }
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
