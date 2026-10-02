import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../staff/providers/staff_reservas_provider.dart';
import '../../staff/data/staff_reservas_repository.dart';
import '../../../models/reserva_dto.dart';
import 'reserva_sheet.dart';

class StaffReservasScreen extends StatefulWidget {
  const StaffReservasScreen({super.key});

  @override
  State<StaffReservasScreen> createState() => _StaffReservasScreenState();

  static void abrirNueva(BuildContext context) {
    final prov = context.read<StaffReservasProvider>();
    showReservaSheet(
      context,
      canchas:    prov.canchas,
      equipos:    prov.equipos,
      repo:       context.read<StaffReservasRepository>(),
      onGuardado: prov.cargar,
    );
  }
}

class _StaffReservasScreenState extends State<StaffReservasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffReservasProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StaffReservasProvider>();

    return Column(children: [
      _DateNav(prov: prov),
      if (prov.canchas.isNotEmpty) _Filtros(prov: prov),
      Expanded(child: _Cuerpo(prov: prov)),
    ]);
  }
}

// ─── Navegador de fecha ───────────────────────────────────────────────────────

class _DateNav extends StatelessWidget {
  final StaffReservasProvider prov;
  const _DateNav({required this.prov});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: prov.loading ? null : prov.irAnterior),
        Expanded(child: GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: prov.fecha,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (d != null) prov.irFecha(d);
          },
          child: Column(children: [
            Text(prov.fechaLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
            Text(
              '${prov.fecha.day.toString().padLeft(2,'0')}/${prov.fecha.month.toString().padLeft(2,'0')}/${prov.fecha.year}',
              style: TextStyle(fontSize: 11, color: cs.outline),
              textAlign: TextAlign.center),
          ]),
        )),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: prov.loading ? null : prov.irSiguiente),
        if (!prov.esHoy)
          TextButton(onPressed: prov.irHoy, child: const Text('Hoy')),
        if (prov.esHoy)
          const SizedBox(width: 48),
      ]),
    );
  }
}

// ─── Chips de filtro ──────────────────────────────────────────────────────────

class _Filtros extends StatelessWidget {
  final StaffReservasProvider prov;
  const _Filtros({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(children: [
        const Divider(height: 1),
        // Canchas
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              _FiltroChip(label: 'Todas', selected: prov.canchaFiltro == null, onTap: () => prov.setFiltroCancha(null)),
              ...prov.canchas.map((c) => _FiltroChip(
                label: c.clave ?? c.nombre,
                selected: prov.canchaFiltro == c.id,
                onTap: () => prov.setFiltroCancha(c.id),
              )),
            ],
          ),
        ),
        // Estados
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              _FiltroChip(label: 'Todos', selected: prov.estadoFiltro == null, onTap: () => prov.setFiltroEstado(null)),
              ...EstadoReserva.values.map((e) => _FiltroChip(
                label: e.label,
                selected: prov.estadoFiltro == e,
                color: e.color,
                onTap: () => prov.setFiltroEstado(e),
              )),
            ],
          ),
        ),
      ]),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String   label;
  final bool     selected;
  final VoidCallback onTap;
  final Color?   color;

  const _FiltroChip({required this.label, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(color: selected ? accent : Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              color: selected ? accent : Theme.of(context).colorScheme.onSurface)),
      ),
    );
  }
}

// ─── Cuerpo principal ─────────────────────────────────────────────────────────

class _Cuerpo extends StatelessWidget {
  final StaffReservasProvider prov;
  const _Cuerpo({required this.prov});

  @override
  Widget build(BuildContext context) {
    if (prov.loading) return const Center(child: CircularProgressIndicator());

    if (prov.error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(prov.error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          TextButton(onPressed: prov.cargar, child: const Text('Reintentar')),
        ]),
      );
    }

    if (prov.listado.isEmpty) return _Vacio(prov: prov);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount:   prov.listado.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _ReservaCard(
        reserva:    prov.listado[i],
        onTap: () => showReservaSheet(
          ctx,
          reserva:    prov.listado[i],
          canchas:    prov.canchas,
          equipos:    prov.equipos,
          repo:       ctx.read<StaffReservasRepository>(),
          onGuardado: prov.cargar,
        ),
      ),
    );
  }
}

// ─── Card de reserva ──────────────────────────────────────────────────────────

class _ReservaCard extends StatelessWidget {
  final ReservaDto  reserva;
  final VoidCallback onTap;

  const _ReservaCard({required this.reserva, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r  = reserva;
    final cs = Theme.of(context).colorScheme;

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
            // Hora
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(r.horaInicioDisplay, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(r.horaFinDisplay,   style: TextStyle(fontSize: 11, color: cs.outline)),
            ]),
            const SizedBox(width: 14),
            const VerticalDivider(width: 1, indent: 4, endIndent: 4),
            const SizedBox(width: 14),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.claveCancha != null ? '${r.claveCancha} — ${r.nombreCancha}' : r.nombreCancha,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(r.nombreCliente, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              if (r.telefonoCliente?.isNotEmpty == true)
                Text(r.telefonoCliente!, style: TextStyle(fontSize: 11, color: cs.outline)),
              if (r.nombreEquipo?.isNotEmpty == true)
                Text('⚽ ${r.nombreEquipo}', style: TextStyle(fontSize: 11, color: cs.outline)),
            ])),
            const SizedBox(width: 10),
            // Derecha
            Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              _EstadoBadge(estado: r.estado),
              const SizedBox(height: 4),
              Text('\$${r.total.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              if (r.totalPagado)
                Text('✅ Pagado', style: TextStyle(fontSize: 10, color: cs.primary))
              else if (r.depositoPagado && r.deposito != null)
                Text('⚡ Dep. \$${r.deposito!.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: cs.outline)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _Vacio extends StatelessWidget {
  final StaffReservasProvider prov;
  const _Vacio({required this.prov});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🗓️', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      Text('Sin reservas para ${prov.fechaLabel}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Toca + para agregar la primera reserva.',
        style: TextStyle(color: Theme.of(context).colorScheme.outline)),
    ]),
  );
}

// ─── Badge de estado ─────────────────────────────────────────────────────────

class _EstadoBadge extends StatelessWidget {
  final EstadoReserva estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: estado.bg, borderRadius: BorderRadius.circular(6)),
    child: Text(estado.label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: estado.color)),
  );
}
