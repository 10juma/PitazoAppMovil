import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../models/partido_resumen_dto.dart';
import '../../../shared/enums/estado_partido.dart';
import '../providers/admin_partidos_provider.dart';
import 'partido_detalle_sheet.dart';

class AdminPartidosScreen extends StatefulWidget {
  const AdminPartidosScreen({super.key});

  @override
  State<AdminPartidosScreen> createState() => _AdminPartidosScreenState();
}

class _AdminPartidosScreenState extends State<AdminPartidosScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminPartidosProvider>().cargar();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent   = RolePalettes.accentForRol(context.watch<AuthProvider>().token?.rol);
    final provider = context.watch<AdminPartidosProvider>();

    return Column(
      children: [
        _FiltrosHeader(accent: accent, provider: provider, searchCtrl: _searchCtrl),
        Expanded(child: _Lista(provider: provider, accent: accent)),
      ],
    );
  }
}

// ── Cabecera con filtros ───────────────────────────────────────────────────────

class _FiltrosHeader extends StatelessWidget {
  final Color accent;
  final AdminPartidosProvider provider;
  final TextEditingController searchCtrl;
  const _FiltrosHeader({required this.accent, required this.provider, required this.searchCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(Icons.search, size: 16, color: AppColors.textHint),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Buscar equipo, liga, cancha…',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: provider.setBusqueda,
                  ),
                ),
                if (searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      searchCtrl.clear();
                      provider.setBusqueda('');
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.close, size: 14, color: AppColors.textHint),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Dropdowns de Liga y Temporada
          Row(
            children: [
              Expanded(child: _DropdownFiltro(
                label: 'Liga',
                value: provider.ligaFiltro,
                opciones: provider.ligasOpciones,
                accent: accent,
                onChanged: provider.setLiga,
              )),
              const SizedBox(width: 8),
              Expanded(child: _DropdownFiltro(
                label: 'Temporada',
                value: provider.temporadaFiltro,
                opciones: provider.temporadasOpciones,
                accent: accent,
                onChanged: provider.setTemporada,
              )),
            ],
          ),
          const SizedBox(height: 8),

          // Estado chips
          _EstadoChips(accent: accent, provider: provider),
        ],
      ),
    );
  }
}

class _DropdownFiltro extends StatelessWidget {
  final String label;
  final String? value;
  final List<OpcionFiltro> opciones;
  final Color accent;
  final void Function(String?) onChanged;
  const _DropdownFiltro({
    required this.label, required this.value, required this.opciones,
    required this.accent, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value != null;
    return GestureDetector(
      onTap: () => _mostrarOpciones(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? accent.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? accent.withValues(alpha: 0.4) : AppColors.border,
            width: isActive ? 1.2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isActive
                    ? (opciones.where((o) => o.id == value).firstOrNull?.nombre ?? label)
                    : label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? accent : AppColors.textHint,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isActive ? accent : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarOpciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            _OpcionItem(
              texto: 'Todos',
              activo: value == null,
              accent: accent,
              onTap: () { Navigator.pop(context); onChanged(null); },
            ),
            if (opciones.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Sin opciones', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              )
            else
              ...opciones.map((o) => _OpcionItem(
                    texto: o.nombre,
                    activo: o.id == value,
                    accent: accent,
                    onTap: () { Navigator.pop(context); onChanged(o.id); },
                  )),
          ],
        ),
      ),
    );
  }
}

class _OpcionItem extends StatelessWidget {
  final String texto;
  final bool activo;
  final Color accent;
  final VoidCallback onTap;
  const _OpcionItem({required this.texto, required this.activo, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(texto,
          style: TextStyle(
            fontSize: 13,
            fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
            color: activo ? accent : AppColors.textPrimary,
          )),
      trailing: activo ? Icon(Icons.check, size: 16, color: accent) : null,
      onTap: onTap,
    );
  }
}

class _EstadoChips extends StatelessWidget {
  final Color accent;
  final AdminPartidosProvider provider;
  const _EstadoChips({required this.accent, required this.provider});

  @override
  Widget build(BuildContext context) {
    const opciones = [
      (null,                     'Todos'),
      (EstadoPartido.programado, 'Programados'),
      (EstadoPartido.enCurso,    'En vivo'),
      (EstadoPartido.terminado,  'Terminados'),
    ];

    return SizedBox(
      height: 28,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (estado, label) in opciones) ...[
            _EstadoChip(
              label: label,
              activo: provider.estadoFiltro == estado,
              accent: accent,
              onTap: () => provider.setEstado(estado),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String label;
  final bool activo;
  final Color accent;
  final VoidCallback onTap;
  const _EstadoChip({required this.label, required this.activo, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: activo ? accent : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: activo ? accent : AppColors.border,
            width: activo ? 1.2 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: activo ? Colors.white : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

// ── Lista de partidos ──────────────────────────────────────────────────────────

class _Lista extends StatelessWidget {
  final AdminPartidosProvider provider;
  final Color accent;
  const _Lista({required this.provider, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 28, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text(provider.error!,
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: provider.recargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    final lista = provider.filtrados;
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.sports_soccer, size: 28, color: AppColors.textHint),
            SizedBox(height: 8),
            Text('Sin partidos con estos filtros',
                style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          ],
        ),
      );
    }

    final tenantSlug = context.read<AuthProvider>().token?.tenantSlug;

    return RefreshIndicator(
      color: accent,
      onRefresh: provider.recargar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 104),
        itemCount: lista.length,
        itemBuilder: (_, i) => _PartidoRow(partido: lista[i], accent: accent, tenantSlug: tenantSlug),
      ),
    );
  }
}

class _PartidoRow extends StatelessWidget {
  final PartidoResumenDto partido;
  final Color             accent;
  final String?           tenantSlug;
  const _PartidoRow({required this.partido, required this.accent, this.tenantSlug});

  @override
  Widget build(BuildContext context) {
    final esEnVivo   = partido.estado == EstadoPartido.enCurso;
    final terminado  = partido.estado == EstadoPartido.terminado;

    return Card(
      margin:       const EdgeInsets.only(bottom: 8),
      elevation:    0,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: esEnVivo ? const Color(0xFFDC2626).withValues(alpha: 0.25) : AppColors.border,
          width: esEnVivo ? 1.2 : 0.5,
        ),
      ),
      color: AppColors.surface,
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              final cambio = await showPartidoDetalleSheet(context, partido);
              if (cambio && context.mounted) {
                context.read<AdminPartidosProvider>().recargar();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Liga · Temporada
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${partido.ligaNombre} · ${partido.temporadaNombre}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _EstadoBadge(estado: partido.estado, label: partido.estadoLabel),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Equipos + marcador
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(partido.equipoLocalNombre,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text('vs ${partido.equipoVisitanteNombre}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      if (terminado || esEnVivo)
                        Text(
                          '${partido.golesLocal} — ${partido.golesVisitante}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: esEnVivo ? const Color(0xFFDC2626) : AppColors.textPrimary,
                            letterSpacing: 1,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Fecha · Cancha
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 10, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(partido.fechaFormateada,
                          style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                      if (partido.canchaNombre != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.stadium_outlined, size: 10, color: AppColors.textHint),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(partido.canchaNombre!,
                              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (esEnVivo) ...[
            const Divider(height: 0, thickness: 0.5, color: AppColors.border),
            _AdminEnVivoStrip(partido: partido, tenantSlug: tenantSlug),
          ],
        ],
      ),
    );
  }
}

// ── Barra de acciones rápidas (partidos En Vivo — admin) ─────────────────────

class _AdminEnVivoStrip extends StatelessWidget {
  const _AdminEnVivoStrip({required this.partido, this.tenantSlug});

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
      child: Row(children: [
        _AdminStripBtn(
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
        _AdminStripBtn(
          icon:  Icons.chat_outlined,
          label: 'WhatsApp',
          onTap: () => launchUrl(
            Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_textoShare())}'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const VerticalDivider(width: 0, thickness: 0.5, color: AppColors.border),
        _AdminStripBtn(
          icon:  Icons.radio_button_checked,
          label: 'Minuto a minuto',
          color: const Color(0xFFDC2626),
          onTap: () => context.push('/staff/envivo/${partido.id}'),
        ),
        const VerticalDivider(width: 0, thickness: 0.5, color: AppColors.border),
        _AdminStripBtn(
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

class _AdminStripBtn extends StatelessWidget {
  const _AdminStripBtn({
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

// ─────────────────────────────────────────────────────────────────────────────

class _EstadoBadge extends StatelessWidget {
  final EstadoPartido estado;
  final String label;
  const _EstadoBadge({required this.estado, required this.label});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (estado) {
      EstadoPartido.enCurso    => (const Color(0xFFDC2626).withValues(alpha: 0.1), const Color(0xFFDC2626)),
      EstadoPartido.terminado  => (const Color(0xFF166534).withValues(alpha: 0.08), const Color(0xFF166534)),
      EstadoPartido.cancelado  => (const Color(0xFF6B7280).withValues(alpha: 0.1), const Color(0xFF6B7280)),
      EstadoPartido.suspendido => (const Color(0xFFD97706).withValues(alpha: 0.1), const Color(0xFFD97706)),
      _                        => (const Color(0xFF2563EB).withValues(alpha: 0.08), const Color(0xFF2563EB)),
    };

    final texto = estado == EstadoPartido.enCurso ? '🔴 En vivo' : label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(texto, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
