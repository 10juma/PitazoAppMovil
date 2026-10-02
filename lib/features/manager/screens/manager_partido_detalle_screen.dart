import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../shared/enums/estado_partido.dart';
import '../data/manager_repository.dart';
import '../providers/manager_provider.dart';

/// Vista de solo lectura del partido para el Manager — réplica de Manager/Partidos/General.cshtml.
/// A diferencia de Staff/Árbitro, el Manager NO puede editar marcador ni eventos.
class ManagerPartidoDetalleScreen extends StatefulWidget {
  final String partidoId;
  const ManagerPartidoDetalleScreen({super.key, required this.partidoId});

  @override
  State<ManagerPartidoDetalleScreen> createState() => _ManagerPartidoDetalleScreenState();
}

class _ManagerPartidoDetalleScreenState extends State<ManagerPartidoDetalleScreen> {
  final _repo = ManagerRepository();

  PartidoCompletoDto?      _partido;
  Map<String, dynamic>?    _calificacion;
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
      Map<String, dynamic>? cal;
      if (p.estado == EstadoPartido.terminado && p.arbitroId != null && mounted) {
        final equipoId = context.read<ManagerProvider>().equipoActivo?.equipoId;
        if (equipoId != null) {
          cal = await _repo.obtenerCalificacionArbitro(equipoId, widget.partidoId);
        }
      }
      if (mounted) setState(() { _partido = p; _calificacion = cal; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent  = RolePalettes.accentForRol('Manager');
    final equipoId = context.watch<ManagerProvider>().equipoActivo?.equipoId;

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
                          if (equipoId != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(children: [
                                Expanded(child: OutlinedButton.icon(
                                  icon: const Icon(Icons.people_outline, size: 14),
                                  label: const Text('Confirmaciones', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: accent,
                                    side: BorderSide(color: accent.withValues(alpha: 0.4)),
                                  ),
                                  onPressed: () => context.push(
                                    '/manager/confirmaciones/$equipoId/${widget.partidoId}',
                                  ),
                                )),
                                const SizedBox(width: 8),
                                Expanded(child: OutlinedButton.icon(
                                  icon: const Icon(Icons.sports_soccer_outlined, size: 14),
                                  label: const Text('Alineación', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: accent,
                                    side: BorderSide(color: accent.withValues(alpha: 0.4)),
                                  ),
                                  onPressed: () => context.push(
                                    '/manager/alineacion/$equipoId/${widget.partidoId}',
                                  ),
                                )),
                              ]),
                            ),
                          _MarcadorCard(p: _partido!, accent: accent, equipoId: equipoId),
                          const SizedBox(height: 12),
                          _InfoCards(p: _partido!),
                          if (_partido!.cuotaMonto != null && equipoId != null) ...[
                            const SizedBox(height: 12),
                            _CuotaCard(p: _partido!, equipoId: equipoId, accent: accent),
                          ],
                          const SizedBox(height: 12),
                          _EventosCard(eventos: _partido!.eventos),
                          if (_partido!.estado == EstadoPartido.terminado &&
                              _partido!.arbitroId != null && equipoId != null) ...[
                            const SizedBox(height: 12),
                            _CalificarArbitroInline(
                              equipoId: equipoId,
                              partidoId: widget.partidoId,
                              arbitroNombre: _partido!.arbitroNombre,
                              calificacionInicial: _calificacion?['calificacion'] as int?,
                              comentarioInicial: _calificacion?['comentario'] as String?,
                            ),
                          ],
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
  final String?  equipoId;
  const _MarcadorCard({required this.p, required this.accent, required this.equipoId});

  @override
  Widget build(BuildContext context) {
    final enCurso   = p.estado == EstadoPartido.enCurso;
    final mostrarMarcador = p.estado != EstadoPartido.programado;
    final esLocal = equipoId != null && equipoId == p.equipoLocalId;

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
            Text('Local${esLocal ? ' (Tu equipo)' : ''}',
                style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ])),
          SizedBox(width: 90, child: mostrarMarcador
              ? Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${p.golesLocal}',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: accent)),
                    const Text(' - ', style: TextStyle(fontSize: 22, color: AppColors.textHint)),
                    Text('${p.golesVisitante}',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: accent)),
                  ]),
                ])
              : const Text('vs', style: TextStyle(fontSize: 16, color: AppColors.textHint))),
          Expanded(child: Column(children: [
            Text(p.equipoVisitanteNombre, textAlign: TextAlign.center, maxLines: 2,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Visitante${!esLocal && equipoId != null ? ' (Tu equipo)' : ''}',
                style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
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

// ── Cuota ─────────────────────────────────────────────────────────────────────

class _CuotaCard extends StatelessWidget {
  final PartidoCompletoDto p;
  final String equipoId;
  final Color  accent;
  const _CuotaCard({required this.p, required this.equipoId, required this.accent});

  @override
  Widget build(BuildContext context) {
    final esLocal   = equipoId == p.equipoLocalId;
    final miPago    = esLocal ? p.pagoEquipoLocal : p.pagoEquipoVisitante;
    final rivalPago = esLocal ? p.pagoEquipoVisitante : p.pagoEquipoLocal;
    final fmtPesos  = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Cuota del partido',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(fmtPesos.format(p.cuotaMonto), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(children: [
          Icon(miPago ? Icons.check_circle : Icons.cancel, size: 14, color: miPago ? AppColors.success : AppColors.error),
          const SizedBox(width: 6),
          Text(miPago ? 'Pagada' : 'Pendiente de pago',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: miPago ? AppColors.success : AppColors.error)),
        ]),
        const SizedBox(height: 4),
        Text('Rival: ${rivalPago ? 'Pagada' : 'Pendiente'}',
            style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
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

// ── Calificar árbitro (inline) ─────────────────────────────────────────────────

class _CalificarArbitroInline extends StatefulWidget {
  final String  equipoId;
  final String  partidoId;
  final String? arbitroNombre;
  final int?    calificacionInicial;
  final String? comentarioInicial;
  const _CalificarArbitroInline({
    required this.equipoId, required this.partidoId, this.arbitroNombre,
    this.calificacionInicial, this.comentarioInicial,
  });

  @override
  State<_CalificarArbitroInline> createState() => _CalificarArbitroInlineState();
}

class _CalificarArbitroInlineState extends State<_CalificarArbitroInline> {
  final _repo = ManagerRepository();
  late int    _stars   = widget.calificacionInicial ?? 0;
  late String _comment = widget.comentarioInicial ?? '';
  bool _loading = false;

  Future<void> _guardar() async {
    if (_stars == 0) return;
    setState(() => _loading = true);
    final err = await _repo.calificarArbitro(
      widget.equipoId, widget.partidoId,
      calificacion: _stars,
      comentario:   _comment.trim().isEmpty ? null : _comment.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Calificación guardada. ¡Gracias!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('⭐ Calificar árbitro',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          if (widget.arbitroNombre != null)
            Text(widget.arbitroNombre!, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(
          icon: Icon(i < _stars ? Icons.star : Icons.star_border, color: Colors.amber.shade600, size: 28),
          onPressed: () => setState(() => _stars = i + 1),
        ))),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Comentario (opcional)',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          maxLines: 2,
          initialValue: _comment,
          onChanged: (v) => _comment = v,
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: (_stars == 0 || _loading) ? null : _guardar,
          child: _loading
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Guardar calificación'),
        )),
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
