import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../models/equipo_dto.dart';
import '../../../shared/enums/estado_equipo.dart';
import '../../staff/providers/staff_equipos_provider.dart';
import 'equipo_detalle_sheet.dart';

class StaffEquiposScreen extends StatefulWidget {
  const StaffEquiposScreen({super.key});

  @override
  State<StaffEquiposScreen> createState() => _StaffEquiposScreenState();
}

class _StaffEquiposScreenState extends State<StaffEquiposScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StaffEquiposProvider>().cargar();
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
    final provider = context.watch<StaffEquiposProvider>();

    return Column(
      children: [
        _FiltrosHeader(accent: accent, provider: provider, searchCtrl: _searchCtrl),
        Expanded(child: _Lista(provider: provider, accent: accent)),
      ],
    );
  }
}

// ── Filtros ────────────────────────────────────────────────────────────────────

class _FiltrosHeader extends StatelessWidget {
  final Color                 accent;
  final StaffEquiposProvider  provider;
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
                      hintText: 'Buscar por nombre o manager…',
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
                    onTap: () { searchCtrl.clear(); provider.setBusqueda(''); },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.close, size: 14, color: AppColors.textHint),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _EstadoChips(accent: accent, provider: provider),
        ],
      ),
    );
  }
}

class _EstadoChips extends StatelessWidget {
  final Color                accent;
  final StaffEquiposProvider provider;
  const _EstadoChips({required this.accent, required this.provider});

  @override
  Widget build(BuildContext context) {
    const opciones = [
      (null,                    'Todos'),
      (EstadoEquipo.activo,     'Activos'),
      (EstadoEquipo.inactivo,   'Inactivos'),
      (EstadoEquipo.disuelto,   'Disueltos'),
    ];

    return SizedBox(
      height: 28,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (estado, label) in opciones) ...[
            _Chip(
              label:  label,
              activo: provider.estadoFiltro == estado,
              accent: accent,
              onTap:  () => provider.setEstado(estado),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool activo;
  final Color accent;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.activo, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
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
      child: Text(label,
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: activo ? Colors.white : AppColors.textHint,
        )),
    ),
  );
}

// ── Lista ──────────────────────────────────────────────────────────────────────

class _Lista extends StatelessWidget {
  final StaffEquiposProvider provider;
  final Color                accent;
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
            Icon(Icons.group_off_outlined, size: 28, color: AppColors.textHint),
            SizedBox(height: 8),
            Text('Sin equipos con estos filtros',
              style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: accent,
      onRefresh: provider.recargar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 104),
        itemCount: lista.length,
        itemBuilder: (_, i) => _EquipoRow(
          equipo:        lista[i],
          accent:        accent,
          tieneWhatsApp: provider.tieneWhatsApp,
          onChanged:     provider.recargar,
        ),
      ),
    );
  }
}

// ── Tarjeta de equipo ──────────────────────────────────────────────────────────

class _EquipoRow extends StatelessWidget {
  final EquipoDto    equipo;
  final Color        accent;
  final bool         tieneWhatsApp;
  final VoidCallback onChanged;
  const _EquipoRow({
    required this.equipo,
    required this.accent,
    required this.tieneWhatsApp,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorEq = _hexColor(equipo.colorPrincipal) ?? accent;

    return GestureDetector(
      onTap: () async {
        await showEquipoDetalleSheet(
          context, equipo,
          tieneWhatsApp: tieneWhatsApp,
        );
        if (context.mounted) onChanged();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: colorEq.withValues(alpha: 0.15),
              radius: 22,
              child: Env.toAbsolutePhotoUrl(equipo.logoUrl) != null
                  ? ClipOval(child: Image.network(Env.toAbsolutePhotoUrl(equipo.logoUrl)!, width: 44, height: 44, fit: BoxFit.cover))
                  : Text(equipo.nombre.isNotEmpty ? equipo.nombre[0].toUpperCase() : '?',
                      style: TextStyle(color: colorEq, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(equipo.nombre,
                          style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      _EstadoBadge(estado: equipo.estado, label: equipo.estadoLabel),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.group_outlined, size: 11, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Text('${equipo.totalActivos} activos / ${equipo.totalJugadores} total',
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                      if (equipo.manager != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.person_outline, size: 11, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(equipo.manager!.nombreCompleto,
                            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                            overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Colores
            if (equipo.colorPrincipal != null) ...[
              const SizedBox(width: 8),
              Row(
                children: [
                  _ColorDot(hex: equipo.colorPrincipal),
                  if (equipo.colorSecundario != null) ...[
                    const SizedBox(width: 3),
                    _ColorDot(hex: equipo.colorSecundario),
                  ],
                ],
              ),
            ],
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final String? hex;
  const _ColorDot({required this.hex});

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(hex);
    if (color == null) return const SizedBox.shrink();
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final EstadoEquipo estado;
  final String       label;
  const _EstadoBadge({required this.estado, required this.label});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (estado) {
      EstadoEquipo.activo   => (const Color(0xFF166534).withValues(alpha: 0.08), const Color(0xFF166534)),
      EstadoEquipo.inactivo => (const Color(0xFF6B7280).withValues(alpha: 0.1),  const Color(0xFF6B7280)),
      EstadoEquipo.disuelto => (const Color(0xFFDC2626).withValues(alpha: 0.08), const Color(0xFFDC2626)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

Color? _hexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  try {
    final h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    if (h.length == 8) return Color(int.parse(h, radix: 16));
  } catch (_) {}
  return null;
}
