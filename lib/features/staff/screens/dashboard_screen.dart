import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/env.dart';
import '../../../core/network/signalr_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/staff/providers/staff_dashboard_provider.dart';
import '../../../models/staff_dashboard_dto.dart';
import '../../../models/reserva_dto.dart';
import '../../../shared/widgets/pitazo_scaffold.dart';
import '../../admin/screens/reservas_screen.dart';
import 'staff_canchas_screen.dart';
import 'staff_partidos_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final tieneReservas = context.watch<StaffDashboardProvider>().tieneReservas;

    if (!tieneReservas && _activeTab == 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _activeTab = 0);
      });
    }

    final reservasIdx   = tieneReservas ? 4 : -1;
    final tabActivo     = _activeTab.clamp(0, tieneReservas ? 4 : 3);

    final primaryNav = [
      const PitazoNavItem(icon: Icons.dashboard_outlined,        label: 'Inicio'),
      const PitazoNavItem(icon: Icons.calendar_today_outlined,   label: 'Partidos'),
      const PitazoNavItem(icon: Icons.radio_button_checked,      label: 'En Vivo'),
      const PitazoNavItem(icon: Icons.stadium_outlined,          label: 'Canchas'),
      if (tieneReservas)
        const PitazoNavItem(icon: Icons.event_available_outlined, label: 'Reservas'),
    ];

    final screens = [
      const _StaffDashboardBody(),
      const StaffPartidosScreen(),
      const _EnVivoTab(),
      const StaffCanchasScreen(),
      if (tieneReservas) const StaffReservasScreen(),
    ];

    return PitazoScaffold(
      primaryNav: primaryNav,
      onTabChanged: (i) => setState(() => _activeTab = i),
      onAvatarTap: () => context.push('/staff/perfil'),
      floatingActionButton: tieneReservas && tabActivo == reservasIdx
          ? FloatingActionButton(
              onPressed: () => StaffReservasScreen.abrirNueva(context),
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

// ── Dashboard body ────────────────────────────────────────────────────────────

class _StaffDashboardBody extends StatefulWidget {
  const _StaffDashboardBody();

  @override
  State<_StaffDashboardBody> createState() => _StaffDashboardBodyState();
}

class _LiveState {
  final int golesLocal;
  final int golesVisitante;
  final int minuto;
  const _LiveState({required this.golesLocal, required this.golesVisitante, required this.minuto});
}

class _StaffDashboardBodyState extends State<_StaffDashboardBody> {
  final Map<String, _LiveState>        _liveState = {};
  final List<PartidoSignalRService>    _signalRs  = [];
  final List<String>                   _connectedIds = [];
  StaffDashboardProvider?              _provider;

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
    final accent   = RolePalettes.accentForRol('Staff');
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
            if (data == null && provider.error == null)
              _buildSkeleton()
            else if (data == null && provider.error != null)
              _ErrorCard(mensaje: provider.error!, onRetry: () => context.read<StaffDashboardProvider>().load())
            else ...[
              // Contadores partidos hoy
              _ContadoresHoy(data: data!, accent: accent),
              const SizedBox(height: 8),
              // En Vivo
              _EnVivoCard(partidos: data.partidosEnVivo, liveState: _liveState, accent: accent),
              // Reservas hoy
              if (data.reservasCanchasActiva && data.reservasHoy.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ReservasHoyCard(reservas: data.reservasHoy, accent: accent),
              ],
              // Próximos partidos
              if (data.proximosPartidos.isNotEmpty) ...[
                const SizedBox(height: 10),
                _ProximosSection(partidos: data.proximosPartidos, accent: accent),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: _Shimmer(height: 72, radius: 12)),
            const SizedBox(width: 8),
            Expanded(child: _Shimmer(height: 72, radius: 12)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _Shimmer(height: 72, radius: 12)),
            const SizedBox(width: 8),
            Expanded(child: _Shimmer(height: 72, radius: 12)),
          ]),
          const SizedBox(height: 8),
          _Shimmer(height: 90, radius: 14),
          const SizedBox(height: 10),
          _Shimmer(height: 14, radius: 4, width: 140),
          const SizedBox(height: 8),
          _Shimmer(height: 64, radius: 14),
          const SizedBox(height: 8),
          _Shimmer(height: 64, radius: 14),
        ],
      );
}

// ── Contadores ────────────────────────────────────────────────────────────────

class _ContadoresHoy extends StatelessWidget {
  final StaffDashboardData data;
  final Color accent;
  const _ContadoresHoy({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        _Contador(label: 'PARTIDOS HOY',  valor: data.totalPartidos, color: accent),
        _Contador(label: 'EN CURSO',       valor: data.enCurso,       color: const Color(0xFFDC2626)),
        _Contador(label: 'POR INICIAR',    valor: data.porIniciar,    color: const Color(0xFFD97706)),
        _Contador(label: 'TERMINADOS',     valor: data.terminados,    color: const Color(0xFF16A34A)),
      ],
    );
  }
}

class _Contador extends StatelessWidget {
  final String label;
  final int    valor;
  final Color  color;
  const _Contador({required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$valor',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, height: 1),
            ),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.textHint, letterSpacing: 0.5)),
          ],
        ),
      );
}

// ── En Vivo card ──────────────────────────────────────────────────────────────

class _EnVivoCard extends StatelessWidget {
  final List<PartidoEnVivoDto>  partidos;
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

class _PartidoVivoRow extends StatelessWidget {
  final PartidoEnVivoDto partido;
  final _LiveState?      live;
  final Color            accent;
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

// ── Reservas hoy ─────────────────────────────────────────────────────────────

class _ReservasHoyCard extends StatelessWidget {
  final List<ReservaDto> reservas;
  final Color            accent;
  const _ReservasHoyCard({required this.reservas, required this.accent});

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
        const Text('Reservas hoy',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        ...reservas.map((r) => _ReservaRow(reserva: r)),
      ]),
    );
  }
}

class _ReservaRow extends StatelessWidget {
  final ReservaDto reserva;
  const _ReservaRow({required this.reserva});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(children: [
        Text(
          reserva.horaInicioDisplay,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(reserva.nombreCliente,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis),
          Text(reserva.nombreCancha,
              style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: reserva.estado.bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(reserva.estado.label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: reserva.estado.color)),
        ),
      ]),
    );
  }
}

// ── Próximos partidos ─────────────────────────────────────────────────────────

class _ProximosSection extends StatelessWidget {
  final List<PartidoProximoDto> partidos;
  final Color                   accent;
  const _ProximosSection({required this.partidos, required this.accent});

  @override
  Widget build(BuildContext context) {
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
  final Color             accent;
  final bool              primero;
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
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: primero ? accent : AppColors.border)),
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

// ── Tab: En Vivo ──────────────────────────────────────────────────────────────

class _EnVivoTab extends StatelessWidget {
  const _EnVivoTab();

  @override
  Widget build(BuildContext context) {
    final accent   = RolePalettes.accentForRol('Staff');
    final provider = context.watch<StaffDashboardProvider>();
    final partidos = provider.data?.partidosEnVivo ?? [];

    if (provider.loading && provider.data == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (partidos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radio_button_unchecked, size: 36, color: AppColors.textHint),
            SizedBox(height: 10),
            Text('No hay partidos en vivo ahora',
                style: TextStyle(fontSize: 13, color: AppColors.textHint)),
          ],
        ),
      );
    }

    final tenantSlug = context.read<AuthProvider>().token?.tenantSlug;

    return RefreshIndicator(
      color: accent,
      onRefresh: () => context.read<StaffDashboardProvider>().refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 104),
        itemCount: partidos.length,
        itemBuilder: (_, i) {
          final p = partidos[i];
          return Card(
            margin:       const EdgeInsets.only(bottom: 8),
            elevation:    0,
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            color: AppColors.surface,
            child: Column(children: [
              InkWell(
                onTap: () => context.push('/staff/envivo/${p.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(width: 8, height: 8,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFDC2626))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${p.equipoLocalNombre} vs ${p.equipoVisitanteNombre}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(p.canchaNombre ?? '—',
                          style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${p.golesLocal} — ${p.golesVisitante}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                              color: accent, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text("${p.minuto}'",
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                              color: Color(0xFFDC2626))),
                    ]),
                  ]),
                ),
              ),
              const Divider(height: 0, thickness: 0.5, color: AppColors.border),
              _EnVivoAccionesStrip(partido: p, tenantSlug: tenantSlug),
            ]),
          );
        },
      ),
    );
  }
}


// ── Helpers ───────────────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  final double height, radius;
  final double? width;
  const _Shimmer({required this.height, required this.radius, this.width});

  @override
  Widget build(BuildContext context) => Container(
        width: width, height: height,
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
          Text(mensaje, style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
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

// ── Barra de acciones rápidas (tab En Vivo) ───────────────────────────────────

class _EnVivoAccionesStrip extends StatelessWidget {
  const _EnVivoAccionesStrip({required this.partido, this.tenantSlug});

  final PartidoEnVivoDto partido;
  final String?          tenantSlug;

  String _textoShare() {
    final marcador = '${partido.golesLocal} – ${partido.golesVisitante}';
    var texto = '⚽ ${partido.equipoLocalNombre} $marcador ${partido.equipoVisitanteNombre}\n'
                '🔴 En vivo';
    if (partido.canchaNombre != null) texto += '\n📍 ${partido.canchaNombre}';
    if (tenantSlug != null) {
      texto += '\n${Env.webUrl}/c/$tenantSlug/partidos/${partido.id}';
    }
    return texto;
  }

  @override
  Widget build(BuildContext context) {
    final publicoUrl = tenantSlug != null
        ? '${Env.webUrl}/c/$tenantSlug/partidos/${partido.id}'
        : null;

    return IntrinsicHeight(
      child: Row(children: [
        _DashStripBtn(
          icon:  Icons.share_outlined,
          label: 'Compartir',
          onTap: () {
            final box = context.findRenderObject() as RenderBox?;
            Share.share(
              _textoShare(),
              sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
            );
          },
        ),
        const VerticalDivider(width: 0, thickness: 0.5, color: AppColors.border),
        _DashStripBtn(
          icon:  Icons.chat_outlined,
          label: 'WhatsApp',
          onTap: () => launchUrl(
            Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_textoShare())}'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const VerticalDivider(width: 0, thickness: 0.5, color: AppColors.border),
        _DashStripBtn(
          icon:  Icons.radio_button_checked,
          label: 'Minuto a minuto',
          color: const Color(0xFFDC2626),
          onTap: () => context.push('/staff/envivo/${partido.id}'),
        ),
        const VerticalDivider(width: 0, thickness: 0.5, color: AppColors.border),
        _DashStripBtn(
          icon:    Icons.visibility_outlined,
          label:   'Público',
          enabled: publicoUrl != null,
          onTap:   publicoUrl != null
              ? () => launchUrl(
                  Uri.parse(publicoUrl),
                  mode: LaunchMode.externalApplication,
                )
              : null,
        ),
      ]),
    );
  }
}

class _DashStripBtn extends StatelessWidget {
  const _DashStripBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.enabled = true,
  });

  final IconData      icon;
  final String        label;
  final VoidCallback? onTap;
  final Color?        color;
  final bool          enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled
        ? (color ?? AppColors.textHint)
        : AppColors.textHint.withValues(alpha: 0.4);

    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: effectiveColor),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(fontSize: 9, color: effectiveColor),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
