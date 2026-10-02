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
import '../../admin/screens/partido_detalle_sheet.dart';
import '../data/staff_partidos_repository.dart';

class StaffPartidosScreen extends StatefulWidget {
  const StaffPartidosScreen({super.key});

  @override
  State<StaffPartidosScreen> createState() => _StaffPartidosScreenState();
}

class _StaffPartidosScreenState extends State<StaffPartidosScreen> {
  final _repo = StaffPartidosRepository();

  late DateTime               _fecha    = _diaDeHoy();
  List<PartidoResumenDto>     _partidos = [];
  bool                        _cargando = false;
  String?                     _error;

  static DateTime _diaDeHoy() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _esHoy {
    final h = _diaDeHoy();
    return _fecha.year == h.year && _fecha.month == h.month && _fecha.day == h.day;
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() { _cargando = true; _error = null; });
    try {
      final list = await _repo.listarPorFecha(_fecha);
      if (!mounted) return;
      setState(() { _partidos = list; _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  void _cambiarFecha(DateTime nueva) {
    setState(() { _fecha = nueva; _partidos = []; });
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final accent     = RolePalettes.accentForRol('Staff');
    final tenantSlug = context.read<AuthProvider>().token?.tenantSlug;

    return RefreshIndicator(
      color: accent,
      onRefresh: _cargar,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                children: [
                  _NavegadorFecha(
                    fecha:    _fecha,
                    esHoy:    _esHoy,
                    accent:   accent,
                    onCambiar: _cambiarFecha,
                    onHoy:    () => _cambiarFecha(_diaDeHoy()),
                  ),
                  const SizedBox(height: 10),
                  if (!_cargando && _error == null)
                    _ChipsResumen(partidos: _partidos, accent: accent),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (_cargando)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: _ErrorView(mensaje: _error!, onRetry: _cargar),
            )
          else if (_partidos.isEmpty)
            SliverFillRemaining(
              child: _VacioView(esHoy: _esHoy),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 104),
              sliver: SliverList.builder(
                itemCount: _partidos.length,
                itemBuilder: (ctx, i) {
                  final p = _partidos[i];
                  return _PartidoCard(
                    partido:    p,
                    accent:     accent,
                    tenantSlug: tenantSlug,
                    onTap: () async {
                      final cambiado = await showPartidoDetalleSheet(
                        ctx,
                        p,
                        esAdmin:    false,
                        tenantSlug: tenantSlug,
                      );
                      if (cambiado && mounted) _cargar();
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Navegador de fecha ────────────────────────────────────────────────────────

class _NavegadorFecha extends StatelessWidget {
  const _NavegadorFecha({
    required this.fecha,
    required this.esHoy,
    required this.accent,
    required this.onCambiar,
    required this.onHoy,
  });

  final DateTime  fecha;
  final bool      esHoy;
  final Color     accent;
  final void Function(DateTime) onCambiar;
  final VoidCallback             onHoy;

  static const _meses = [
    'enero','febrero','marzo','abril','mayo','junio',
    'julio','agosto','septiembre','octubre','noviembre','diciembre',
  ];
  static const _dias = ['lun','mar','mié','jue','vie','sáb','dom'];

  @override
  Widget build(BuildContext context) {
    final diaSem = _dias[(fecha.weekday - 1) % 7];
    final label  = '$diaSem ${fecha.day} de ${_meses[fecha.month - 1]}';

    return Row(
      children: [
        _NavBtn(icon: Icons.chevron_left,
            onTap: () => onCambiar(fecha.subtract(const Duration(days: 1)))),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: fecha,
                firstDate: DateTime(2020),
                lastDate:  DateTime(2030),
              );
              if (picked != null) {
                onCambiar(DateTime(picked.year, picked.month, picked.day));
              }
            },
            child: Column(
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                if (esHoy)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Hoy',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      )),
                  )
                else
                  GestureDetector(
                    onTap: onHoy,
                    child: Text('Ir a hoy',
                      style: TextStyle(fontSize: 11, color: accent,
                          fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _NavBtn(icon: Icons.chevron_right,
            onTap: () => onCambiar(fecha.add(const Duration(days: 1)))),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData     icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 20, color: AppColors.textPrimary),
    ),
  );
}

// ── Chips resumen ─────────────────────────────────────────────────────────────

class _ChipsResumen extends StatelessWidget {
  const _ChipsResumen({required this.partidos, required this.accent});

  final List<PartidoResumenDto> partidos;
  final Color                   accent;

  @override
  Widget build(BuildContext context) {
    final total      = partidos.length;
    final enCurso    = partidos.where((p) => p.estado == EstadoPartido.enCurso).length;
    final porIniciar = partidos.where((p) => p.estado == EstadoPartido.programado).length;
    final terminados = partidos.where((p) => p.estado == EstadoPartido.terminado).length;

    return Row(children: [
      Expanded(child: _Chip(label: 'TOTAL',       valor: '$total',      color: accent)),
      const SizedBox(width: 6),
      Expanded(child: _Chip(label: 'EN CURSO',    valor: '$enCurso',    color: const Color(0xFFDC2626))),
      const SizedBox(width: 6),
      Expanded(child: _Chip(label: 'POR INICIAR', valor: '$porIniciar', color: const Color(0xFFD97706))),
      const SizedBox(width: 6),
      Expanded(child: _Chip(label: 'TERMINADOS',  valor: '$terminados', color: const Color(0xFF16A34A))),
    ]);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.valor, required this.color});
  final String label;
  final String valor;
  final Color  color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
              color: color, letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(valor,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      ],
    ),
  );
}

// ── Card de partido ───────────────────────────────────────────────────────────

class _PartidoCard extends StatelessWidget {
  const _PartidoCard({
    required this.partido,
    required this.accent,
    required this.onTap,
    this.tenantSlug,
  });

  final PartidoResumenDto partido;
  final Color             accent;
  final VoidCallback      onTap;
  final String?           tenantSlug;

  @override
  Widget build(BuildContext context) {
    final hora = '${partido.fechaHora.hour.toString().padLeft(2, '0')}:'
                 '${partido.fechaHora.minute.toString().padLeft(2, '0')}';
    final enCurso      = partido.estado == EstadoPartido.enCurso;
    final muestraGoles = enCurso || partido.estado == EstadoPartido.terminado;

    return Card(
      margin:          const EdgeInsets.only(bottom: 8),
      elevation:       0,
      clipBehavior:    Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: enCurso
              ? const Color(0xFFDC2626).withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      color: AppColors.surface,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hora + cancha + badge
                  Row(
                    children: [
                      Text(hora,
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                      const SizedBox(width: 8),
                      if (partido.canchaNombre != null)
                        Expanded(
                          child: Text(partido.canchaNombre!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                            overflow: TextOverflow.ellipsis),
                        )
                      else
                        const Spacer(),
                      const SizedBox(width: 8),
                      _EstadoBadge(estado: partido.estado, label: partido.estadoLabel),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Equipos + marcador
                  Row(
                    children: [
                      Expanded(
                        child: Text(partido.equipoLocalNombre,
                          style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis),
                      ),
                      if (muestraGoles) ...[
                        const SizedBox(width: 8),
                        Text('${partido.golesLocal}',
                          style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          )),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('–',
                            style: TextStyle(fontSize: 14, color: AppColors.textHint)),
                        ),
                        Text('${partido.golesVisitante}',
                          style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          )),
                      ] else
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('vs',
                            style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(partido.equipoVisitanteNombre,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Liga · Fase
                  Text(
                    '${partido.ligaNombre} · ${partido.faseNombre}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Indicador EN VIVO
                  if (enCurso) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDC2626), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      const Text('EN VIVO',
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        )),
                    ]),
                  ],
                ],
              ),
            ),
          ),
          // Barra de acciones rápidas (solo partidos EN VIVO)
          if (enCurso) ...[
            const Divider(height: 0, thickness: 0.5, color: AppColors.border),
            _AccionesEnVivoStrip(partido: partido, tenantSlug: tenantSlug),
          ],
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado, required this.label});
  final EstadoPartido estado;
  final String        label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (estado) {
      EstadoPartido.programado => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      EstadoPartido.enCurso    => (const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
      EstadoPartido.terminado  => (const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
      EstadoPartido.suspendido => (const Color(0xFFFEF3C7), const Color(0xFFD97706)),
      EstadoPartido.cancelado  => (const Color(0xFFF1F5F9), const Color(0xFF64748B)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// ── Vacío / Error ─────────────────────────────────────────────────────────────

class _VacioView extends StatelessWidget {
  const _VacioView({required this.esHoy});
  final bool esHoy;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 40, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            'No hay partidos${esHoy ? ' hoy' : ' para este día'}',
            style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Navega a otro día con las flechas',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.mensaje, required this.onRetry});
  final String       mensaje;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 36, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon:  const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

// ── Barra de acciones rápidas para partidos En Vivo ───────────────────────────

class _AccionesEnVivoStrip extends StatelessWidget {
  const _AccionesEnVivoStrip({required this.partido, this.tenantSlug});

  final PartidoResumenDto partido;
  final String?           tenantSlug;

  String _textoShare() {
    final marcador = '${partido.golesLocal} – ${partido.golesVisitante}';
    var texto = '⚽ ${partido.equipoLocalNombre} $marcador ${partido.equipoVisitanteNombre}\n'
                '🔴 En vivo · ${partido.ligaNombre}';
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
      child: Row(
        children: [
          _StripBtn(
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
          _StripBtn(
            icon:  Icons.chat_outlined,
            label: 'WhatsApp',
            onTap: () => launchUrl(
              Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_textoShare())}'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const VerticalDivider(width: 0, thickness: 0.5, color: AppColors.border),
          _StripBtn(
            icon:  Icons.radio_button_checked,
            label: 'Minuto a minuto',
            color: const Color(0xFFDC2626),
            onTap: () => context.push('/staff/envivo/${partido.id}'),
          ),
          const VerticalDivider(width: 0, thickness: 0.5, color: AppColors.border),
          _StripBtn(
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
        ],
      ),
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
