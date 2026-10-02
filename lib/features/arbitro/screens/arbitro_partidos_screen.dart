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
import '../../../shared/enums/estado_partido.dart';
import '../data/arbitro_repository.dart';
import '../providers/arbitro_provider.dart';

class ArbitroPartidosScreen extends StatefulWidget {
  const ArbitroPartidosScreen({super.key});

  @override
  State<ArbitroPartidosScreen> createState() => _ArbitroPartidosScreenState();
}

class _ArbitroPartidosScreenState extends State<ArbitroPartidosScreen> {
  final _repo = ArbitroRepository();

  List<PartidoResumenDto> _todos    = [];
  bool                    _cargando = false;
  String?                 _error;
  int?                    _estadoFiltro; // null=todos, 1=programado, 2=encurso, 3=terminado

  static const _tabs = [
    (null,  'Todos'),
    (2,     '🔴 En vivo'),
    (1,     'Próximos'),
    (3,     'Terminados'),
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() { _cargando = true; _error = null; });
    try {
      final list = await _repo.listarPartidos(estado: _estadoFiltro);
      if (!mounted) return;
      setState(() { _todos = list; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Error al cargar partidos.'; _cargando = false; });
    }
  }

  void _setFiltro(int? estado) {
    if (_estadoFiltro == estado) return;
    setState(() { _estadoFiltro = estado; _todos = []; });
    _cargar();
  }

  Future<void> _iniciar(BuildContext ctx, PartidoResumenDto p) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Iniciar partido'),
        content: Text('¿Confirmas que vas a iniciar\n${p.equipoLocalNombre} vs ${p.equipoVisitanteNombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),  child: const Text('Iniciar')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final err = await context.read<ArbitroProvider>().iniciarPartido(p.id);
    if (!mounted) return;
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
    final accent = RolePalettes.accentForRol('Arbitro');

    return RefreshIndicator(
      color: accent,
      onRefresh: _cargar,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Filtros
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tabs.map((tab) {
                    final (val, lbl) = tab;
                    final activo = _estadoFiltro == val;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _setFiltro(val),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: activo ? accent : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: activo ? accent : AppColors.border,
                              width: activo ? 1.5 : 0.5,
                            ),
                          ),
                          child: Text(lbl,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                                color: activo ? Colors.white : AppColors.textPrimary,
                              )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Contenido
          if (_cargando && _todos.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cloud_off_outlined, size: 28, color: AppColors.textHint),
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                ]),
              ),
            )
          else if (_todos.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_month_outlined, size: 32, color: AppColors.textHint),
                  SizedBox(height: 8),
                  Text('No hay partidos para este filtro',
                      style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                ]),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 104),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PartidoCard(
                      partido: _todos[i],
                      accent: accent,
                      onIniciar: () => _iniciar(context, _todos[i]),
                    ),
                  ),
                  childCount: _todos.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PartidoCard extends StatelessWidget {
  final PartidoResumenDto partido;
  final Color             accent;
  final VoidCallback      onIniciar;

  const _PartidoCard({
    required this.partido,
    required this.accent,
    required this.onIniciar,
  });

  static const _meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];

  Widget _fechaCol(DateTime fh) => SizedBox(
    width: 40,
    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text('${fh.day}',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: accent, height: 1)),
      Text(_meses[fh.month - 1],
          style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
      Text('${fh.hour.toString().padLeft(2,'0')}:${fh.minute.toString().padLeft(2,'0')}',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textHint)),
    ]),
  );

  Widget _badgeEstado(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg)),
  );

  @override
  Widget build(BuildContext context) {
    final p  = partido;
    final fh = p.fechaHora;

    // ── EN VIVO: card con tira de acciones ─────────────────────────────────
    if (p.estado == EstadoPartido.enCurso) {
      final tenantSlug = context.read<AuthProvider>().token?.tenantSlug;
      final publicoUrl = (tenantSlug != null && tenantSlug.isNotEmpty)
          ? '${Env.webUrl}/c/$tenantSlug/partidos/${p.id}'
          : null;
      final textoShare = () {
        final marc = '${p.golesLocal} – ${p.golesVisitante}';
        var txt = '⚽ ${p.equipoLocalNombre} $marc ${p.equipoVisitanteNombre}\n🔴 En vivo';
        if (p.canchaNombre != null) txt += '\n📍 ${p.canchaNombre}';
        if (publicoUrl != null) txt += '\n$publicoUrl';
        return txt;
      }();

      return Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
        ),
        child: Column(children: [
          InkWell(
            onTap: () => context.push('/staff/envivo/${p.id}'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                _fechaCol(fh),
                Container(width: 1, height: 44, color: AppColors.border,
                    margin: const EdgeInsets.symmetric(horizontal: 12)),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${p.equipoLocalNombre} vs ${p.equipoVisitanteNombre}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${p.canchaNombre ?? '—'} · ${p.ligaNombre}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                      overflow: TextOverflow.ellipsis),
                ])),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${p.golesLocal} – ${p.golesVisitante}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                          color: Color(0xFFD97706), letterSpacing: 1)),
                  const SizedBox(height: 3),
                  _badgeEstado('EN VIVO', const Color(0xFFFEF2F2), const Color(0xFFDC2626)),
                ]),
              ]),
            ),
          ),
          const Divider(height: 0, thickness: 0.5, color: AppColors.border),
          _AccionesEnVivoStrip(
            textoShare: textoShare,
            publicoUrl: publicoUrl,
            onEnVivo:   () => context.push('/staff/envivo/${p.id}'),
          ),
        ]),
      );
    }

    // ── OTROS ESTADOS: card simple ──────────────────────────────────────────
    Color estadoColor;
    Color estadoBg;
    String estadoLabel;

    switch (p.estado) {
      case EstadoPartido.terminado:
        estadoColor = AppColors.textHint;
        estadoBg    = AppColors.border.withValues(alpha: 0.4);
        estadoLabel = 'TERMINADO';
      default:
        estadoColor = accent;
        estadoBg    = accent.withValues(alpha: 0.08);
        estadoLabel = p.estadoLabel.toUpperCase();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        _fechaCol(fh),
        Container(width: 1, height: 44, color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 12)),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p.equipoLocalNombre} vs ${p.equipoVisitanteNombre}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${p.canchaNombre ?? '—'} · ${p.ligaNombre}',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (p.estado == EstadoPartido.terminado)
            Text('${p.golesLocal} – ${p.golesVisitante}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: Color(0xFFD97706), letterSpacing: 1)),
          const SizedBox(height: 3),
          _badgeEstado(estadoLabel, estadoBg, estadoColor),
          if (p.estado == EstadoPartido.programado) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onIniciar,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
                child: const Text('▶ Iniciar',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

// ── Barra de acciones en vivo ─────────────────────────────────────────────────

class _AccionesEnVivoStrip extends StatelessWidget {
  const _AccionesEnVivoStrip({
    required this.textoShare,
    required this.onEnVivo,
    this.publicoUrl,
  });

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
