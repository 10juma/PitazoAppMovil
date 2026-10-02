import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../models/patrocinador_dto.dart';
import '../providers/patrocinador_provider.dart';

class PatrocinadorEstadisticasScreen extends StatefulWidget {
  const PatrocinadorEstadisticasScreen({super.key});

  @override
  State<PatrocinadorEstadisticasScreen> createState() => _PatrocinadorEstadisticasScreenState();
}

class _PatrocinadorEstadisticasScreenState extends State<PatrocinadorEstadisticasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<PatrocinadorProvider>();
      if (p.metricas == null && !p.loading) p.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = RolePalettes.accentForRol('Patrocinador');
    final p = context.watch<PatrocinadorProvider>();
    final metricas = p.metricas;

    return RefreshIndicator(
      color: accent,
      onRefresh: () => p.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
        child: p.loading && metricas == null
            ? const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            : metricas == null
                ? Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(children: [
                      const Icon(Icons.cloud_off_outlined, size: 28, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      const Text('No se pudieron cargar tus estadísticas',
                          style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: () => p.load(), child: const Text('Reintentar')),
                    ]),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GridView.count(
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
                      ),
                      const SizedBox(height: 14),
                      if (metricas.serie.isNotEmpty) _SerieChart(serie: metricas.serie, accent: accent),
                    ],
                  ),
      ),
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

class _SerieChart extends StatelessWidget {
  final List<VistaDiariaDto> serie;
  final Color accent;
  const _SerieChart({required this.serie, required this.accent});

  @override
  Widget build(BuildContext context) {
    final maxVal = serie.map((v) => v.vistas).fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Vistas — últimos 30 días',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: serie.map((v) {
              final h = maxVal > 0 ? (v.vistas / maxVal) * 110 : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Tooltip(
                    message: '${v.vistas} vistas — ${v.fecha.day}/${v.fecha.month}',
                    child: Container(
                      height: h < 2 ? 2 : h,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.7),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${serie.first.fecha.day}/${serie.first.fecha.month}',
                style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
            Text('${serie.last.fecha.day}/${serie.last.fecha.month}',
                style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ],
        ),
      ]),
    );
  }
}
