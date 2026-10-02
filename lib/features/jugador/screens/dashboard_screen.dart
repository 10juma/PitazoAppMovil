import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../shared/widgets/pitazo_scaffold.dart';
import '../../../shared/enums/estado_partido.dart';
import '../data/jugador_repository.dart';
import '../providers/jugador_provider.dart';

class JugadorDashboardScreen extends StatefulWidget {
  const JugadorDashboardScreen({super.key});

  @override
  State<JugadorDashboardScreen> createState() => _JugadorDashboardScreenState();
}

class _JugadorDashboardScreenState extends State<JugadorDashboardScreen> {
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<JugadorProvider>();
      if (p.equipoActivo == null && !p.loading) p.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JugadorProvider>();
    final accent   = RolePalettes.accentForRol('Jugador');
    final equipoId = provider.equipoActivo?.jugadorEquipoId;

    return PitazoScaffold(
      primaryNav: const [
        PitazoNavItem(icon: Icons.dashboard_outlined,   label: 'Inicio'),
        PitazoNavItem(icon: Icons.bar_chart_outlined,    label: 'Estadísticas'),
        PitazoNavItem(icon: Icons.history,               label: 'Resultados'),
        PitazoNavItem(icon: Icons.campaign_outlined,     label: 'Comunicados'),
      ],
      onTabChanged: (i) => setState(() => _activeTab = i),
      onAvatarTap: () => context.push('/jugador/perfil'),
      child: Column(children: [
        if (provider.equipos.length > 1)
          _EquipoSelector(
            equipos: provider.equipos,
            activo:  provider.equipoActivo,
            accent:  accent,
            onChanged: (id) => provider.cambiarEquipo(id),
          ),
        if (provider.participaciones.length > 1)
          _CompetenciaSelector(
            competencias: provider.participaciones,
            activaId:     provider.equipoActivo?.participacionId,
            accent:       accent,
            onChanged:    (id) => provider.cambiarParticipacion(id),
          ),
        Expanded(child: IndexedStack(
          index: _activeTab,
          children: [
            _JugadorInicioBody(accent: accent),
            _JugadorEstadisticasBody(
              equipoId: equipoId,
              participacionId: provider.equipoActivo?.participacionId,
              accent: accent,
            ),
            _JugadorResultadosBody(
              equipoId: equipoId,
              participacionId: provider.equipoActivo?.participacionId,
              accent: accent,
            ),
            _JugadorComunicadosBody(accent: accent),
          ],
        )),
      ]),
    );
  }
}

// ── Equipo selector ───────────────────────────────────────────────────────────

class _EquipoSelector extends StatelessWidget {
  final List<EquipoJugadorDto> equipos;
  final EquipoJugadorDto?      activo;
  final Color                  accent;
  final void Function(String)  onChanged;
  const _EquipoSelector({
    required this.equipos, required this.activo,
    required this.accent,  required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: activo?.jugadorEquipoId,
          isExpanded: true,
          underline: const SizedBox(),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          items: equipos.map((e) => DropdownMenuItem(
            value: e.jugadorEquipoId,
            child: Text(e.nombre),
          )).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

// ── Competencia selector (cuando el equipo juega varias ligas a la vez) ────────

class _CompetenciaSelector extends StatelessWidget {
  final List<ParticipacionResumenDto> competencias;
  final String?               activaId;
  final Color                 accent;
  final void Function(String) onChanged;
  const _CompetenciaSelector({
    required this.competencias, required this.activaId,
    required this.accent,       required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButton<String>(
          value: activaId,
          isExpanded: true,
          underline: const SizedBox(),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          items: competencias.map((c) => DropdownMenuItem(
            value: c.participacionId,
            child: Text('${c.ligaNombre} · ${c.temporadaNombre}', overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

// ── Inicio body ───────────────────────────────────────────────────────────────

class _JugadorInicioBody extends StatefulWidget {
  final Color accent;
  const _JugadorInicioBody({required this.accent});

  @override
  State<_JugadorInicioBody> createState() => _JugadorInicioBodyState();
}

class _JugadorInicioBodyState extends State<_JugadorInicioBody> {
  @override
  Widget build(BuildContext context) {
    final p    = context.watch<JugadorProvider>();
    final dash = p.dashboard;

    return RefreshIndicator(
      color: widget.accent,
      onRefresh: () => p.loadSilent(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (p.loading && dash == null)
            _buildSkeleton()
          else if (dash == null)
            _InfoCard(
              icon: Icons.sports_soccer_outlined,
              texto: p.equipoActivo == null
                  ? 'No perteneces a ningún equipo todavía'
                  : 'No se pudo cargar tu información',
            )
          else ...[
            _EnVivoJugadorCard(partidos: dash.enVivoRegistrado, accent: widget.accent),
            const SizedBox(height: 10),
            _StatsRow(dash: dash, accent: widget.accent),
            const SizedBox(height: 14),
            _SeccionTitle(icon: Icons.calendar_month_outlined, titulo: 'Próximos partidos'),
            const SizedBox(height: 8),
            if (p.proximos.isEmpty)
              const _InfoCard(icon: Icons.event_available_outlined, texto: 'Sin partidos próximos')
            else
              ...p.proximos.map((partido) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ProximoPartidoCard(partido: partido, accent: widget.accent),
              )),
          ],
        ]),
      ),
    );
  }

  Widget _buildSkeleton() => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Shimmer(height: 88),
      SizedBox(height: 10),
      _Shimmer(height: 70),
    ],
  );
}

// ── En Vivo (registrado) ──────────────────────────────────────────────────────

class _EnVivoJugadorCard extends StatelessWidget {
  final List<PartidoJugadorDto> partidos;
  final Color accent;
  const _EnVivoJugadorCard({required this.partidos, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: partidos.isEmpty ? AppColors.border : const Color(0xFFDC2626).withValues(alpha: 0.4),
          width: partidos.isEmpty ? 0.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            if (partidos.isNotEmpty) _LiveDot(),
            if (partidos.isNotEmpty) const SizedBox(width: 6),
            const Text('En vivo ahora',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            if (partidos.isNotEmpty) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(10)),
                child: Text('${partidos.length}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ]),
        ),
        if (partidos.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(children: [
              Icon(Icons.nightlight_outlined, size: 15, color: AppColors.textHint),
              SizedBox(width: 6),
              Text('No tienes partidos en vivo ahora', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
            ]),
          )
        else
          ...partidos.map((p) => Column(children: [
            const Divider(height: 0, thickness: 0.5, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Container(width: 8, height: 8,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFDC2626))),
                const SizedBox(width: 12),
                Expanded(child: Text('${p.equipoLocalNombre} vs ${p.equipoVisitanteNombre}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                Text('${p.golesLocal} – ${p.golesVisitante}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accent)),
              ]),
            ),
          ])),
      ]),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final JugadorDashboardDto dash;
  final Color accent;
  const _StatsRow({required this.dash, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _StatChip(valor: '${dash.overall}', label: 'Overall', accent: accent)),
      const SizedBox(width: 8),
      Expanded(child: _StatChip(valor: '${dash.pj}', label: 'Partidos', accent: accent)),
      const SizedBox(width: 8),
      Expanded(child: _StatChip(valor: '${dash.goles}', label: 'Goles', accent: accent)),
      const SizedBox(width: 8),
      Expanded(child: _StatChip(valor: '${dash.asistencias}', label: 'Asist.', accent: accent)),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final String valor;
  final String label;
  final Color  accent;
  const _StatChip({required this.valor, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: Column(children: [
      Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accent)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
    ]),
  );
}

// ── Próximo partido (con confirmar asistencia) ────────────────────────────────

class _ProximoPartidoCard extends StatefulWidget {
  final PartidoJugadorDto partido;
  final Color accent;
  const _ProximoPartidoCard({required this.partido, required this.accent});

  @override
  State<_ProximoPartidoCard> createState() => _ProximoPartidoCardState();
}

class _ProximoPartidoCardState extends State<_ProximoPartidoCard> {
  final _repo = JugadorRepository();
  bool?  _confirma;
  int?   _motivo;
  bool   _cargado  = false;
  bool   _cargando = false;

  static const _motivos = [
    (1, 'Lesión'), (2, 'Trabajo'), (3, 'Personal'), (4, 'Suspensión'), (5, 'Otro'),
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final jugadorEquipoId = context.read<JugadorProvider>().equipoActivo?.jugadorEquipoId;
    if (jugadorEquipoId == null) return;
    try {
      final (confirma, motivo) = await _repo.obtenerConfirmacion(jugadorEquipoId, widget.partido.id);
      if (mounted) setState(() { _confirma = confirma; _motivo = motivo; _cargado = true; });
    } catch (_) {
      if (mounted) setState(() => _cargado = true);
    }
  }

  Future<void> _responder(bool confirma, [int? motivo]) async {
    final jugadorEquipoId = context.read<JugadorProvider>().equipoActivo?.jugadorEquipoId;
    if (jugadorEquipoId == null) return;
    setState(() => _cargando = true);
    final err = await _repo.confirmar(jugadorEquipoId, widget.partido.id, confirma: confirma, motivo: motivo);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (err == null) { _confirma = confirma; _motivo = motivo; }
    });
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  void _abrirMotivos() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(alignment: Alignment.centerLeft, child: Text('¿Por qué no puedes asistir?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          ),
          ..._motivos.map((m) => ListTile(
            title: Text(m.$2, style: const TextStyle(fontSize: 13)),
            onTap: () { Navigator.pop(context); _responder(false, m.$1); },
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p   = widget.partido;
    final fmt = DateFormat('EEE dd/MM · HH:mm', 'es_MX');
    final motivoLabel = _motivos.firstWhere((m) => m.$1 == _motivo, orElse: () => (0, '')).$2;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(fmt.format(p.fechaHora), style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
        const SizedBox(height: 6),
        Text('${p.equipoLocalNombre} vs ${p.equipoVisitanteNombre}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        if (p.canchaNombre != null) ...[
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.place_outlined, size: 12, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(p.canchaNombre!, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ]),
        ],
        const SizedBox(height: 10),
        if (!_cargado)
          const SizedBox(height: 32, child: Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))))
        else if (_cargando)
          const SizedBox(height: 32, child: Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))))
        else if (_confirma == true)
          Row(children: [
            const Icon(Icons.check_circle, size: 16, color: AppColors.success),
            const SizedBox(width: 6),
            const Text('Confirmaste tu asistencia', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(onPressed: () => _responder(false), child: const Text('Cambiar', style: TextStyle(fontSize: 11))),
          ])
        else if (_confirma == false)
          Row(children: [
            const Icon(Icons.cancel, size: 16, color: AppColors.error),
            const SizedBox(width: 6),
            Expanded(child: Text('Declinaste${motivoLabel.isNotEmpty ? ' · $motivoLabel' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600))),
            TextButton(onPressed: () => _responder(true), child: const Text('Cambiar', style: TextStyle(fontSize: 11))),
          ])
        else
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.check, size: 14),
              label: const Text('Asisto', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: () => _responder(true),
            )),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.close, size: 14),
              label: const Text('No asisto', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: _abrirMotivos,
            )),
          ]),
      ]),
    );
  }
}

// ── Estadísticas body ─────────────────────────────────────────────────────────

class _JugadorEstadisticasBody extends StatefulWidget {
  final String? equipoId;
  final String? participacionId;
  final Color   accent;
  const _JugadorEstadisticasBody({required this.equipoId, required this.participacionId, required this.accent});

  @override
  State<_JugadorEstadisticasBody> createState() => _JugadorEstadisticasBodyState();
}

class _JugadorEstadisticasBodyState extends State<_JugadorEstadisticasBody> {
  final _repo = JugadorRepository();
  EstadisticasJugadorDto?   _stats;
  bool   _avanzadasActivas = false;
  List<TablaPosicionesJugadorDto> _tablas = [];
  bool    _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.equipoId != null) _cargar();
  }

  @override
  void didUpdateWidget(_JugadorEstadisticasBody old) {
    super.didUpdateWidget(old);
    if ((old.equipoId != widget.equipoId || old.participacionId != widget.participacionId) && widget.equipoId != null) _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final (stats, avanzadas) = await _repo.obtenerEstadisticas(widget.equipoId!, participacionId: widget.participacionId);
      final tablas = await _repo.obtenerTablas(widget.equipoId!, participacionId: widget.participacionId);
      if (mounted) setState(() { _stats = stats; _avanzadasActivas = avanzadas; _tablas = tablas; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.equipoId == null) return const _InfoCard(icon: Icons.bar_chart_outlined, texto: 'Sin equipo activo');
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _InfoCard(icon: Icons.error_outline, texto: _error!, onRetry: _cargar);
    final s = _stats;
    if (s == null) return const _InfoCard(icon: Icons.bar_chart_outlined, texto: 'Sin estadísticas para esta temporada');

    return RefreshIndicator(
      color: widget.accent,
      onRefresh: _cargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SeccionTitle(icon: Icons.bar_chart_outlined, titulo: 'Mi rendimiento'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _StatChip(valor: '${s.pj}', label: 'PJ', accent: widget.accent)),
            const SizedBox(width: 8),
            Expanded(child: _StatChip(valor: '${s.goles}', label: 'Goles', accent: widget.accent)),
            const SizedBox(width: 8),
            Expanded(child: _StatChip(valor: '${s.asistencias}', label: 'Asist.', accent: widget.accent)),
          ]),
          if (_avanzadasActivas) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _StatChip(valor: '${s.partidosConvocado}', label: 'Convocado', accent: widget.accent)),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(valor: '${s.porcentajeAsistencia}%', label: 'Asistencia', accent: widget.accent)),
              const SizedBox(width: 8),
              Expanded(child: _StatChip(valor: '${s.minutosJugados}', label: 'Minutos', accent: widget.accent)),
            ]),
            const SizedBox(height: 8),
            Text('Promedio de goles por partido: ${s.golesPorPartido}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          _SeccionTitle(icon: Icons.sports_outlined, titulo: 'Disciplina'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Wrap(spacing: 18, runSpacing: 8, children: [
              _DisciplinaItem(valor: '${s.tarjetasAmarillas}', label: 'Amarillas'),
              _DisciplinaItem(valor: '${s.tarjetasRojas}', label: 'Rojas'),
              _DisciplinaItem(valor: '${s.lesiones}', label: 'Lesiones'),
              _DisciplinaItem(valor: '${s.penalesMarcados}/${s.penalesFallados}', label: 'Penales (marc./fall.)'),
            ]),
          ),
          if (_tablas.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final tabla in _tablas) ...[
              _SeccionTitle(icon: Icons.emoji_events_outlined,
                  titulo: 'Tabla — ${tabla.faseNombre}${tabla.grupoNombre != null ? ' · ${tabla.grupoNombre}' : ''}'),
              const SizedBox(height: 8),
              _TablaPosicionesWidget(tabla: tabla, accent: widget.accent),
              const SizedBox(height: 12),
            ],
          ],
        ]),
      ),
    );
  }
}

class _DisciplinaItem extends StatelessWidget {
  final String valor;
  final String label;
  const _DisciplinaItem({required this.valor, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
  ]);
}

class _TablaPosicionesWidget extends StatelessWidget {
  final TablaPosicionesJugadorDto tabla;
  final Color accent;
  const _TablaPosicionesWidget({required this.tabla, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 32,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 32,
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('#', style: TextStyle(fontSize: 10))),
            DataColumn(label: Text('Equipo', style: TextStyle(fontSize: 10))),
            DataColumn(label: Text('PJ', style: TextStyle(fontSize: 10))),
            DataColumn(label: Text('PG', style: TextStyle(fontSize: 10))),
            DataColumn(label: Text('PE', style: TextStyle(fontSize: 10))),
            DataColumn(label: Text('PP', style: TextStyle(fontSize: 10))),
            DataColumn(label: Text('DG', style: TextStyle(fontSize: 10))),
            DataColumn(label: Text('Pts', style: TextStyle(fontSize: 10))),
          ],
          rows: tabla.filas.map((f) => DataRow(cells: [
            DataCell(Text('${f.posicion}', style: const TextStyle(fontSize: 11))),
            DataCell(Text(f.nombre, style: const TextStyle(fontSize: 11))),
            DataCell(Text('${f.pj}', style: const TextStyle(fontSize: 11))),
            DataCell(Text('${f.pg}', style: const TextStyle(fontSize: 11))),
            DataCell(Text('${f.pe}', style: const TextStyle(fontSize: 11))),
            DataCell(Text('${f.pp}', style: const TextStyle(fontSize: 11))),
            DataCell(Text('${f.dg > 0 ? '+' : ''}${f.dg}', style: const TextStyle(fontSize: 11))),
            DataCell(Text('${f.pts}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent))),
          ])).toList(),
        ),
      ),
    );
  }
}

// ── Resultados (partidos terminados) ────────────────────────────────────────────

class _JugadorResultadosBody extends StatefulWidget {
  final String? equipoId;
  final String? participacionId;
  final Color   accent;
  const _JugadorResultadosBody({required this.equipoId, required this.participacionId, required this.accent});

  @override
  State<_JugadorResultadosBody> createState() => _JugadorResultadosBodyState();
}

class _JugadorResultadosBodyState extends State<_JugadorResultadosBody> {
  final _repo = JugadorRepository();
  List<PartidoJugadorDto> _partidos = [];
  bool    _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.equipoId != null) _cargar();
  }

  @override
  void didUpdateWidget(_JugadorResultadosBody old) {
    super.didUpdateWidget(old);
    if ((old.equipoId != widget.equipoId || old.participacionId != widget.participacionId) && widget.equipoId != null) _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final partidos = await _repo.listarPartidos(widget.equipoId!,
          estado: EstadoPartido.terminado, participacionId: widget.participacionId);
      partidos.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
      if (mounted) setState(() { _partidos = partidos; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.equipoId == null) return const _InfoCard(icon: Icons.history, texto: 'Sin equipo activo');
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _InfoCard(icon: Icons.error_outline, texto: _error!, onRetry: _cargar);
    if (_partidos.isEmpty) {
      return const _InfoCard(icon: Icons.history, texto: 'Aún no hay partidos terminados en esta competencia');
    }

    return RefreshIndicator(
      color: widget.accent,
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _partidos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _ResultadoCard(
          p: _partidos[i], equipoId: widget.equipoId!, accent: widget.accent,
          onTap: () => context.push('/jugador/partidos/${_partidos[i].id}'),
        ),
      ),
    );
  }
}

class _ResultadoCard extends StatelessWidget {
  final PartidoJugadorDto p;
  final String equipoId;
  final Color  accent;
  final VoidCallback onTap;
  const _ResultadoCard({required this.p, required this.equipoId, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE d MMM', 'es_MX');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p.equipoLocalNombre} vs ${p.equipoVisitanteNombre}', maxLines: 2,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('${fmt.format(p.fechaHora)} · ${p.faseNombre} J${p.jornadaNumero}',
                style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ])),
          const SizedBox(width: 10),
          Text('${p.golesLocal} - ${p.golesVisitante}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
        ]),
      ),
    );
  }
}

// ── Comunicados ─────────────────────────────────────────────────────────────────

class _JugadorComunicadosBody extends StatefulWidget {
  final Color accent;
  const _JugadorComunicadosBody({required this.accent});

  @override
  State<_JugadorComunicadosBody> createState() => _JugadorComunicadosBodyState();
}

class _JugadorComunicadosBodyState extends State<_JugadorComunicadosBody> {
  final _repo = JugadorRepository();
  List<ComunicadoJugadorDto> _comunicados = [];
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
      final comunicados = await _repo.listarComunicados();
      if (mounted) setState(() { _comunicados = comunicados; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _marcarLeido(ComunicadoJugadorDto c) async {
    if (c.leida) return;
    final i = _comunicados.indexWhere((x) => x.id == c.id);
    if (i == -1) return;
    final ok = await _repo.marcarComunicadoLeido(c.id);
    if (ok && mounted) {
      setState(() => _comunicados[i] = ComunicadoJugadorDto(
            id: c.id, titulo: c.titulo, cuerpo: c.cuerpo, leida: true, creadaEn: c.creadaEn,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _InfoCard(icon: Icons.error_outline, texto: _error!, onRetry: _cargar);
    if (_comunicados.isEmpty) {
      return const _InfoCard(icon: Icons.campaign_outlined, texto: 'No tienes comunicados.');
    }

    return RefreshIndicator(
      color: widget.accent,
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _comunicados.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _ComunicadoCard(
          c: _comunicados[i], accent: widget.accent,
          onTap: () => _marcarLeido(_comunicados[i]),
        ),
      ),
    );
  }
}

class _ComunicadoCard extends StatelessWidget {
  final ComunicadoJugadorDto c;
  final Color  accent;
  final VoidCallback onTap;
  const _ComunicadoCard({required this.c, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy · HH:mm', 'es_MX');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.leida ? AppColors.surface : accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!c.leida) Padding(
              padding: const EdgeInsets.only(top: 4, right: 6),
              child: Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
            ),
            Expanded(child: Text(c.titulo,
                style: TextStyle(fontSize: 13, fontWeight: c.leida ? FontWeight.w600 : FontWeight.w800, color: AppColors.textPrimary))),
            const SizedBox(width: 8),
            Text(fmt.format(c.creadaEn), style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ]),
          const SizedBox(height: 6),
          Text(c.cuerpo, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SeccionTitle extends StatelessWidget {
  final IconData icon;
  final String   titulo;
  const _SeccionTitle({required this.icon, required this.titulo});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: AppColors.textSecondary),
    const SizedBox(width: 6),
    Text(titulo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
  ]);
}

class _InfoCard extends StatelessWidget {
  final IconData     icon;
  final String       texto;
  final VoidCallback? onRetry;
  const _InfoCard({required this.icon, required this.texto, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 36, color: AppColors.textHint),
      const SizedBox(height: 10),
      Text(texto, style: const TextStyle(fontSize: 12, color: AppColors.textHint), textAlign: TextAlign.center),
      if (onRetry != null) ...[
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ]),
  ));
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _ctrl,
    child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFDC2626))),
  );
}

class _Shimmer extends StatelessWidget {
  final double height;
  const _Shimmer({required this.height});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(14)),
  );
}
