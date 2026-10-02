import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/config/env.dart';
import '../../../core/network/signalr_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../features/staff/providers/staff_dashboard_provider.dart';
import '../../../models/staff_dashboard_dto.dart';
import '../../../shared/widgets/pitazo_scaffold.dart';
import 'canchas_screen.dart';
import 'comunicados_screen.dart';
import 'equipos_screen.dart';
import 'partidos_screen.dart';
import 'reservas_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final tieneReservas = context.watch<StaffDashboardProvider>().tieneReservas;

    if (!tieneReservas && _activeTab == 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _activeTab = 0);
      });
    }

    final comunicadosIdx = tieneReservas ? 5 : 4;
    final tabActivo      = _activeTab.clamp(0, comunicadosIdx);
    final esReservas     = tieneReservas && tabActivo == 4;
    final esComunicados  = tabActivo == comunicadosIdx;

    final primaryNav = [
      const PitazoNavItem(icon: Icons.dashboard_outlined,        label: 'Inicio'),
      const PitazoNavItem(icon: Icons.sports_soccer,             label: 'Partidos'),
      const PitazoNavItem(icon: Icons.shield_outlined,           label: 'Equipos'),
      const PitazoNavItem(icon: Icons.stadium_outlined,          label: 'Canchas'),
      if (tieneReservas)
        const PitazoNavItem(icon: Icons.event_available_outlined, label: 'Reservas'),
      const PitazoNavItem(icon: Icons.campaign_outlined,         label: 'Comunicados'),
    ];

    final screens = [
      const _AdminDashboardBody(),
      const AdminPartidosScreen(),
      const StaffEquiposScreen(),
      const AdminCanchasScreen(),
      if (tieneReservas) const StaffReservasScreen(),
      const StaffComunicadosScreen(),
    ];

    return PitazoScaffold(
      primaryNav: primaryNav,
      onTabChanged: (i) => setState(() => _activeTab = i),
      onAvatarTap: () => context.push('/admin/perfil'),
      floatingActionButton: esReservas
          ? FloatingActionButton(
              onPressed: () => StaffReservasScreen.abrirNueva(context),
              child: const Icon(Icons.add),
            )
          : esComunicados
              ? FloatingActionButton(
                  onPressed: () => StaffComunicadosScreen.abrirNuevo(context),
                  child: const Icon(Icons.add),
                )
              : null,
      child: IndexedStack(
        index: tabActivo,
        children: screens,
      ),
    );
  }
}

// ── Cuerpo del dashboard de Admin ─────────────────────────────────────────────

class _AdminDashboardBody extends StatefulWidget {
  const _AdminDashboardBody();

  @override
  State<_AdminDashboardBody> createState() => _AdminDashboardBodyState();
}

class _LiveState {
  final int golesLocal;
  final int golesVisitante;
  final int minuto;
  const _LiveState({required this.golesLocal, required this.golesVisitante, required this.minuto});
}

class _AdminDashboardBodyState extends State<_AdminDashboardBody> {
  final Map<String, _LiveState> _liveState = {};
  final List<PartidoSignalRService> _signalRs = [];
  final List<String> _connectedIds = [];
  StaffDashboardProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider = context.read<StaffDashboardProvider>();
      _provider!.addListener(_onProviderChanged);
      if (_provider!.data == null && !_provider!.loading) _provider!.load();
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChanged);
    for (final s in _signalRs) { s.dispose(); }
    super.dispose();
  }

  void _onProviderChanged() {
    _reconectarSignalR(_provider?.data?.partidosEnVivo ?? []);
  }

  void _reconectarSignalR(List<PartidoEnVivoDto> partidos) {
    final newIds = partidos.map((p) => p.id).toList()..sort();
    final curIds = List<String>.from(_connectedIds)..sort();
    if (newIds.toString() == curIds.toString()) return;

    for (final s in _signalRs) { s.dispose(); }
    _signalRs.clear();
    _connectedIds..clear()..addAll(partidos.map((p) => p.id));

    for (final p in partidos) {
      final svc = PartidoSignalRService(p.id, Env.apiUrl);
      svc.connect(
        onEventoAgregado: (minuto, gl, gv) {
          if (!mounted) return;
          setState(() => _liveState[p.id] = _LiveState(golesLocal: gl, golesVisitante: gv, minuto: minuto));
        },
        onEventoEliminado: (gl, gv) {
          if (!mounted) return;
          setState(() {
            final cur = _liveState[p.id];
            _liveState[p.id] = _LiveState(golesLocal: gl, golesVisitante: gv, minuto: cur?.minuto ?? p.minuto);
          });
        },
        onPartidoTerminado: (_, __) {
          if (!mounted) return;
          context.read<StaffDashboardProvider>().loadSilent();
        },
      );
      _signalRs.add(svc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent   = RolePalettes.accentForRol('Admin');
    final provider = context.watch<StaffDashboardProvider>();
    final data     = provider.data;

    return RefreshIndicator(
      color: accent,
      onRefresh: () => context.read<StaffDashboardProvider>().refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (provider.loading && data == null)
              _buildSkeleton()
            else if (provider.error != null && data == null)
              _ErrorCard(mensaje: provider.error!, onRetry: () => context.read<StaffDashboardProvider>().load())
            else ...[
              _EnVivoCard(partidos: data?.partidosEnVivo ?? [], liveState: _liveState, accent: accent),
              const SizedBox(height: 8),
              _StatsRow(
                canchas:   data?.totalCanchas   ?? 0,
                ligas:     data?.totalLigas     ?? 0,
                equipos:   data?.totalEquipos   ?? 0,
                jugadores: data?.totalJugadores ?? 0,
                accent:    accent,
              ),
              const SizedBox(height: 10),
              _ProximosSection(partidos: data?.proximosPartidos ?? [], accent: accent),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Shimmer(height: 90, radius: 14),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _Shimmer(height: 62, radius: 12)),
          const SizedBox(width: 8),
          Expanded(child: _Shimmer(height: 62, radius: 12)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _Shimmer(height: 62, radius: 12)),
          const SizedBox(width: 8),
          Expanded(child: _Shimmer(height: 62, radius: 12)),
        ]),
        const SizedBox(height: 10),
        _Shimmer(height: 14, radius: 4, width: 140),
        const SizedBox(height: 8),
        _Shimmer(height: 64, radius: 14),
        const SizedBox(height: 8),
        _Shimmer(height: 64, radius: 14),
      ],
    );
  }
}

// ── Widgets internos ───────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  final double height, radius;
  final double? width;
  const _Shimmer({required this.height, required this.radius, this.width});

  @override
  Widget build(BuildContext context) => Container(
        width: width, height: height,
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorCard({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(children: [
          const Icon(Icons.cloud_off_outlined, size: 28, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(mensaje, style: const TextStyle(fontSize: 12, color: AppColors.textHint), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ]),
      );
}

class _EnVivoCard extends StatelessWidget {
  final List<PartidoEnVivoDto> partidos;
  final Map<String, _LiveState> liveState;
  final Color accent;
  const _EnVivoCard({required this.partidos, required this.liveState, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _LiveDot(),
          const SizedBox(width: 6),
          const Text('En vivo ahora',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const Spacer(),
          if (partidos.isNotEmpty)
            GestureDetector(
              onTap: () => _abrirEnVivo(context),
              child: Text('Ver en vivo',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
            ),
        ]),
        const SizedBox(height: 10),
        if (partidos.isEmpty)
          const Row(children: [
            Icon(Icons.nightlight_outlined, size: 15, color: AppColors.textHint),
            SizedBox(width: 6),
            Text('No hay partidos en vivo ahora',
                style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          ])
        else
          ...partidos.map((p) => _PartidoVivoRow(partido: p, live: liveState[p.id], accent: accent)),
      ]),
    );
  }

  void _abrirEnVivo(BuildContext context) {
    if (partidos.length == 1) {
      context.push('/staff/envivo/${partidos.first.id}');
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _SelectorPartido(partidos: partidos),
      );
    }
  }
}

class _SelectorPartido extends StatelessWidget {
  final List<PartidoEnVivoDto> partidos;
  const _SelectorPartido({required this.partidos});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Selecciona un partido',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...partidos.map((p) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(width: 7, height: 7,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFDC2626))),
                title: Text('${p.equipoLocalNombre} vs ${p.equipoVisitanteNombre}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(p.canchaNombre ?? '',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                trailing: Text('${p.golesLocal} — ${p.golesVisitante}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                onTap: () { Navigator.pop(context); context.push('/staff/envivo/${p.id}'); },
              )),
        ],
      ),
    );
  }
}

class _PartidoVivoRow extends StatelessWidget {
  final PartidoEnVivoDto partido;
  final _LiveState? live;
  final Color accent;
  const _PartidoVivoRow({required this.partido, this.live, required this.accent});

  @override
  Widget build(BuildContext context) {
    final gl  = live?.golesLocal     ?? partido.golesLocal;
    final gv  = live?.golesVisitante ?? partido.golesVisitante;
    final min = live?.minuto         ?? partido.minuto;

    return GestureDetector(
      onTap: () => context.push('/staff/envivo/${partido.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(partido.canchaNombre ?? '—',
                style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$gl — $gv',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: accent, letterSpacing: 1)),
            const SizedBox(height: 2),
            Text("$min'",
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
          ]),
        ]),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int canchas, ligas, equipos, jugadores;
  final Color accent;
  const _StatsRow({required this.canchas, required this.ligas, required this.equipos, required this.jugadores, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.4,
      children: [
        _Stat(icon: Icons.stadium_outlined,     label: 'Canchas',   valor: '$canchas',   accent: accent),
        _Stat(icon: Icons.emoji_events_outlined, label: 'Ligas',     valor: '$ligas',     accent: accent),
        _Stat(icon: Icons.shield_outlined,       label: 'Equipos',   valor: '$equipos',   accent: accent),
        _Stat(icon: Icons.directions_run,        label: 'Jugadores', valor: '$jugadores', accent: accent),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label, valor;
  final Color accent;
  const _Stat({required this.icon, required this.label, required this.valor, required this.accent});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Icon(icon, size: 15, color: accent),
          ),
          const SizedBox(width: 10),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(valor, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ]),
        ]),
      );
}

class _ProximosSection extends StatelessWidget {
  final List<PartidoProximoDto> partidos;
  final Color accent;
  const _ProximosSection({required this.partidos, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (partidos.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Próximos partidos',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      ...partidos.asMap().entries.map((e) => Padding(
            padding: EdgeInsets.only(bottom: e.key < partidos.length - 1 ? 8 : 0),
            child: _PartidoProximoRow(partido: e.value, accent: accent, primero: e.key == 0),
          )),
    ]);
  }
}

class _PartidoProximoRow extends StatelessWidget {
  final PartidoProximoDto partido;
  final Color accent;
  final bool primero;
  const _PartidoProximoRow({required this.partido, required this.accent, required this.primero});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(children: [
          Container(width: 7, height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primero ? accent : AppColors.border)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text('${partido.canchaNombre ?? '—'} · ${partido.ligaNombre}',
                style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ])),
          Text(partido.horaFormateada,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: primero ? accent : AppColors.textHint)),
        ]),
      );
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _ctrl,
        child: Container(width: 7, height: 7,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFDC2626))),
      );
}
