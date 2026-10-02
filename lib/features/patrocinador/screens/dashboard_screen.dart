import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../models/patrocinador_dto.dart';
import '../../../shared/widgets/pitazo_scaffold.dart';
import '../providers/patrocinador_provider.dart';
import 'patrocinador_estadisticas_screen.dart';
import 'patrocinador_facturas_screen.dart';

class PatrocinadorDashboardScreen extends StatefulWidget {
  const PatrocinadorDashboardScreen({super.key});

  @override
  State<PatrocinadorDashboardScreen> createState() => _PatrocinadorDashboardScreenState();
}

class _PatrocinadorDashboardScreenState extends State<PatrocinadorDashboardScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return PitazoScaffold(
      primaryNav: const [
        PitazoNavItem(icon: Icons.dashboard_outlined,    label: 'Inicio'),
        PitazoNavItem(icon: Icons.bar_chart_outlined,     label: 'Estadísticas'),
        PitazoNavItem(icon: Icons.receipt_long_outlined,  label: 'Facturas'),
      ],
      onTabChanged: (i) => setState(() => _activeTab = i),
      onAvatarTap: () => context.push('/patrocinador/perfil'),
      child: IndexedStack(
        index: _activeTab,
        children: [
          _PatrocinadorInicioBody(onVerFacturas: () => setState(() => _activeTab = 2)),
          const PatrocinadorEstadisticasScreen(),
          const PatrocinadorFacturasScreen(),
        ],
      ),
    );
  }
}

// ── Inicio ────────────────────────────────────────────────────────────────────

class _PatrocinadorInicioBody extends StatefulWidget {
  final VoidCallback onVerFacturas;
  const _PatrocinadorInicioBody({required this.onVerFacturas});

  @override
  State<_PatrocinadorInicioBody> createState() => _PatrocinadorInicioBodyState();
}

class _PatrocinadorInicioBodyState extends State<_PatrocinadorInicioBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<PatrocinadorProvider>();
      if (p.perfil == null && !p.loading) p.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = RolePalettes.accentForRol('Patrocinador');
    final p = context.watch<PatrocinadorProvider>();

    return RefreshIndicator(
      color: accent,
      onRefresh: () => p.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (p.loading && p.perfil == null)
              _buildSkeleton()
            else if (p.perfil == null && p.error != null)
              _ErrorCard(mensaje: p.error!, onRetry: () => p.load())
            else if (p.perfil != null) ...[
              _AcuerdoCard(perfil: p.perfil!, accent: accent),
              const SizedBox(height: 10),
              if (p.facturas.any((f) => !f.pagado)) ...[
                _FacturasPendientesCard(
                  facturas: p.facturas.where((f) => !f.pagado).take(3).toList(),
                  accent: accent,
                  onVerTodas: widget.onVerFacturas,
                ),
                const SizedBox(height: 10),
              ],
              if (p.metricas != null) _MetricasGrid(metricas: p.metricas!, accent: accent),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Shimmer(height: 120, radius: 14),
          const SizedBox(height: 10),
          _Shimmer(height: 160, radius: 14),
        ],
      );
}

class _AcuerdoCard extends StatelessWidget {
  final PatrocinadorPortalDto perfil;
  final Color accent;
  const _AcuerdoCard({required this.perfil, required this.accent});

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
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: perfil.logoUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(perfil.logoUrl!, fit: BoxFit.cover))
                : Icon(Icons.storefront_outlined, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(perfil.nombre,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(perfil.tenantNombre, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: perfil.activo ? const Color(0xFF166534).withValues(alpha: 0.1) : AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(perfil.estadoLabel,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: perfil.activo ? const Color(0xFF166534) : AppColors.textHint)),
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 0, thickness: 0.5, color: AppColors.border),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _InfoChip(label: 'Nivel', valor: perfil.nivelLabel)),
          if (perfil.fechaInicio != null && perfil.fechaFin != null)
            Expanded(
              child: _InfoChip(
                label: 'Vigencia',
                valor: '${_fechaCorta(perfil.fechaInicio!)} – ${_fechaCorta(perfil.fechaFin!)}',
              ),
            ),
        ]),
      ]),
    );
  }

  String _fechaCorta(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _InfoChip extends StatelessWidget {
  final String label, valor;
  const _InfoChip({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          const SizedBox(height: 2),
          Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      );
}

class _FacturasPendientesCard extends StatelessWidget {
  final List<FacturaPatrocinadorDto> facturas;
  final Color accent;
  final VoidCallback onVerTodas;
  const _FacturasPendientesCard({required this.facturas, required this.accent, required this.onVerTodas});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 6),
          const Expanded(
            child: Text('Facturas pendientes',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          TextButton(onPressed: onVerTodas, child: const Text('Ver todas', style: TextStyle(fontSize: 12))),
        ]),
        const SizedBox(height: 6),
        ...facturas.map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(child: Text(f.concepto, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                Text('\$${f.monto.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
              ]),
            )),
      ]),
    );
  }
}

class _MetricasGrid extends StatelessWidget {
  final MetricasPatrocinadorDto metricas;
  final Color accent;
  const _MetricasGrid({required this.metricas, required this.accent});

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
        _StatTile(valor: '${metricas.hoy}', label: 'VISTAS HOY', color: accent),
        _StatTile(valor: '${metricas.ultimos7Dias}', label: 'ÚLTIMOS 7 DÍAS', color: accent),
        _StatTile(valor: '${metricas.ultimos30Dias}', label: 'ÚLTIMOS 30 DÍAS', color: accent),
        _StatTile(valor: '${metricas.total}', label: 'TOTAL', color: accent),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String valor, label;
  final Color color;
  const _StatTile({required this.valor, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color, height: 1)),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                    color: AppColors.textHint, letterSpacing: 0.4)),
          ],
        ),
      );
}

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
