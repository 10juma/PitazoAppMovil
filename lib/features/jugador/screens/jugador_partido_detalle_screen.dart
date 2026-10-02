import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../shared/enums/estado_partido.dart';
import '../data/jugador_repository.dart';

/// Vista de solo lectura del partido para el Jugador — marcador final + minuto a minuto.
class JugadorPartidoDetalleScreen extends StatefulWidget {
  final String partidoId;
  const JugadorPartidoDetalleScreen({super.key, required this.partidoId});

  @override
  State<JugadorPartidoDetalleScreen> createState() => _JugadorPartidoDetalleScreenState();
}

class _JugadorPartidoDetalleScreenState extends State<JugadorPartidoDetalleScreen> {
  final _repo = JugadorRepository();

  PartidoCompletoDto? _partido;
  bool    _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await _repo.obtenerPartido(widget.partidoId);
      if (mounted) setState(() { _partido = p; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = RolePalettes.accentForRol('Jugador');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Detalle del partido', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(mensaje: _error!, onRetry: _cargar)
              : _partido == null
                  ? const SizedBox()
                  : RefreshIndicator(
                      color: accent,
                      onRefresh: _cargar,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          _MarcadorCard(p: _partido!, accent: accent),
                          const SizedBox(height: 12),
                          _InfoCards(p: _partido!),
                          const SizedBox(height: 12),
                          _EventosCard(eventos: _partido!.eventos),
                        ]),
                      ),
                    ),
    );
  }
}

// ── Marcador ──────────────────────────────────────────────────────────────────

class _MarcadorCard extends StatelessWidget {
  final PartidoCompletoDto p;
  final Color    accent;
  const _MarcadorCard({required this.p, required this.accent});

  @override
  Widget build(BuildContext context) {
    final enCurso   = p.estado == EstadoPartido.enCurso;
    final mostrarMarcador = p.estado != EstadoPartido.programado;

    final (bg, fg) = switch (p.estado) {
      EstadoPartido.enCurso    => (const Color(0xFFFEE2E2), AppColors.error),
      EstadoPartido.programado => (const Color(0xFFF0FDF4), accent),
      _                        => (AppColors.border, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Text(
            enCurso ? '● EN VIVO' : p.estadoLabel.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
          ),
        ),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Column(children: [
            Text(p.equipoLocalNombre, textAlign: TextAlign.center, maxLines: 2,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Local', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
          ])),
          SizedBox(width: 90, child: mostrarMarcador
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${p.golesLocal}',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: accent)),
                  const Text(' - ', style: TextStyle(fontSize: 22, color: AppColors.textHint)),
                  Text('${p.golesVisitante}',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: accent)),
                ])
              : const Text('vs', style: TextStyle(fontSize: 16, color: AppColors.textHint))),
          Expanded(child: Column(children: [
            Text(p.equipoVisitanteNombre, textAlign: TextAlign.center, maxLines: 2,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Visitante', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
          ])),
        ]),
      ]),
    );
  }
}

// ── Info cards ────────────────────────────────────────────────────────────────

class _InfoCards extends StatelessWidget {
  final PartidoCompletoDto p;
  const _InfoCards({required this.p});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE d MMM · HH:mm', 'es_MX');
    return Wrap(spacing: 8, runSpacing: 8, children: [
      _InfoChip(label: 'Fecha y hora', value: fmt.format(p.fechaHora)),
      if (p.canchaNombre != null) _InfoChip(label: 'Cancha', value: p.canchaNombre!),
      if (p.arbitroNombre != null) _InfoChip(label: 'Árbitro', value: p.arbitroNombre!),
      _InfoChip(label: 'Liga · Fase', value: '${p.ligaNombre}\n${p.faseNombre} · J${p.jornadaNumero}'),
    ]);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.4)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    );
  }
}

// ── Minuto a minuto ───────────────────────────────────────────────────────────

class _EventosCard extends StatelessWidget {
  final List<EventoPartidoDto> eventos;
  const _EventosCard({required this.eventos});

  @override
  Widget build(BuildContext context) {
    final ordenados = [...eventos]..sort((a, b) => b.minuto.compareTo(a.minuto));
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Text('⏱️ Minuto a minuto',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ),
        if (ordenados.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Text('Sin eventos registrados para este partido.',
                style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          )
        else
          ...ordenados.map((ev) => Column(children: [
            const Divider(height: 0, thickness: 0.5, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 32, child: Text("${ev.minuto}'", textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textHint))),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ev.tipoLabel,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  if (ev.jugadorNombre != null)
                    Text('${ev.equipoNombre ?? ''} — ${ev.jugadorNombre}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textHint))
                  else if (ev.equipoNombre != null)
                    Text(ev.equipoNombre!, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                ])),
              ]),
            ),
          ])),
        const SizedBox(height: 4),
      ]),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorBody({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 36, color: AppColors.textHint),
        const SizedBox(height: 10),
        Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ]),
    ),
  );
}
