import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../staff/providers/staff_comunicados_provider.dart';
import '../../staff/data/staff_comunicados_repository.dart';
import '../../../models/comunicado_dto.dart';
import 'comunicado_sheet.dart';

class StaffComunicadosScreen extends StatefulWidget {
  const StaffComunicadosScreen({super.key});

  @override
  State<StaffComunicadosScreen> createState() => _StaffComunicadosScreenState();

  static void abrirNuevo(BuildContext context) {
    final prov = context.read<StaffComunicadosProvider>();
    showComunicadoNuevoSheet(
      context,
      repo:                      context.read<StaffComunicadosRepository>(),
      comunicacionEquiposActiva: prov.comunicacionEquiposActiva,
      temporadas:                prov.temporadas,
      equipos:                   prov.equipos,
      onEnviado:                 prov.cargar,
    );
  }
}

class _StaffComunicadosScreenState extends State<StaffComunicadosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffComunicadosProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StaffComunicadosProvider>();

    if (prov.loading && prov.historial.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (prov.error != null && prov.historial.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(prov.error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        TextButton(onPressed: prov.cargar, child: const Text('Reintentar')),
      ]));
    }

    if (prov.historial.isEmpty) {
      return const _Vacio();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount:   prov.historial.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final c = prov.historial[i];
        return _ComunicadoCard(
          comunicado: c,
          onTap: () => showComunicadoDetalleSheet(ctx, comunicado: c),
        );
      },
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _ComunicadoCard extends StatelessWidget {
  final ComunicadoDto  comunicado;
  final VoidCallback   onTap;
  const _ComunicadoCard({required this.comunicado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c  = comunicado;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.titulo,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(c.audienciaResumen,
                  style: TextStyle(fontSize: 11, color: cs.outline),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(c.fechaFormateada,
                  style: TextStyle(fontSize: 11, color: cs.outline)),
            ])),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${c.totalDestinatarios}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onPrimaryContainer)),
              ),
              const SizedBox(height: 2),
              Text('dest.', style: TextStyle(fontSize: 9, color: cs.outline)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('📭', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      const Text('Sin avisos enviados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Toca + para redactar el primero.',
          style: TextStyle(color: Theme.of(context).colorScheme.outline)),
    ]),
  );
}
