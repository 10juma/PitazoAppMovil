import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/pitazo_scaffold.dart';
import '../data/manager_repository.dart';
import '../providers/manager_provider.dart';
import '../../../shared/enums/estado_partido.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<ManagerProvider>();
      if (p.equipoActivo == null && !p.loading) p.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<ManagerProvider>();
    final accent    = RolePalettes.accentForRol('Manager');
    final equipoId  = provider.equipoActivo?.equipoId;

    return PitazoScaffold(
      primaryNav: const [
        PitazoNavItem(icon: Icons.dashboard_outlined,      label: 'Inicio'),
        PitazoNavItem(icon: Icons.calendar_month_outlined, label: 'Partidos'),
        PitazoNavItem(icon: Icons.payments_outlined,       label: 'Pagos'),
      ],
      onTabChanged: (i) {
        setState(() => _activeTab = i);
        if (i == 0) context.read<ManagerProvider>().loadSilent();
      },
      onAvatarTap: () => context.push('/manager/perfil'),
      floatingActionButton: _activeTab == 2 && equipoId != null
          ? FloatingActionButton(
              backgroundColor: accent,
              onPressed: () => _mostrarCobroSheet(context, equipoId, accent),
              child: const Icon(Icons.add),
            )
          : null,
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
            _ManagerInicioBody(accent: accent),
            _ManagerPartidosBody(equipoId: equipoId, accent: accent),
            _ManagerPagosBody(equipoId: equipoId, accent: accent),
          ],
        )),
      ]),
    );
  }

  void _mostrarCobroSheet(BuildContext context, String equipoId, Color accent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CobroPartidoSheet(equipoId: equipoId, accent: accent),
    );
  }
}

// ── Equipo selector ───────────────────────────────────────────────────────────

class _EquipoSelector extends StatelessWidget {
  final List<EquipoManagerDto> equipos;
  final EquipoManagerDto?      activo;
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
          value: activo?.equipoId,
          isExpanded: true,
          underline: const SizedBox(),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          items: equipos.map((e) => DropdownMenuItem(
            value: e.equipoId,
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

class _ManagerInicioBody extends StatefulWidget {
  final Color accent;
  const _ManagerInicioBody({required this.accent});

  @override
  State<_ManagerInicioBody> createState() => _ManagerInicioBodyState();
}

class _ManagerInicioBodyState extends State<_ManagerInicioBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<ManagerProvider>();
      if (p.dashboard == null && !p.loading && p.equipoActivo != null) p.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p         = context.watch<ManagerProvider>();
    final dash      = p.dashboard;
    final tenantSlug = context.read<AuthProvider>().token?.tenantSlug;

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
              icon: Icons.shield_outlined,
              texto: p.equipoActivo == null
                  ? 'No tienes equipos asignados'
                  : 'No se pudo cargar el dashboard',
            )
          else ...[
            _EnVivoManagerCard(partidos: dash.enVivo, accent: widget.accent, tenantSlug: tenantSlug),
            const SizedBox(height: 10),
            if (dash.proximosPartidos.isNotEmpty) ...[
              _ProximosManagerCard(partidos: dash.proximosPartidos, accent: widget.accent),
              const SizedBox(height: 10),
            ],
            _StatsRow(dash: dash, accent: widget.accent),
            if (dash.posicion != null) ...[
              const SizedBox(height: 10),
              _PosicionCard(pos: dash.posicion!, accent: widget.accent),
            ],
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
      _Shimmer(height: 110),
      SizedBox(height: 10),
      _Shimmer(height: 80),
    ],
  );
}

// ── En Vivo card (Inicio) ─────────────────────────────────────────────────────

class _EnVivoManagerCard extends StatelessWidget {
  final List<PartidoManagerDto> partidos;
  final Color   accent;
  final String? tenantSlug;
  const _EnVivoManagerCard({required this.partidos, required this.accent, this.tenantSlug});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: partidos.isEmpty
              ? AppColors.border
              : const Color(0xFFDC2626).withValues(alpha: 0.4),
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
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${partidos.length}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ]),
        ),
        if (partidos.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: const Row(children: [
              Icon(Icons.nightlight_outlined, size: 15, color: AppColors.textHint),
              SizedBox(width: 6),
              Text('No hay partidos en vivo ahora',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
            ]),
          )
        else
          ...partidos.map((p) => _PartidoVivoManagerRow(partido: p, accent: accent, tenantSlug: tenantSlug)),
      ]),
    );
  }
}

class _PartidoVivoManagerRow extends StatelessWidget {
  final PartidoManagerDto partido;
  final Color             accent;
  final String?           tenantSlug;
  const _PartidoVivoManagerRow({required this.partido, required this.accent, this.tenantSlug});

  String _textoShare() {
    final marcador = '${partido.golesLocal} – ${partido.golesVisitante}';
    var texto = '⚽ ${partido.equipoLocalNombre} $marcador ${partido.equipoVisitanteNombre}\n'
                '🔴 En vivo';
    if (partido.canchaNombre != null) texto += '\n📍 ${partido.canchaNombre}';
    if (tenantSlug != null && tenantSlug!.isNotEmpty) {
      texto += '\n${Env.webUrl}/c/$tenantSlug/partidos/${partido.id}';
    }
    return texto;
  }

  @override
  Widget build(BuildContext context) {
    final publicoUrl = (tenantSlug != null && tenantSlug!.isNotEmpty)
        ? '${Env.webUrl}/c/$tenantSlug/partidos/${partido.id}'
        : null;

    return Column(children: [
      const Divider(height: 0, thickness: 0.5, color: AppColors.border),
      InkWell(
        onTap: () => context.push('/manager/partidos/${partido.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFDC2626)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(partido.canchaNombre ?? '—',
                  style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
            ])),
            Text('${partido.golesLocal} – ${partido.golesVisitante}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: accent, letterSpacing: 1)),
          ]),
        ),
      ),
      const Divider(height: 0, thickness: 0.5, color: AppColors.border),
      _AccionesEnVivoStrip(
        textoShare: _textoShare(),
        publicoUrl: publicoUrl,
        onEnVivo:   () => context.push('/manager/partidos/${partido.id}'),
      ),
    ]);
  }
}

// ── Próximos card (Inicio) ────────────────────────────────────────────────────

class _ProximosManagerCard extends StatelessWidget {
  final List<PartidoManagerDto> partidos;
  final Color accent;
  const _ProximosManagerCard({required this.partidos, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: const Text('Próximos partidos',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
        ...partidos.take(3).map((p) => _ProximoRow(partido: p, accent: accent)),
        const SizedBox(height: 4),
      ]),
    );
  }
}

class _ProximoRow extends StatelessWidget {
  final PartidoManagerDto partido;
  final Color accent;
  const _ProximoRow({required this.partido, required this.accent});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM HH:mm', 'es_MX');
    return Column(children: [
      const Divider(height: 0, thickness: 0.5, color: AppColors.border),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(fmt.format(partido.fechaHora),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accent)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(
            '${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}',
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          )),
        ]),
      ),
    ]);
  }
}

// ── Stats row (Inicio) ────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final ManagerDashboardDto dash;
  final Color accent;
  const _StatsRow({required this.dash, required this.accent});

  @override
  Widget build(BuildContext context) {
    final fmtPesos = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    return Row(children: [
      Expanded(child: _StatChip(
        icon: Icons.person_outline, color: accent,
        label: '${dash.jugadoresActivos}', sub: 'Jugadores',
      )),
      const SizedBox(width: 8),
      Expanded(child: _StatChip(
        icon: Icons.block_outlined, color: AppColors.error,
        label: '${dash.jugadoresSancionados}', sub: 'Sancionados',
      )),
      const SizedBox(width: 8),
      Expanded(child: _StatChip(
        icon: Icons.payments_outlined, color: AppColors.success,
        label: '${dash.cuotasPendientes}',
        sub: fmtPesos.format(dash.montoCuotasPendientes),
      )),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final String   sub;
  const _StatChip({required this.icon, required this.color, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 9, color: AppColors.textHint),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Posición card (Inicio) ────────────────────────────────────────────────────

class _PosicionCard extends StatelessWidget {
  final FilaPosicionDto pos;
  final Color accent;
  const _PosicionCard({required this.pos, required this.accent});

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
        const Text('Posición en tabla',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('${pos.posicion}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(pos.nombre,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          _PosCell('PJ', '${pos.pj}'),
          _PosCell('PG', '${pos.pg}'),
          _PosCell('PE', '${pos.pe}'),
          _PosCell('PP', '${pos.pp}'),
          _PosCell('DG', '${pos.dg > 0 ? '+' : ''}${pos.dg}'),
          _PosCell('Pts', '${pos.pts}', bold: true, color: accent),
        ]),
      ]),
    );
  }
}

class _PosCell extends StatelessWidget {
  final String label;
  final String value;
  final bool   bold;
  final Color? color;
  const _PosCell(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(
          fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: color ?? AppColors.textPrimary,
        )),
      ]),
    );
  }
}

// ── Partidos body ─────────────────────────────────────────────────────────────

class _ManagerPartidosBody extends StatefulWidget {
  final String? equipoId;
  final Color   accent;
  const _ManagerPartidosBody({required this.equipoId, required this.accent});

  @override
  State<_ManagerPartidosBody> createState() => _ManagerPartidosBodyState();
}

class _ManagerPartidosBodyState extends State<_ManagerPartidosBody> {
  final _repo    = ManagerRepository();
  List<PartidoManagerDto> _partidos = [];
  bool _loading  = false;
  String? _error;
  int  _filtro   = 0; // 0=Todos 1=En Vivo 2=Próximos 3=Terminados

  static const _labels = ['Todos', 'En Vivo', 'Próximos', 'Terminados'];

  @override
  void initState() {
    super.initState();
    if (widget.equipoId != null) _cargar();
  }

  @override
  void didUpdateWidget(_ManagerPartidosBody old) {
    super.didUpdateWidget(old);
    if (old.equipoId != widget.equipoId && widget.equipoId != null) {
      _cargar();
    }
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final lista = await _repo.listarPartidos(widget.equipoId!);
      if (mounted) setState(() { _partidos = lista; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<PartidoManagerDto> get _filtrados => switch (_filtro) {
        1 => _partidos.where((p) => p.estado == EstadoPartido.enCurso).toList(),
        2 => _partidos.where((p) => p.estado == EstadoPartido.programado).toList(),
        3 => _partidos.where((p) => p.estado == EstadoPartido.terminado).toList(),
        _ => _partidos,
      };

  @override
  Widget build(BuildContext context) {
    final tenantSlug = context.read<AuthProvider>().token?.tenantSlug;

    if (widget.equipoId == null) return const _InfoCard(icon: Icons.shield_outlined, texto: 'Sin equipo activo');
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _InfoCard(icon: Icons.error_outline, texto: _error!, onRetry: _cargar);
    }

    return Column(children: [
      // Filtros
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: List.generate(_labels.length, (i) => Padding(
            padding: EdgeInsets.only(right: i < _labels.length - 1 ? 8 : 0),
            child: ChoiceChip(
              label: Text(_labels[i], style: const TextStyle(fontSize: 11)),
              selected: _filtro == i,
              onSelected: (_) => setState(() => _filtro = i),
              selectedColor: widget.accent.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: _filtro == i ? widget.accent : AppColors.textSecondary,
                fontWeight: _filtro == i ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ))),
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          color: widget.accent,
          onRefresh: _cargar,
          child: _filtrados.isEmpty
              ? const _InfoCard(icon: Icons.calendar_today_outlined, texto: 'Sin partidos')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
                  itemCount: _filtrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _PartidoCard(
                    partido:     _filtrados[i],
                    accent:      widget.accent,
                    tenantSlug:  tenantSlug,
                    equipoId:    widget.equipoId!,
                    onUpdated:   _cargar,
                  ),
                ),
        ),
      ),
    ]);
  }
}

class _PartidoCard extends StatelessWidget {
  final PartidoManagerDto partido;
  final Color   accent;
  final String? tenantSlug;
  final String  equipoId;
  final VoidCallback onUpdated;
  const _PartidoCard({
    required this.partido, required this.accent,
    required this.tenantSlug, required this.equipoId,
    required this.onUpdated,
  });

  String _textoShare() {
    final marcador = '${partido.golesLocal} – ${partido.golesVisitante}';
    var texto = '⚽ ${partido.equipoLocalNombre} $marcador ${partido.equipoVisitanteNombre}';
    if (partido.estado == EstadoPartido.enCurso) texto += '\n🔴 En vivo';
    if (partido.canchaNombre != null) texto += '\n📍 ${partido.canchaNombre}';
    if (tenantSlug != null && tenantSlug!.isNotEmpty) {
      texto += '\n${Env.webUrl}/c/$tenantSlug/partidos/${partido.id}';
    }
    return texto;
  }

  @override
  Widget build(BuildContext context) {
    final p          = partido;
    final enCurso    = p.estado == EstadoPartido.enCurso;
    final terminado  = p.estado == EstadoPartido.terminado;
    final fmt        = DateFormat('EEE dd/MM  HH:mm', 'es_MX');
    final publicoUrl = (tenantSlug != null && tenantSlug!.isNotEmpty)
        ? '${Env.webUrl}/c/$tenantSlug/partidos/${p.id}'
        : null;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enCurso ? const Color(0xFFDC2626).withValues(alpha: 0.4) : AppColors.border,
          width: enCurso ? 1 : 0.5,
        ),
      ),
      child: Column(children: [
        // Cabecera
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(fmt.format(p.fechaHora),
                  style: const TextStyle(fontSize: 10, color: AppColors.textHint))),
              _BadgeEstado(estado: p.estado, label: p.estadoLabel),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Expanded(child: Text(p.equipoLocalNombre,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  (enCurso || terminado)
                      ? '${p.golesLocal}–${p.golesVisitante}'
                      : 'vs',
                  style: TextStyle(
                    fontSize: (enCurso || terminado) ? 18 : 14,
                    fontWeight: FontWeight.w800,
                    color: enCurso ? const Color(0xFFDC2626) : AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(child: Text(p.equipoVisitanteNombre,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            if (p.canchaNombre != null) ...[
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.place_outlined, size: 12, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(p.canchaNombre!,
                    style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
              ]),
            ],
          ]),
        ),

        // Action strip for EnCurso
        if (enCurso) ...[
          const Divider(height: 0, thickness: 0.5, color: AppColors.border),
          _AccionesEnVivoStrip(
            textoShare: _textoShare(),
            publicoUrl: publicoUrl,
            onEnVivo:   () => context.push('/manager/partidos/${p.id}'),
          ),
        ],

        // Confirmaciones (todos los estados) + Calificar árbitro (Terminado)
        const Divider(height: 0, thickness: 0.5, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.people_outline, size: 14),
              label: const Text('Confirmaciones', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                side: BorderSide(color: accent.withValues(alpha: 0.4)),
                foregroundColor: accent,
              ),
              onPressed: () => context.push(
                '/manager/confirmaciones/$equipoId/${p.id}',
              ),
            )),
            if (!terminado) ...[
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.sports_soccer_outlined, size: 14),
                label: const Text('Alineación', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  side: BorderSide(color: accent.withValues(alpha: 0.4)),
                  foregroundColor: accent,
                ),
                onPressed: () => context.push(
                  '/manager/alineacion/$equipoId/${p.id}',
                ),
              )),
            ],
            if (terminado && p.arbitroId != null) ...[
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.star_outline, size: 14),
                label: const Text('Calificar árbitro', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  side: BorderSide(color: Colors.amber.shade600.withValues(alpha: 0.6)),
                  foregroundColor: Colors.amber.shade700,
                ),
                onPressed: () => _abrirCalificarSheet(context, p),
              )),
            ],
          ]),
        ),
      ]),
    );
  }

  void _abrirCalificarSheet(BuildContext context, PartidoManagerDto p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CalificarArbitroSheet(
        equipoId:    equipoId,
        partido:     p,
        onCalificado: onUpdated,
      ),
    );
  }
}

// ── Pagos body ────────────────────────────────────────────────────────────────

class _ManagerPagosBody extends StatefulWidget {
  final String? equipoId;
  final Color   accent;
  const _ManagerPagosBody({required this.equipoId, required this.accent});

  @override
  State<_ManagerPagosBody> createState() => _ManagerPagosBodyState();
}

class _ManagerPagosBodyState extends State<_ManagerPagosBody> {
  final _repo  = ManagerRepository();
  List<PagoJugadorDto> _pagos   = [];
  bool    _loading  = false;
  String? _error;
  int     _filtro   = 0; // 0=Todos 1=Pendientes 2=Pagados 3=Vencidos
  final Set<String> _procesando = {};

  static const _labels = ['Todos', 'Pendientes', 'Pagados', 'Vencidos'];

  @override
  void initState() {
    super.initState();
    if (widget.equipoId != null) _cargar();
  }

  @override
  void didUpdateWidget(_ManagerPagosBody old) {
    super.didUpdateWidget(old);
    if (old.equipoId != widget.equipoId && widget.equipoId != null) _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final lista = await _repo.obtenerPagos(widget.equipoId!);
      if (mounted) setState(() { _pagos = lista; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _togglePagado(PagoJugadorDto pago) async {
    setState(() => _procesando.add(pago.id));
    final ok = await _repo.marcarPagado(
      widget.equipoId!, pago.id, pagado: !pago.pagado,
    );
    if (ok) { await _cargar(); }
    if (mounted) { setState(() => _procesando.remove(pago.id)); }
  }

  List<PagoJugadorDto> get _filtrados => switch (_filtro) {
        1 => _pagos.where((p) => !p.pagado).toList(),
        2 => _pagos.where((p) => p.pagado).toList(),
        3 => _pagos.where((p) => p.vencido && !p.pagado).toList(),
        _ => _pagos,
      };

  @override
  Widget build(BuildContext context) {
    if (widget.equipoId == null) return const _InfoCard(icon: Icons.payments_outlined, texto: 'Sin equipo activo');
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _InfoCard(icon: Icons.error_outline, texto: _error!, onRetry: _cargar);

    final pendientes = _pagos.where((p) => !p.pagado).length;
    final fmtPesos   = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

    return Column(children: [
      // Resumen rápido
      if (_pagos.isNotEmpty)
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Row(children: [
            const Icon(Icons.pending_outlined, size: 14, color: AppColors.textHint),
            const SizedBox(width: 6),
            Text('$pendientes pendiente${pendientes == 1 ? '' : 's'} · ${fmtPesos.format(
              _pagos.where((p) => !p.pagado).fold<double>(0, (s, p) => s + p.monto),
            )}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),

      // Filtros
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: List.generate(_labels.length, (i) => Padding(
            padding: EdgeInsets.only(right: i < _labels.length - 1 ? 8 : 0),
            child: ChoiceChip(
              label: Text(_labels[i], style: const TextStyle(fontSize: 11)),
              selected: _filtro == i,
              onSelected: (_) => setState(() => _filtro = i),
              selectedColor: widget.accent.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: _filtro == i ? widget.accent : AppColors.textSecondary,
                fontWeight: _filtro == i ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ))),
        ),
      ),

      Expanded(
        child: RefreshIndicator(
          color: widget.accent,
          onRefresh: _cargar,
          child: _filtrados.isEmpty
              ? const _InfoCard(icon: Icons.payments_outlined, texto: 'Sin pagos')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
                  itemCount: _filtrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _PagoCard(
                    pago: _filtrados[i],
                    accent: widget.accent,
                    procesando: _procesando.contains(_filtrados[i].id),
                    onToggle: () => _togglePagado(_filtrados[i]),
                  ),
                ),
        ),
      ),
    ]);
  }
}

class _PagoCard extends StatelessWidget {
  final PagoJugadorDto pago;
  final Color  accent;
  final bool   procesando;
  final VoidCallback onToggle;
  const _PagoCard({required this.pago, required this.accent, required this.procesando, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final fmtPesos = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final fmtDate  = DateFormat('dd/MM/yy', 'es_MX');

    final Color estadoColor = pago.pagado
        ? AppColors.success
        : pago.vencido
            ? AppColors.error
            : AppColors.textHint;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pago.vencido && !pago.pagado
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Row(children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: accent.withValues(alpha: 0.12),
          child: Text(pago.nombreJugador.isNotEmpty ? pago.nombreJugador[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(pago.nombreJugador,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(pago.concepto, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          if (pago.partidoLabel != null)
            Text(pago.partidoLabel!, style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
          const SizedBox(height: 2),
          Row(children: [
            Icon(
              pago.pagado ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              size: 11, color: estadoColor,
            ),
            const SizedBox(width: 3),
            Text(
              pago.pagado
                  ? 'Pagado ${pago.pagadoEn != null ? fmtDate.format(pago.pagadoEn!) : ''}'
                  : pago.vencido
                      ? 'Venció ${fmtDate.format(pago.venceEn)}'
                      : 'Vence ${fmtDate.format(pago.venceEn)}',
              style: TextStyle(fontSize: 9, color: estadoColor),
            ),
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(fmtPesos.format(pago.monto),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: estadoColor)),
          const SizedBox(height: 6),
          procesando
              ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2))
              : GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: pago.pagado
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      pago.pagado ? 'Desmarcar' : 'Marcar pagado',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: pago.pagado ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ),
                ),
        ]),
      ]),
    );
  }
}

// ── Calificar árbitro BottomSheet ─────────────────────────────────────────────

class _CalificarArbitroSheet extends StatefulWidget {
  final String          equipoId;
  final PartidoManagerDto partido;
  final VoidCallback    onCalificado;
  const _CalificarArbitroSheet({required this.equipoId, required this.partido, required this.onCalificado});

  @override
  State<_CalificarArbitroSheet> createState() => _CalificarArbitroSheetState();
}

class _CalificarArbitroSheetState extends State<_CalificarArbitroSheet> {
  final _repo   = ManagerRepository();
  int     _stars    = 0;
  String  _comment  = '';
  bool    _loading  = false;
  bool    _yaCalificado = false;
  int     _calActual    = 0;

  @override
  void initState() {
    super.initState();
    _cargarCalificacion();
  }

  Future<void> _cargarCalificacion() async {
    final data = await _repo.obtenerCalificacionArbitro(widget.equipoId, widget.partido.id);
    if (data != null && mounted) {
      setState(() {
        _yaCalificado = true;
        _calActual = data['calificacion'] as int? ?? 0;
        _stars     = _calActual;
        _comment   = data['comentario'] as String? ?? '';
      });
    }
  }

  Future<void> _guardar() async {
    if (_stars == 0) return;
    setState(() => _loading = true);
    final err = await _repo.calificarArbitro(
      widget.equipoId, widget.partido.id,
      calificacion: _stars,
      comentario:   _comment.trim().isEmpty ? null : _comment.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      widget.onCalificado();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.partido;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16, right: 16, top: 16,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Calificar árbitro', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        if (p.arbitroNombre != null)
          Text(p.arbitroNombre!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        if (_yaCalificado)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
              const SizedBox(width: 6),
              Text('Ya calificaste este árbitro ($_calActual★). Puedes actualizar.',
                  style: const TextStyle(fontSize: 11, color: AppColors.success)),
            ]),
          ),
        if (_yaCalificado) const SizedBox(height: 12),
        // Stars
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(
          icon: Icon(
            i < _stars ? Icons.star : Icons.star_border,
            color: Colors.amber.shade600, size: 32,
          ),
          onPressed: () => setState(() => _stars = i + 1),
        ))),
        const SizedBox(height: 8),
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
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: (_stars == 0 || _loading) ? null : _guardar,
            child: _loading
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Guardar calificación'),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ── Cobro por partido BottomSheet ─────────────────────────────────────────────

class _CobroPartidoSheet extends StatefulWidget {
  final String equipoId;
  final Color  accent;
  const _CobroPartidoSheet({required this.equipoId, required this.accent});

  @override
  State<_CobroPartidoSheet> createState() => _CobroPartidoSheetState();
}

class _CobroPartidoSheetState extends State<_CobroPartidoSheet> {
  final _repo = ManagerRepository();
  List<PartidoManagerDto> _partidos = [];
  String? _partidoSelId;
  final _conceptoCtrl = TextEditingController();
  final _montoCtrl    = TextEditingController();
  bool _loadingPartidos = true;
  bool _guardando       = false;

  @override
  void initState() {
    super.initState();
    _cargarPartidos();
  }

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPartidos() async {
    try {
      final lista = await _repo.listarPartidos(widget.equipoId);
      if (mounted) setState(() { _partidos = lista; _loadingPartidos = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPartidos = false);
    }
  }

  Future<void> _guardar() async {
    final concepto = _conceptoCtrl.text.trim();
    final monto    = double.tryParse(_montoCtrl.text.replaceAll(',', ''));
    if (concepto.isEmpty || monto == null || monto <= 0 || _partidoSelId == null) return;

    setState(() => _guardando = true);
    final (creados, error) = await _repo.crearCobrosPartido(
      widget.equipoId,
      partidoId: _partidoSelId!,
      concepto:  concepto,
      monto:     monto,
    );
    if (!mounted) return;
    setState(() => _guardando = false);

    if (creados != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$creados cobro${creados == 1 ? '' : 's'} creado${creados == 1 ? '' : 's'}')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'No se pudo crear el cobro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16, right: 16, top: 16,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Cobro por partido', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Crea un cobro para todos los jugadores de un partido.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        if (_loadingPartidos)
          const Center(child: CircularProgressIndicator())
        else ...[
          DropdownButtonFormField<String>(
            initialValue: _partidoSelId,
            decoration: const InputDecoration(
              labelText: 'Partido',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _partidos.map((p) => DropdownMenuItem(
              value: p.id,
              child: Text(
                '${p.equipoLocalNombre} vs ${p.equipoVisitanteNombre}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),
            onChanged: (v) => setState(() => _partidoSelId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _conceptoCtrl,
            decoration: const InputDecoration(
              labelText: 'Concepto',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _montoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto (\$)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: widget.accent),
              onPressed: (_guardando || _partidoSelId == null) ? null : _guardar,
              child: _guardando
                  ? const SizedBox(height: 16, width: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Crear cobro para todos'),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ── En Vivo action strip ──────────────────────────────────────────────────────

class _AccionesEnVivoStrip extends StatelessWidget {
  final String   textoShare;
  final String?  publicoUrl;
  final VoidCallback onEnVivo;
  const _AccionesEnVivoStrip({required this.textoShare, this.publicoUrl, required this.onEnVivo});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(children: [
        _StripBtn(icon: Icons.share_outlined, label: 'Compartir',
            onTap: () {
              final box = context.findRenderObject() as RenderBox?;
              Share.share(
                textoShare,
                sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
              );
            }),
        const VerticalDivider(width: 0, thickness: 0.5, color: AppColors.border),
        _StripBtn(
          icon: Icons.chat_outlined, label: 'WhatsApp',
          onTap: () => launchUrl(
            Uri.parse('https://wa.me/?text=${Uri.encodeComponent(textoShare)}'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const VerticalDivider(width: 0, thickness: 0.5, color: AppColors.border),
        _StripBtn(
          icon: Icons.radio_button_checked, label: 'Minuto a minuto',
          color: const Color(0xFFDC2626), onTap: onEnVivo,
        ),
        const VerticalDivider(width: 0, thickness: 0.5, color: AppColors.border),
        _StripBtn(
          icon: Icons.visibility_outlined, label: 'Público',
          enabled: publicoUrl != null,
          onTap: publicoUrl != null
              ? () => launchUrl(Uri.parse(publicoUrl!), mode: LaunchMode.externalApplication)
              : null,
        ),
      ]),
    );
  }
}

class _StripBtn extends StatelessWidget {
  final IconData    icon;
  final String      label;
  final Color?      color;
  final bool        enabled;
  final VoidCallback? onTap;
  const _StripBtn({required this.icon, required this.label, this.color, this.enabled = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = enabled
        ? (color ?? AppColors.textSecondary)
        : AppColors.textHint;
    return Expanded(child: InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ]),
      ),
    ));
  }
}

// ── Badge de estado ───────────────────────────────────────────────────────────

class _BadgeEstado extends StatelessWidget {
  final EstadoPartido estado;
  final String        label;
  const _BadgeEstado({required this.estado, required this.label});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (estado) {
      EstadoPartido.enCurso    => (const Color(0xFFFEE2E2), AppColors.error),
      EstadoPartido.terminado  => (const Color(0xFFE2E8F0), AppColors.textSecondary),
      EstadoPartido.programado => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      _                        => (const Color(0xFFF1F5F9), AppColors.textHint),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData     icon;
  final String       texto;
  final VoidCallback? onRetry;
  const _InfoCard({required this.icon, required this.texto, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 36, color: AppColors.textHint),
        const SizedBox(height: 10),
        Text(texto, style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ]),
    ));
  }
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _ctrl,
    child: Container(
      width: 8, height: 8,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFDC2626)),
    ),
  );
}

class _Shimmer extends StatelessWidget {
  final double height;
  const _Shimmer({required this.height});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(14),
    ),
  );
}
