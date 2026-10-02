import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/partido_resumen_dto.dart';
import '../../../shared/widgets/pitazo_scaffold.dart';
import '../data/arbitro_repository.dart';
import '../providers/arbitro_provider.dart';
import 'arbitro_evaluaciones_screen.dart';
import 'arbitro_partidos_screen.dart';

class ArbitroDashboardScreen extends StatefulWidget {
  const ArbitroDashboardScreen({super.key});

  @override
  State<ArbitroDashboardScreen> createState() => _ArbitroDashboardScreenState();
}

class _ArbitroDashboardScreenState extends State<ArbitroDashboardScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return PitazoScaffold(
      primaryNav: const [
        PitazoNavItem(icon: Icons.dashboard_outlined,      label: 'Inicio'),
        PitazoNavItem(icon: Icons.calendar_month_outlined, label: 'Partidos'),
        PitazoNavItem(icon: Icons.star_outline,            label: 'Evaluaciones'),
      ],
      onTabChanged: (i) => setState(() => _activeTab = i),
      onAvatarTap: () => context.push('/arbitro/perfil'),
      child: IndexedStack(
        index: _activeTab,
        children: const [
          _ArbitroDashboardBody(),
          ArbitroPartidosScreen(),
          ArbitroEvaluacionesScreen(),
        ],
      ),
    );
  }
}

// ── Dashboard body ────────────────────────────────────────────────────────────

class _ArbitroDashboardBody extends StatefulWidget {
  const _ArbitroDashboardBody();

  @override
  State<_ArbitroDashboardBody> createState() => _ArbitroDashboardBodyState();
}

class _ArbitroDashboardBodyState extends State<_ArbitroDashboardBody> {
  ArbitroProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider = context.read<ArbitroProvider>();
      if (_provider!.perfil == null && !_provider!.loading) _provider!.load();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent   = RolePalettes.accentForRol('Arbitro');
    final provider = context.watch<ArbitroProvider>();

    return RefreshIndicator(
      color: accent,
      onRefresh: () => provider.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (provider.loading && provider.perfil == null)
              _buildSkeleton()
            else if (provider.perfil == null && provider.error != null)
              _ErrorCard(mensaje: provider.error!, onRetry: () => provider.load())
            else ...[
              // En Vivo
              _EnVivoCard(partidos: provider.enVivo, accent: accent),
              const SizedBox(height: 10),

              // Próximos
              if (provider.proximos.isNotEmpty) ...[
                _ProximosCard(partidos: provider.proximos, accent: accent),
                const SizedBox(height: 10),
              ],

              // Stats
              _StatsCard(
                totalPartidos:   provider.perfil?.totalPartidos    ?? 0,
                esteAnio:        provider.perfil?.partidosEsteAnio ?? 0,
                resumen:         provider.resumen,
                accent:          accent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Shimmer(height: 88, radius: 14),
          const SizedBox(height: 10),
          _Shimmer(height: 120, radius: 14),
          const SizedBox(height: 10),
          _Shimmer(height: 160, radius: 14),
        ],
      );
}

// ── En Vivo ───────────────────────────────────────────────────────────────────

class _EnVivoCard extends StatelessWidget {
  final List<PartidoResumenDto> partidos;
  final Color                   accent;
  const _EnVivoCard({required this.partidos, required this.accent});

  @override
  Widget build(BuildContext context) {
    final tenantSlug = context.read<AuthProvider>().token?.tenantSlug;

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
          ...partidos.map((p) => _PartidoVivoRow(partido: p, accent: accent, tenantSlug: tenantSlug)),
      ]),
    );
  }
}

class _PartidoVivoRow extends StatelessWidget {
  final PartidoResumenDto partido;
  final Color             accent;
  final String?           tenantSlug;
  const _PartidoVivoRow({required this.partido, required this.accent, this.tenantSlug});

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
        onTap: () => context.push('/staff/envivo/${partido.id}'),
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
        partidoId:    partido.id,
        textoShare:   _textoShare(),
        publicoUrl:   publicoUrl,
        onEnVivo:     () => context.push('/staff/envivo/${partido.id}'),
      ),
    ]);
  }
}

// ── Próximos ──────────────────────────────────────────────────────────────────

class _ProximosCard extends StatefulWidget {
  final List<PartidoResumenDto> partidos;
  final Color                   accent;
  const _ProximosCard({required this.partidos, required this.accent});

  @override
  State<_ProximosCard> createState() => _ProximosCardState();
}

class _ProximosCardState extends State<_ProximosCard> {
  final Set<String> _iniciando = {};

  Future<void> _iniciar(PartidoResumenDto p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Iniciar partido'),
        content: Text('¿Confirmas que vas a iniciar\n${p.equipoLocalNombre} vs ${p.equipoVisitanteNombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Iniciar')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _iniciando.add(p.id));
    final err = await context.read<ArbitroProvider>().iniciarPartido(p.id);
    if (!mounted) return;
    setState(() => _iniciando.remove(p.id));

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    } else {
      context.push('/staff/envivo/${p.id}');
    }
  }

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
        const Text('Próximos partidos',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        ...widget.partidos.asMap().entries.map((e) {
          final p      = e.value;
          final fh     = p.fechaHora;
          final meses  = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
          final esHoy  = fh.day == DateTime.now().day && fh.month == DateTime.now().month;
          final enInicio = _iniciando.contains(p.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(children: [
              SizedBox(
                width: 36,
                child: Column(children: [
                  if (esHoy)
                    const Text('HOY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626))),
                  Text('${fh.day}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                          color: widget.accent, height: 1)),
                  Text(meses[fh.month - 1],
                      style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
                  Text('${fh.hour.toString().padLeft(2,'0')}:${fh.minute.toString().padLeft(2,'0')}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                ]),
              ),
              Container(width: 1, height: 40, color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 10)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p.equipoLocalNombre} vs ${p.equipoVisitanteNombre}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(p.canchaNombre ?? '—',
                    style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
              ])),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: enInicio ? null : () => _iniciar(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: enInicio ? AppColors.border : widget.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: enInicio
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('▶ Iniciar',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ── Stats ─────────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final int                    totalPartidos;
  final int                    esteAnio;
  final ResumenEvaluacionesDto resumen;
  final Color                  accent;

  const _StatsCard({
    required this.totalPartidos,
    required this.esteAnio,
    required this.resumen,
    required this.accent,
  });

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
        const Text('Mis estadísticas',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),

        // Grilla 2x2
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: [
            _StatTile(valor: '$totalPartidos', label: 'PARTIDOS TOTAL', color: accent),
            _StatTile(valor: '$esteAnio',      label: 'ESTE AÑO',       color: accent),
            _StatTile(
              valor: resumen.total > 0 ? resumen.promedioGeneral.toStringAsFixed(1) : '—',
              label: 'PROMEDIO ★',
              color: const Color(0xFFF59E0B),
            ),
            _StatTile(valor: '${resumen.total}', label: 'EVALUACIONES',  color: accent),
          ],
        ),

        // Desglose criterios
        if (resumen.total > 0) ...[
          const SizedBox(height: 14),
          const Divider(height: 0, thickness: 0.5, color: AppColors.border),
          const SizedBox(height: 12),
          ...([
            ('⏰ Puntualidad',   resumen.promPuntualidad),
            ('📖 Conocimiento',  resumen.promConocimiento),
            ('🤝 Trato',         resumen.promTrato),
            ('⚖️ Imparcialidad', resumen.promImparcialidad),
          ].map((item) {
            final (lbl, val) = item;
            final pct        = val / 5.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(lbl, style: const TextStyle(fontSize: 12, color: AppColors.textHint))),
                  Text(val.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ]),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                  ),
                ),
              ]),
            );
          })),
        ],
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String valor;
  final String label;
  final Color  color;
  const _StatTile({required this.valor, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(valor,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color, height: 1)),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                    color: AppColors.textHint, letterSpacing: 0.4)),
          ],
        ),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  final double height, radius;
  const _Shimmer({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  final String       mensaje;
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
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
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

// ── Barra de acciones en vivo ─────────────────────────────────────────────────

class _AccionesEnVivoStrip extends StatelessWidget {
  const _AccionesEnVivoStrip({
    required this.partidoId,
    required this.textoShare,
    required this.onEnVivo,
    this.publicoUrl,
  });

  final String       partidoId;
  final String       textoShare;
  final String?      publicoUrl;
  final VoidCallback onEnVivo;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(children: [
        _StripBtn(
          icon:  Icons.share_outlined,
          label: 'Compartir',
          onTap: () {
            final box = context.findRenderObject() as RenderBox?;
            Share.share(
              textoShare,
              sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
            );
          },
        ),
        const VerticalDivider(width: 0, thickness: 0.5, color: AppColors.border),
        _StripBtn(
          icon:  Icons.chat_outlined,
          label: 'WhatsApp',
          onTap: () => launchUrl(
            Uri.parse('https://wa.me/?text=${Uri.encodeComponent(textoShare)}'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const VerticalDivider(width: 0, thickness: 0.5, color: AppColors.border),
        _StripBtn(
          icon:  Icons.radio_button_checked,
          label: 'Minuto a minuto',
          color: const Color(0xFFDC2626),
          onTap: onEnVivo,
        ),
        const VerticalDivider(width: 0, thickness: 0.5, color: AppColors.border),
        _StripBtn(
          icon:    Icons.visibility_outlined,
          label:   'Público',
          enabled: publicoUrl != null,
          onTap:   publicoUrl != null
              ? () => launchUrl(Uri.parse(publicoUrl!), mode: LaunchMode.externalApplication)
              : null,
        ),
      ]),
    );
  }
}

class _StripBtn extends StatelessWidget {
  const _StripBtn({
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
    final c = enabled ? (color ?? AppColors.textHint) : AppColors.textHint.withValues(alpha: 0.4);
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(fontSize: 9, color: c),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}
