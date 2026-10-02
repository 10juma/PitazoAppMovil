import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../models/patrocinador_dto.dart';
import '../providers/patrocinador_provider.dart';

class PatrocinadorFacturasScreen extends StatefulWidget {
  const PatrocinadorFacturasScreen({super.key});

  @override
  State<PatrocinadorFacturasScreen> createState() => _PatrocinadorFacturasScreenState();
}

class _PatrocinadorFacturasScreenState extends State<PatrocinadorFacturasScreen> {
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
    final pendientes = p.facturas.where((f) => !f.pagado).toList();
    final totalPendiente = pendientes.fold<double>(0, (sum, f) => sum + f.monto);

    return RefreshIndicator(
      color: accent,
      onRefresh: () => p.refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
        child: p.loading && p.facturas.isEmpty
            ? const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            : p.facturas.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.textHint),
                          SizedBox(height: 10),
                          Text('No tienes facturas todavía',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                        ],
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (pendientes.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${pendientes.length} factura(s) pendiente(s) por \$${totalPendiente.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 12),
                      ],
                      ...p.facturas.map((f) => _FacturaCard(factura: f)),
                    ],
                  ),
      ),
    );
  }
}

class _FacturaCard extends StatelessWidget {
  final FacturaPatrocinadorDto factura;
  const _FacturaCard({required this.factura});

  Color get _colorEstado => factura.pagado
      ? const Color(0xFF166534)
      : factura.venceEn.isBefore(DateTime.now())
          ? AppColors.error
          : const Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(factura.concepto,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _colorEstado.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(factura.estadoLabel,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _colorEstado)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          factura.pagado
              ? 'Pagada el ${_fecha(factura.pagadoEn!)}'
              : 'Vence el ${_fecha(factura.venceEn)}',
          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
        if (factura.notas != null && factura.notas!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(factura.notas!, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
        ],
        const SizedBox(height: 8),
        Text('\$${factura.monto.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ]),
    );
  }

  String _fecha(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
