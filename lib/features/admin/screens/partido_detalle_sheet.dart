import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/env.dart';
import '../../../models/partido_detalle_dto.dart';
import '../../../models/partido_resumen_dto.dart';
import '../../../shared/enums/estado_partido.dart';
import '../../staff/data/staff_partidos_repository.dart';

/// Abre el panel de detalle del partido como bottom sheet.
Future<bool> showPartidoDetalleSheet(
  BuildContext context,
  PartidoResumenDto resumen, {
  bool    esAdmin    = true,
  String? tenantSlug,
}) async {
  final repo   = StaffPartidosRepository();
  final result = await showModalBottomSheet<bool>(
    context:            context,
    isScrollControlled: true,
    useSafeArea:        true,
    backgroundColor:    Colors.transparent,
    builder: (_) => _DetalleSheet(
      id:         resumen.id,
      repo:       repo,
      esAdmin:    esAdmin,
      tenantSlug: tenantSlug,
    ),
  );
  return result ?? false;
}

// ─── Sheet raíz ─────────────────────────────────────────────────────────────

class _DetalleSheet extends StatefulWidget {
  const _DetalleSheet({
    required this.id,
    required this.repo,
    required this.esAdmin,
    this.tenantSlug,
  });
  final String                   id;
  final StaffPartidosRepository  repo;
  final bool                     esAdmin;
  final String?                  tenantSlug;

  @override
  State<_DetalleSheet> createState() => _DetalleSheetState();
}

class _DetalleSheetState extends State<_DetalleSheet> {
  PartidoDetalleDto?    _detalle;
  List<CanchaSimpleDto> _canchas = [];
  bool                  _cargando = true;
  String?               _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final results = await Future.wait([
        widget.repo.obtenerDetalle(widget.id),
        widget.repo.listarCanchas(),
      ]);
      if (!mounted) return;
      setState(() {
        _detalle  = results[0] as PartidoDetalleDto;
        _canchas  = results[1] as List<CanchaSimpleDto>;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Error al cargar datos del partido.'; _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:     MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _DragHandle(),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorPanel(mensaje: _error!, onReintentar: _cargar)
                    : _ContenidoSheet(
                        detalle:    _detalle!,
                        canchas:    _canchas,
                        repo:       widget.repo,
                        onRefresh:  _cargar,
                        esAdmin:    widget.esAdmin,
                        tenantSlug: widget.tenantSlug,
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Contenido del sheet ────────────────────────────────────────────────────

class _ContenidoSheet extends StatelessWidget {
  const _ContenidoSheet({
    required this.detalle,
    required this.canchas,
    required this.repo,
    required this.onRefresh,
    required this.esAdmin,
    this.tenantSlug,
  });

  final PartidoDetalleDto       detalle;
  final List<CanchaSimpleDto>   canchas;
  final StaffPartidosRepository repo;
  final VoidCallback            onRefresh;
  final bool                    esAdmin;
  final String?                 tenantSlug;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Contexto(detalle: detalle),
          const SizedBox(height: 16),
          _Enfrentamiento(detalle: detalle),
          const SizedBox(height: 12),
          _InfoRow(detalle: detalle),
          const Divider(height: 32),
          _SeccionesAccion(
            detalle:    detalle,
            canchas:    canchas,
            repo:       repo,
            onRefresh:  onRefresh,
            esAdmin:    esAdmin,
            tenantSlug: tenantSlug,
          ),
        ],
      ),
    );
  }
}

// ─── Drag handle ────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Center(
      child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(
          color:        Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );
}

// ─── Contexto: Liga › Temporada · Jornada + estado badge ───────────────────

class _Contexto extends StatelessWidget {
  const _Contexto({required this.detalle});
  final PartidoDetalleDto detalle;

  @override
  Widget build(BuildContext context) {
    final ctx = [
      if (detalle.ligaNombre.isNotEmpty)      detalle.ligaNombre,
      if (detalle.temporadaNombre.isNotEmpty) detalle.temporadaNombre,
      if (detalle.faseNombre.isNotEmpty)      detalle.faseNombre,
      if (detalle.jornadaNombre.isNotEmpty)   detalle.jornadaNombre,
    ].join(' · ');

    return Row(
      children: [
        Expanded(
          child: Text(
            ctx,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ),
        const SizedBox(width: 8),
        _EstadoBadge(estado: detalle.estado, label: detalle.estadoLabel),
      ],
    );
  }
}

// ─── Enfrentamiento ─────────────────────────────────────────────────────────

class _Enfrentamiento extends StatelessWidget {
  const _Enfrentamiento({required this.detalle});
  final PartidoDetalleDto detalle;

  @override
  Widget build(BuildContext context) {
    final colorLocal    = _hexColor(detalle.equipoLocalColor)    ?? Colors.blue;
    final colorVisitante= _hexColor(detalle.equipoVisitanteColor)?? Colors.orange;
    final terminado     = detalle.estado == EstadoPartido.terminado
                       || detalle.estado == EstadoPartido.enCurso;

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              CircleAvatar(backgroundColor: colorLocal, radius: 20,
                child: Text(detalle.equipoLocalNombre.isNotEmpty ? detalle.equipoLocalNombre[0] : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Text(detalle.equipoLocalNombre,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
        if (terminado) ...[
          Text('${detalle.golesLocal}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('–', style: TextStyle(fontSize: 24, color: Colors.grey)),
          ),
          Text('${detalle.golesVisitante}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('vs', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ),
        Expanded(
          child: Column(
            children: [
              CircleAvatar(backgroundColor: colorVisitante, radius: 20,
                child: Text(detalle.equipoVisitanteNombre.isNotEmpty ? detalle.equipoVisitanteNombre[0] : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Text(detalle.equipoVisitanteNombre,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Info row: fecha, cancha, árbitro ───────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.detalle});
  final PartidoDetalleDto detalle;

  @override
  Widget build(BuildContext context) {
    final f = detalle.fechaHora;
    final meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    final fecha = '${f.day} ${meses[f.month-1]} ${f.year} · '
                  '${f.hour.toString().padLeft(2,'0')}:${f.minute.toString().padLeft(2,'0')}';

    return Wrap(
      spacing: 16, runSpacing: 4,
      children: [
        _Chip(icon: Icons.calendar_today_outlined, text: fecha),
        if (detalle.canchaNombre != null)
          _Chip(icon: Icons.sports_soccer_outlined, text: detalle.canchaNombre!),
        if (detalle.arbitroNombre != null)
          _Chip(icon: Icons.person_outline, text: detalle.arbitroNombre!),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});
  final IconData icon;
  final String   text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: Colors.grey[600]),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
    ],
  );
}

// ─── Secciones de acción según estado ───────────────────────────────────────

class _SeccionesAccion extends StatelessWidget {
  const _SeccionesAccion({
    required this.detalle,
    required this.canchas,
    required this.repo,
    required this.onRefresh,
    required this.esAdmin,
    this.tenantSlug,
  });

  final PartidoDetalleDto       detalle;
  final List<CanchaSimpleDto>   canchas;
  final StaffPartidosRepository repo;
  final VoidCallback            onRefresh;
  final bool                    esAdmin;
  final String?                 tenantSlug;

  @override
  Widget build(BuildContext context) {
    return switch (detalle.estado) {
      EstadoPartido.programado  => _AccionesProgamado(detalle: detalle, canchas: canchas, repo: repo, onRefresh: onRefresh, esAdmin: esAdmin),
      EstadoPartido.enCurso     => _AccionesEnCurso(detalle: detalle, repo: repo, onRefresh: onRefresh, esAdmin: esAdmin, tenantSlug: tenantSlug),
      EstadoPartido.terminado   => _AccionesTerminado(detalle: detalle, repo: repo, onRefresh: onRefresh),
      EstadoPartido.suspendido  => _AccionesSuspendido(detalle: detalle, repo: repo, onRefresh: onRefresh, esAdmin: esAdmin),
      EstadoPartido.cancelado   => _AccionesCancelado(detalle: detalle, repo: repo, onRefresh: onRefresh, esAdmin: esAdmin),
    };
  }
}

// ─── Programado ─────────────────────────────────────────────────────────────

class _AccionesProgamado extends StatelessWidget {
  const _AccionesProgamado({
    required this.detalle,
    required this.canchas,
    required this.repo,
    required this.onRefresh,
    required this.esAdmin,
  });

  final PartidoDetalleDto       detalle;
  final List<CanchaSimpleDto>   canchas;
  final StaffPartidosRepository repo;
  final VoidCallback            onRefresh;
  final bool                    esAdmin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FormReprogramar(detalle: detalle, canchas: canchas, repo: repo, onGuardado: onRefresh),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _abrirIniciar(context),
          icon:  const Icon(Icons.play_arrow_rounded),
          label: const Text('Iniciar partido'),
          style: FilledButton.styleFrom(backgroundColor: Colors.green[700]),
        ),
        const SizedBox(height: 8),
        _BotonesCambiarEstado(
          detalle:   detalle,
          repo:      repo,
          onRefresh: onRefresh,
          estados:   const ['Suspendido', 'Cancelado'],
          esAdmin:   esAdmin,
        ),
      ],
    );
  }

  void _abrirIniciar(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      useSafeArea:        true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _IniciarSheet(detalle: detalle, repo: repo, onIniciado: onRefresh),
    );
  }
}

// ─── En Curso ───────────────────────────────────────────────────────────────

class _AccionesEnCurso extends StatefulWidget {
  const _AccionesEnCurso({
    required this.detalle,
    required this.repo,
    required this.onRefresh,
    required this.esAdmin,
    this.tenantSlug,
  });
  final PartidoDetalleDto       detalle;
  final StaffPartidosRepository repo;
  final VoidCallback            onRefresh;
  final bool                    esAdmin;
  final String?                 tenantSlug;

  @override
  State<_AccionesEnCurso> createState() => _AccionesEnCursoState();
}

class _AccionesEnCursoState extends State<_AccionesEnCurso> {
  late bool _pagoLocal;
  late bool _pagoVisitante;
  bool      _guardandoCuota = false;

  @override
  void initState() {
    super.initState();
    _pagoLocal     = widget.detalle.pagoEquipoLocal;
    _pagoVisitante = widget.detalle.pagoEquipoVisitante;
  }

  Future<void> _toggleCuota(bool local, bool valor) async {
    final nuevoLocal     = local ? valor : _pagoLocal;
    final nuevoVisitante = local ? _pagoVisitante : valor;
    setState(() {
      if (local) { _pagoLocal = valor; } else { _pagoVisitante = valor; }
      _guardandoCuota = true;
    });
    try {
      await widget.repo.marcarPagoCuota(
        widget.detalle.id,
        pagoLocal:     nuevoLocal,
        pagoVisitante: nuevoVisitante,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (local) { _pagoLocal = !valor; } else { _pagoVisitante = !valor; }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar cuota'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _guardandoCuota = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneCuota = (widget.detalle.cuotaMonto ?? 0) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            context.push('/staff/envivo/${widget.detalle.id}');
          },
          icon:  const Icon(Icons.live_tv_rounded),
          label: const Text('Ver en vivo'),
          style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
        ),
        if (widget.tenantSlug != null && widget.tenantSlug!.isNotEmpty) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final url = Uri.parse(
                '${Env.webUrl}/c/${widget.tenantSlug}/partidos/${widget.detalle.id}',
              );
              if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
            },
            icon:  const Icon(Icons.open_in_new, size: 16),
            label: const Text('Ver vista pública'),
          ),
        ],
        if (tieneCuota) ...[
          const SizedBox(height: 12),
          _CuotaPanel(
            cuotaMonto:     widget.detalle.cuotaMonto!,
            nombreLocal:    widget.detalle.equipoLocalNombre,
            nombreVisitante:widget.detalle.equipoVisitanteNombre,
            pagoLocal:      _pagoLocal,
            pagoVisitante:  _pagoVisitante,
            guardando:      _guardandoCuota,
            onToggleLocal:  (v) => _toggleCuota(true, v),
            onToggleVisitante: (v) => _toggleCuota(false, v),
          ),
        ],
        const SizedBox(height: 8),
        _BotonesCambiarEstado(
          detalle:   widget.detalle,
          repo:      widget.repo,
          onRefresh: widget.onRefresh,
          estados:   const ['Suspendido', 'Cancelado'],
          esAdmin:   widget.esAdmin,
        ),
      ],
    );
  }
}

class _CuotaPanel extends StatelessWidget {
  const _CuotaPanel({
    required this.cuotaMonto,
    required this.nombreLocal,
    required this.nombreVisitante,
    required this.pagoLocal,
    required this.pagoVisitante,
    required this.guardando,
    required this.onToggleLocal,
    required this.onToggleVisitante,
  });
  final double   cuotaMonto;
  final String   nombreLocal;
  final String   nombreVisitante;
  final bool     pagoLocal;
  final bool     pagoVisitante;
  final bool     guardando;
  final void Function(bool) onToggleLocal;
  final void Function(bool) onToggleVisitante;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.payments_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              'Cuota: \$${cuotaMonto.toStringAsFixed(cuotaMonto.truncateToDouble() == cuotaMonto ? 0 : 2)} por equipo',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            if (guardando) ...[
              const SizedBox(width: 8),
              const SizedBox(width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ]),
          const SizedBox(height: 10),
          _TogglePago(
            label:    nombreLocal,
            pagado:   pagoLocal,
            onToggle: guardando ? null : onToggleLocal,
          ),
          const SizedBox(height: 6),
          _TogglePago(
            label:    nombreVisitante,
            pagado:   pagoVisitante,
            onToggle: guardando ? null : onToggleVisitante,
          ),
        ],
      ),
    ),
  );
}

class _TogglePago extends StatelessWidget {
  const _TogglePago({required this.label, required this.pagado, required this.onToggle});
  final String   label;
  final bool     pagado;
  final void Function(bool)? onToggle;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onToggle == null ? null : () => onToggle!(!pagado),
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:        pagado ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: pagado ? Colors.green[200]! : Colors.red[200]!),
      ),
      child: Row(children: [
        Icon(
          pagado ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 16,
          color: pagado ? Colors.green[700] : Colors.red[700],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: pagado ? Colors.green[800] : Colors.red[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          pagado ? 'Pagó' : 'Pendiente',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: pagado ? Colors.green[700] : Colors.red[700],
          ),
        ),
      ]),
    ),
  );
}

// ─── Terminado ──────────────────────────────────────────────────────────────

class _AccionesTerminado extends StatelessWidget {
  const _AccionesTerminado({required this.detalle, required this.repo, required this.onRefresh});
  final PartidoDetalleDto       detalle;
  final StaffPartidosRepository repo;
  final VoidCallback            onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FormResultado(detalle: detalle, repo: repo, onGuardado: onRefresh),
        if (detalle.tieneArbitro) ...[
          const SizedBox(height: 16),
          _EvaluacionArbitroPanel(
            partidoId:     detalle.id,
            arbitroNombre: detalle.arbitroNombre!,
            repo:          repo,
          ),
        ],
      ],
    );
  }
}

// ─── Suspendido / Cancelado ─────────────────────────────────────────────────

class _AccionesSuspendido extends StatelessWidget {
  const _AccionesSuspendido({required this.detalle, required this.repo, required this.onRefresh, required this.esAdmin});
  final PartidoDetalleDto       detalle;
  final StaffPartidosRepository repo;
  final VoidCallback            onRefresh;
  final bool                    esAdmin;

  @override
  Widget build(BuildContext context) {
    return _BotonesCambiarEstado(
      detalle:   detalle,
      repo:      repo,
      onRefresh: onRefresh,
      estados:   [if (esAdmin) 'Programado', 'Cancelado'],
      esAdmin:   esAdmin,
    );
  }
}

class _AccionesCancelado extends StatelessWidget {
  const _AccionesCancelado({required this.detalle, required this.repo, required this.onRefresh, required this.esAdmin});
  final PartidoDetalleDto       detalle;
  final StaffPartidosRepository repo;
  final VoidCallback            onRefresh;
  final bool                    esAdmin;

  @override
  Widget build(BuildContext context) {
    if (!esAdmin) return const SizedBox.shrink();
    return _BotonesCambiarEstado(
      detalle:   detalle,
      repo:      repo,
      onRefresh: onRefresh,
      estados:   const ['Programado'],
      esAdmin:   esAdmin,
    );
  }
}

// ─── Botones cambiar estado ──────────────────────────────────────────────────

class _BotonesCambiarEstado extends StatefulWidget {
  const _BotonesCambiarEstado({
    required this.detalle,
    required this.repo,
    required this.onRefresh,
    required this.estados,
    required this.esAdmin,
  });
  final PartidoDetalleDto       detalle;
  final StaffPartidosRepository repo;
  final VoidCallback            onRefresh;
  final List<String>            estados;
  final bool                    esAdmin;

  @override
  State<_BotonesCambiarEstado> createState() => _BotonesCambiarEstadoState();
}

class _BotonesCambiarEstadoState extends State<_BotonesCambiarEstado> {
  bool _guardando = false;

  Future<void> _cambiar(String estado) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cambiar a $estado'),
        content: Text('¿Confirmas cambiar el estado del partido a $estado?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _guardando = true);
    try {
      if (widget.esAdmin) {
        await widget.repo.cambiarEstado(widget.detalle.id, estado);
      } else {
        await widget.repo.cambiarEstadoStaff(widget.detalle.id, estado);
      }
      if (!mounted) return;
      widget.onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado cambiado a $estado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cambiar estado'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.estados.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8, runSpacing: 8,
      children: widget.estados.map((e) => OutlinedButton(
        onPressed: _guardando ? null : () => _cambiar(e),
        style: OutlinedButton.styleFrom(
          foregroundColor: _colorEstado(e),
          side: BorderSide(color: _colorEstado(e)),
        ),
        child: Text(e),
      )).toList(),
    );
  }

  Color _colorEstado(String e) => switch (e) {
    'Suspendido' => Colors.orange[700]!,
    'Cancelado'  => Colors.red[700]!,
    'Programado' => Colors.blue[700]!,
    _            => Colors.grey[700]!,
  };
}

// ─── Formulario Reprogramar ─────────────────────────────────────────────────

class _FormReprogramar extends StatefulWidget {
  const _FormReprogramar({
    required this.detalle,
    required this.canchas,
    required this.repo,
    required this.onGuardado,
  });
  final PartidoDetalleDto       detalle;
  final List<CanchaSimpleDto>   canchas;
  final StaffPartidosRepository repo;
  final VoidCallback            onGuardado;

  @override
  State<_FormReprogramar> createState() => _FormReprogramarState();
}

class _FormReprogramarState extends State<_FormReprogramar> {
  late DateTime         _fecha;
  late TimeOfDay        _hora;
  CanchaSimpleDto?      _cancha;
  bool                  _guardando = false;
  bool                  _expandido = false;

  @override
  void initState() {
    super.initState();
    _fecha  = widget.detalle.fechaHora;
    _hora   = TimeOfDay.fromDateTime(widget.detalle.fechaHora);
    _cancha = widget.canchas
        .where((c) => c.id == widget.detalle.canchaId).firstOrNull;
  }

  Future<void> _guardar() async {
    final fechaHora = DateTime(
      _fecha.year, _fecha.month, _fecha.day, _hora.hour, _hora.minute,
    );
    setState(() => _guardando = true);
    try {
      await widget.repo.actualizarGenerales(
        widget.detalle.id,
        fechaHora: fechaHora,
        canchaId:  _cancha?.id,
      );
      if (!mounted) return;
      widget.onGuardado();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partido reprogramado')),
      );
      setState(() => _expandido = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al reprogramar'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    final fechaStr = '${_fecha.day} ${meses[_fecha.month-1]} ${_fecha.year}';
    final horaStr  = '${_hora.hour.toString().padLeft(2,'0')}:${_hora.minute.toString().padLeft(2,'0')}';

    return Card(
      child: ExpansionTile(
        initiallyExpanded: _expandido,
        title: const Text('Reprogramar', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$fechaStr  $horaStr${_cancha != null ? ' · ${_cancha!.nombre}' : ''}',
          style: const TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CampoFecha(
                        label: 'Fecha',
                        valor: fechaStr,
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _fecha,
                            firstDate: DateTime(2020),
                            lastDate:  DateTime(2030),
                          );
                          if (d != null) setState(() => _fecha = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CampoFecha(
                        label: 'Hora',
                        valor: horaStr,
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _hora,
                          );
                          if (t != null) setState(() => _hora = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.canchas.isNotEmpty)
                  _CampoPicker<CanchaSimpleDto>(
                    label:     'Cancha',
                    valor:     _cancha?.nombre ?? 'Sin cancha asignada',
                    opciones:  widget.canchas,
                    etiqueta:  (c) => c.nombre,
                    onSeleccion: (c) => setState(() => _cancha = c),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formulario Resultado ────────────────────────────────────────────────────

class _FormResultado extends StatefulWidget {
  const _FormResultado({required this.detalle, required this.repo, required this.onGuardado});
  final PartidoDetalleDto       detalle;
  final StaffPartidosRepository repo;
  final VoidCallback            onGuardado;

  @override
  State<_FormResultado> createState() => _FormResultadoState();
}

class _FormResultadoState extends State<_FormResultado> {
  late int   _golesLocal;
  late int   _golesVisitante;
  late bool  _prorroga;
  late bool  _penales;
  late int   _golesLocalPenales;
  late int   _golesVisitantePenales;
  bool       _guardando = false;

  @override
  void initState() {
    super.initState();
    _golesLocal            = widget.detalle.golesLocal;
    _golesVisitante        = widget.detalle.golesVisitante;
    _prorroga              = widget.detalle.tuvoProrroga;
    _penales               = widget.detalle.tuvoPenales;
    _golesLocalPenales     = widget.detalle.golesLocalPenales    ?? 0;
    _golesVisitantePenales = widget.detalle.golesVisitantePenales ?? 0;
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await widget.repo.registrarResultado(
        widget.detalle.id,
        golesLocal:            _golesLocal,
        golesVisitante:        _golesVisitante,
        tuvoProrroga:          _prorroga,
        tuvoPenales:           _penales,
        golesLocalPenales:     _penales ? _golesLocalPenales     : null,
        golesVisitantePenales: _penales ? _golesVisitantePenales : null,
      );
      if (!mounted) return;
      widget.onGuardado();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resultado guardado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar resultado'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloqueado = widget.detalle.resultadoBloqueado;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Resultado', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ContadorGoles(
                    label:      widget.detalle.equipoLocalNombre,
                    valor:      _golesLocal,
                    deshabilitado: bloqueado,
                    onChange:   bloqueado ? null : (v) => setState(() => _golesLocal = v),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('–', style: TextStyle(fontSize: 28)),
                ),
                Expanded(
                  child: _ContadorGoles(
                    label:      widget.detalle.equipoVisitanteNombre,
                    valor:      _golesVisitante,
                    deshabilitado: bloqueado,
                    onChange:   bloqueado ? null : (v) => setState(() => _golesVisitante = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value:    _prorroga,
              onChanged: bloqueado ? null : (v) => setState(() {
                _prorroga = v;
                if (!v) _penales = false;
              }),
              title:     const Text('Tuvo prórroga'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_prorroga) ...[
              SwitchListTile.adaptive(
                value:    _penales,
                onChanged: bloqueado ? null : (v) => setState(() => _penales = v),
                title:     const Text('Tuvo penales'),
                contentPadding: EdgeInsets.zero,
              ),
              if (_penales) ...[
                const SizedBox(height: 8),
                const Text('Goles en penales', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ContadorGoles(
                        label:      widget.detalle.equipoLocalNombre,
                        valor:      _golesLocalPenales,
                        deshabilitado: bloqueado,
                        onChange:   bloqueado ? null : (v) => setState(() => _golesLocalPenales = v),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('–', style: TextStyle(fontSize: 24)),
                    ),
                    Expanded(
                      child: _ContadorGoles(
                        label:      widget.detalle.equipoVisitanteNombre,
                        valor:      _golesVisitantePenales,
                        deshabilitado: bloqueado,
                        onChange:   bloqueado ? null : (v) => setState(() => _golesVisitantePenales = v),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            if (!bloqueado) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar resultado'),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('El resultado está bloqueado.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Iniciar partido (sheet anidado) ─────────────────────────────────────────

class _IniciarSheet extends StatefulWidget {
  const _IniciarSheet({required this.detalle, required this.repo, required this.onIniciado});
  final PartidoDetalleDto       detalle;
  final StaffPartidosRepository repo;
  final VoidCallback            onIniciado;

  @override
  State<_IniciarSheet> createState() => _IniciarSheetState();
}

class _IniciarSheetState extends State<_IniciarSheet> {
  PartidoPreInicioDto? _preInicio;
  bool                 _cargando  = true;
  String?              _error;
  ArbitroSimpleDto?    _arbitro;
  bool                 _pagoLocal     = false;
  bool                 _pagoVisitante = false;
  bool                 _iniciando     = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final pi = await widget.repo.obtenerPreInicio(widget.detalle.id);
      if (!mounted) return;
      setState(() {
        _preInicio = pi;
        _cargando  = false;
        _arbitro   = pi.arbitros
            .where((a) => a.id == pi.arbitroActualId).firstOrNull
            ?? (pi.arbitros.isNotEmpty ? pi.arbitros.first : null);
        _pagoLocal     = pi.pagoEquipoLocal;
        _pagoVisitante = pi.pagoEquipoVisitante;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Error al cargar datos de inicio.'; _cargando = false; });
    }
  }

  Future<void> _iniciar() async {
    if (_arbitro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un árbitro'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _iniciando = true);
    try {
      await widget.repo.iniciar(
        widget.detalle.id,
        arbitroId:     _arbitro!.id,
        pagoLocal:     _pagoLocal,
        pagoVisitante: _pagoVisitante,
      );
      if (!mounted) return;
      Navigator.pop(context);   // cierra sheet Iniciar
      widget.onIniciado();      // recarga datos del partido (ahora EnCurso)
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al iniciar partido'), backgroundColor: Colors.red),
      );
      setState(() => _iniciando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:     MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _DragHandle(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Iniciar partido',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(),
          if (_cargando)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(child: _ErrorPanel(mensaje: _error!, onReintentar: _cargar))
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Jugadores
                    _InfoCard(children: [
                      _InfoLinea(
                        label: widget.detalle.equipoLocalNombre,
                        valor: '${_preInicio!.jugadoresLocalActivos} activos',
                        icono: Icons.group_outlined,
                      ),
                      _InfoLinea(
                        label: widget.detalle.equipoVisitanteNombre,
                        valor: '${_preInicio!.jugadoresVisitanteActivos} activos',
                        icono: Icons.group_outlined,
                      ),
                      _InfoLinea(
                        label: 'Jugadores en campo',
                        valor: '${_preInicio!.jugadoresEnCampo}',
                        icono: Icons.sports_soccer_outlined,
                      ),
                    ]),
                    const SizedBox(height: 12),
                    // Cuota
                    if (_preInicio!.cuotaMonto != null)
                      _InfoCard(children: [
                        _InfoLinea(
                          label: 'Cuota',
                          valor: '\$${_preInicio!.cuotaMonto!.toStringAsFixed(2)}',
                          icono: Icons.payments_outlined,
                        ),
                        SwitchListTile.adaptive(
                          value:    _pagoLocal,
                          onChanged: (v) => setState(() => _pagoLocal = v),
                          title: Text('Pagó ${widget.detalle.equipoLocalNombre}'),
                          contentPadding: const EdgeInsets.only(left: 0),
                          dense: true,
                        ),
                        SwitchListTile.adaptive(
                          value:    _pagoVisitante,
                          onChanged: (v) => setState(() => _pagoVisitante = v),
                          title: Text('Pagó ${widget.detalle.equipoVisitanteNombre}'),
                          contentPadding: const EdgeInsets.only(left: 0),
                          dense: true,
                        ),
                      ]),
                    const SizedBox(height: 12),
                    // Árbitro
                    if (_preInicio!.arbitros.isNotEmpty)
                      _CampoPicker<ArbitroSimpleDto>(
                        label:    'Árbitro',
                        valor:    _arbitro?.nombre ?? 'Seleccionar árbitro',
                        opciones: _preInicio!.arbitros,
                        etiqueta: (a) => a.nombre,
                        onSeleccion: (a) => setState(() => _arbitro = a),
                      ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _iniciando ? null : _iniciar,
                      icon:  _iniciando
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.play_arrow_rounded),
                      label: const Text('Iniciar partido'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Widgets reutilizables ───────────────────────────────────────────────────

class _CampoFecha extends StatelessWidget {
  const _CampoFecha({required this.label, required this.valor, required this.onTap});
  final String   label;
  final String   valor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText:   label,
        border:      const OutlineInputBorder(),
        isDense:     true,
        suffixIcon:  const Icon(Icons.edit_calendar_outlined, size: 18),
      ),
      child: Text(valor, style: const TextStyle(fontSize: 14)),
    ),
  );
}

// ─── Panel de evaluación de árbitro ─────────────────────────────────────────

class _EvaluacionArbitroPanel extends StatefulWidget {
  const _EvaluacionArbitroPanel({
    required this.partidoId,
    required this.arbitroNombre,
    required this.repo,
  });
  final String                   partidoId;
  final String                   arbitroNombre;
  final StaffPartidosRepository  repo;

  @override
  State<_EvaluacionArbitroPanel> createState() => _EvaluacionArbitroPanelState();
}

class _EvaluacionArbitroPanelState extends State<_EvaluacionArbitroPanel> {
  EvaluacionArbitroDto? _existente;
  bool                  _cargando  = true;
  String?               _error;

  // campos del form
  int     _puntualidad   = 5;
  int     _conocimiento  = 5;
  int     _trato         = 5;
  int     _imparcialidad = 5;
  final   _cComentario   = TextEditingController();
  bool    _enviando      = false;
  bool    _enviado       = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _cComentario.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final ev = await widget.repo.obtenerEvaluacionArbitro(widget.partidoId);
      if (!mounted) return;
      setState(() { _existente = ev; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Error al cargar evaluación.'; _cargando = false; });
    }
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    try {
      await widget.repo.evaluarArbitro(
        widget.partidoId,
        puntualidad:   _puntualidad,
        conocimiento:  _conocimiento,
        trato:         _trato,
        imparcialidad: _imparcialidad,
        comentario:    _cComentario.text.trim().isEmpty ? null : _cComentario.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _enviado   = true;
        _enviando  = false;
        _existente = EvaluacionArbitroDto(
          id:                '',
          puntualidad:       _puntualidad,
          conocimiento:      _conocimiento,
          trato:             _trato,
          imparcialidad:     _imparcialidad,
          promedio:          (_puntualidad + _conocimiento + _trato + _imparcialidad) / 4.0,
          comentario:        _cComentario.text.trim().isEmpty ? null : _cComentario.text.trim(),
          evaluadoPorNombre: '',
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar evaluación'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.star_outline_rounded, size: 18, color: Colors.amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Calificar árbitro · ${widget.arbitroNombre}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            if (_cargando)
              const Center(child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (_error != null)
              _ErrorPanel(mensaje: _error!, onReintentar: _cargar)
            else if (_existente != null)
              _VistaEvaluacionExistente(ev: _existente!, recienEnviada: _enviado)
            else
              _FormEvaluacion(
                puntualidad:    _puntualidad,
                conocimiento:   _conocimiento,
                trato:          _trato,
                imparcialidad:  _imparcialidad,
                cComentario:    _cComentario,
                enviando:       _enviando,
                onPuntualidad:  (v) => setState(() => _puntualidad   = v),
                onConocimiento: (v) => setState(() => _conocimiento  = v),
                onTrato:        (v) => setState(() => _trato         = v),
                onImparcialidad:(v) => setState(() => _imparcialidad = v),
                onEnviar:       _enviar,
              ),
          ],
        ),
      ),
    );
  }
}

class _VistaEvaluacionExistente extends StatelessWidget {
  const _VistaEvaluacionExistente({required this.ev, required this.recienEnviada});
  final EvaluacionArbitroDto ev;
  final bool                 recienEnviada;

  @override
  Widget build(BuildContext context) {
    final criterios = [
      ('Puntualidad',    ev.puntualidad),
      ('Conocimiento',   ev.conocimiento),
      ('Trato',          ev.trato),
      ('Imparcialidad',  ev.imparcialidad),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recienEnviada)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(children: [
              Icon(Icons.check_circle_outline, size: 16, color: Colors.green[700]),
              const SizedBox(width: 6),
              Text('Evaluación enviada', style: TextStyle(fontSize: 12, color: Colors.green[800], fontWeight: FontWeight.w600)),
            ]),
          ),
        ...criterios.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(width: 100,
                child: Text(c.$1, style: const TextStyle(fontSize: 12, color: Colors.grey))),
              _EstrellasLectura(valor: c.$2),
              const SizedBox(width: 6),
              Text('${c.$2}/5', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        )),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const SizedBox(width: 100,
                child: Text('Promedio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
              Text(ev.promedio.toStringAsFixed(1),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.amber)),
              const SizedBox(width: 4),
              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
            ],
          ),
        ),
        if (ev.comentario != null && ev.comentario!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(ev.comentario!,
              style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
        ],
      ],
    );
  }
}

class _FormEvaluacion extends StatelessWidget {
  const _FormEvaluacion({
    required this.puntualidad,
    required this.conocimiento,
    required this.trato,
    required this.imparcialidad,
    required this.cComentario,
    required this.enviando,
    required this.onPuntualidad,
    required this.onConocimiento,
    required this.onTrato,
    required this.onImparcialidad,
    required this.onEnviar,
  });
  final int                   puntualidad;
  final int                   conocimiento;
  final int                   trato;
  final int                   imparcialidad;
  final TextEditingController cComentario;
  final bool                  enviando;
  final void Function(int)    onPuntualidad;
  final void Function(int)    onConocimiento;
  final void Function(int)    onTrato;
  final void Function(int)    onImparcialidad;
  final VoidCallback          onEnviar;

  @override
  Widget build(BuildContext context) {
    final criterios = [
      ('Puntualidad',   puntualidad,   onPuntualidad),
      ('Conocimiento',  conocimiento,  onConocimiento),
      ('Trato',         trato,         onTrato),
      ('Imparcialidad', imparcialidad, onImparcialidad),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...criterios.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(width: 100,
                child: Text(c.$1, style: const TextStyle(fontSize: 12, color: Colors.grey))),
              _EstrellasPicker(valor: c.$2, onChanged: c.$3),
            ],
          ),
        )),
        const SizedBox(height: 4),
        TextField(
          controller: cComentario,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Comentario (opcional)',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: enviando ? null : onEnviar,
          icon: enviando
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.star_rounded, size: 18),
          label: const Text('Enviar calificación'),
          style: FilledButton.styleFrom(backgroundColor: Colors.amber[700]),
        ),
      ],
    );
  }
}

class _EstrellasPicker extends StatelessWidget {
  const _EstrellasPicker({required this.valor, required this.onChanged});
  final int                valor;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) {
      final n = i + 1;
      return GestureDetector(
        onTap: () => onChanged(n),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            n <= valor ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 24,
            color: Colors.amber,
          ),
        ),
      );
    }),
  );
}

class _EstrellasLectura extends StatelessWidget {
  const _EstrellasLectura({required this.valor});
  final int valor;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) => Icon(
      (i + 1) <= valor ? Icons.star_rounded : Icons.star_outline_rounded,
      size: 14,
      color: Colors.amber,
    )),
  );
}

// ─── Widgets reutilizables ───────────────────────────────────────────────────

class _CampoPicker<T> extends StatelessWidget {
  const _CampoPicker({
    required this.label,
    required this.valor,
    required this.opciones,
    required this.etiqueta,
    required this.onSeleccion,
  });
  final String       label;
  final String       valor;
  final List<T>      opciones;
  final String Function(T) etiqueta;
  final void Function(T)   onSeleccion;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _mostrarPicker(context),
    borderRadius: BorderRadius.circular(8),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText:  label,
        border:     const OutlineInputBorder(),
        isDense:    true,
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      child: Text(valor, style: const TextStyle(fontSize: 14)),
    ),
  );

  void _mostrarPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: opciones.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(etiqueta(opciones[i])),
          onTap: () {
            onSeleccion(opciones[i]);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class _ContadorGoles extends StatelessWidget {
  const _ContadorGoles({
    required this.label,
    required this.valor,
    required this.deshabilitado,
    required this.onChange,
  });
  final String label;
  final int    valor;
  final bool   deshabilitado;
  final void Function(int)? onChange;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 6),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: (deshabilitado || valor <= 0) ? null : () => onChange!(valor - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 36,
            child: Text('$valor',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            onPressed: deshabilitado ? null : () => onChange!(valor + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    ],
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    ),
  );
}

class _InfoLinea extends StatelessWidget {
  const _InfoLinea({required this.label, required this.valor, required this.icono});
  final String   label;
  final String   valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icono, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    ),
  );
}

// ─── Error panel ────────────────────────────────────────────────────────────

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.mensaje, required this.onReintentar});
  final String       mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
        const SizedBox(height: 12),
        Text(mensaje, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: onReintentar,
          icon:  const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    ),
  );
}

// ─── Estado badge ────────────────────────────────────────────────────────────

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado, required this.label});
  final EstadoPartido estado;
  final String        label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (estado) {
      EstadoPartido.programado => (Colors.blue[50]!,    Colors.blue[700]!),
      EstadoPartido.enCurso    => (Colors.red[50]!,     Colors.red[700]!),
      EstadoPartido.terminado  => (Colors.green[50]!,   Colors.green[700]!),
      EstadoPartido.suspendido => (Colors.orange[50]!,  Colors.orange[700]!),
      EstadoPartido.cancelado  => (Colors.grey[100]!,   Colors.grey[600]!),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Color? _hexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  try {
    final h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    if (h.length == 8) return Color(int.parse(h, radix: 16));
  } catch (_) {}
  return null;
}
