import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/cancha.dart';
import '../../canchas/providers/canchas_estado_provider.dart';

class StaffCanchasScreen extends StatefulWidget {
  const StaffCanchasScreen({super.key});

  @override
  State<StaffCanchasScreen> createState() => _StaffCanchasScreenState();
}

class _StaffCanchasScreenState extends State<StaffCanchasScreen> {
  late final CanchasEstadoProvider _prov;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _prov = CanchasEstadoProvider();
    _prov.cargar();
    _timer = Timer.periodic(const Duration(seconds: 60),
        (_) => _prov.cargar(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _prov.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CanchasEstadoProvider>.value(
      value: _prov,
      child: const _CanchasBody(),
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────────

class _CanchasBody extends StatelessWidget {
  const _CanchasBody();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CanchasEstadoProvider>();

    if (prov.loading && prov.canchas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (prov.error != null && prov.canchas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(prov.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<CanchasEstadoProvider>().cargar(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (prov.canchas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.stadium_outlined, size: 48, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('Sin canchas configuradas',
                style: TextStyle(fontSize: 14, color: AppColors.textHint)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<CanchasEstadoProvider>().cargar(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
        children: [
          _Leyenda(cargando: prov.loading),
          const SizedBox(height: 12),
          if (prov.errorMuta != null)
            _ErrorBanner(mensaje: prov.errorMuta!),
          ...prov.canchas.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CanchaCard(cancha: c),
              )),
        ],
      ),
    );
  }
}

// ── Leyenda ────────────────────────────────────────────────────────────────────

class _Leyenda extends StatelessWidget {
  final bool cargando;
  const _Leyenda({required this.cargando});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Dot(color: _estadoColor('libre')),
        const SizedBox(width: 4),
        const Text('Libre', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        const SizedBox(width: 12),
        _Dot(color: _estadoColor('partido')),
        const SizedBox(width: 4),
        const Text('Partido', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        const SizedBox(width: 12),
        _Dot(color: _estadoColor('reserva')),
        const SizedBox(width: 4),
        const Text('Reserva', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        const SizedBox(width: 12),
        _Dot(color: _estadoColor('mantenimiento')),
        const SizedBox(width: 4),
        const Text('Mantenim.', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        const Spacer(),
        if (cargando)
          const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 9, height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

// ── Card de cancha ─────────────────────────────────────────────────────────────

class _CanchaCard extends StatelessWidget {
  final EstadoCanchaStaffDto cancha;
  const _CanchaCard({required this.cancha});

  @override
  Widget build(BuildContext context) {
    final color  = _estadoColor(cancha.estadoActual);
    final prov   = context.read<CanchasEstadoProvider>();
    final mutando = context.watch<CanchasEstadoProvider>().mutating;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header
            Row(
              children: [
                if (cancha.clave != null) ...[
                  Text(cancha.clave!,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.textHint)),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(cancha.nombre,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ),
                _EstadoBadge(estado: cancha.estadoActual),
              ],
            ),
            const SizedBox(height: 8),
            // ── Evento actual
            if (cancha.eventoActual != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cancha.eventoActual!,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    if (cancha.eventoActualHasta != null)
                      Text('Hasta las ${cancha.eventoActualHasta}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint)),
                    if (cancha.esMantenimiento &&
                        cancha.mantenimientoActivo != null) ...[
                      const SizedBox(height: 2),
                      Text(cancha.mantenimientoActivo!.categoriaLabel,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint)),
                      if (cancha.mantenimientoActivo!.proveedor != null)
                        Text(cancha.mantenimientoActivo!.proveedor!,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textHint)),
                      Text('Por: ${cancha.mantenimientoActivo!.registradoPorNombre}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textHint)),
                    ],
                  ],
                ),
              ),
            ] else ...[
              const Text('Sin actividad ahora',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
            ],
            // ── Próximo evento
            if (cancha.proximoEvento != null && !cancha.esMantenimiento) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    'Próximo: ${_horaLocal(cancha.proximoEventoHora)} · ${cancha.proximoEvento}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
            ] else if (!cancha.esMantenimiento) ...[
              const SizedBox(height: 4),
              const Text('Sin más eventos hoy',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            ],
            const SizedBox(height: 10),
            // ── Acciones
            Row(
              children: [
                if (cancha.esMantenimiento &&
                    cancha.mantenimientoActivo != null) ...[
                  Expanded(
                    child: _AccionBtn(
                      label: 'Resolver mantenimiento',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      disabled: mutando,
                      onTap: () => _mostrarSheetResolver(context, prov, cancha),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: _AccionBtn(
                      label: 'Poner en mantenimiento',
                      icon: Icons.build_outlined,
                      color: const Color(0xFFEA580C),
                      disabled: mutando,
                      onTap: () => _mostrarSheetIniciar(context, prov, cancha),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                _AccionBtn(
                  label: '',
                  icon: Icons.history_rounded,
                  color: AppColors.textSecondary,
                  disabled: false,
                  onTap: () => _mostrarHistorial(context, prov, cancha),
                  compact: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _horaLocal(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = _estadoColor(estado);
    final label = switch (estado) {
      'partido'       => '● Partido',
      'reserva'       => '● Reserva',
      'mantenimiento' => '🔧 Mantenimiento',
      _               => '● Libre',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _AccionBtn extends StatelessWidget {
  final String  label;
  final IconData icon;
  final Color   color;
  final bool    disabled;
  final bool    compact;
  final VoidCallback onTap;

  const _AccionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.disabled,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 10, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(icon, size: 15, color: color),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sheet: Iniciar mantenimiento ───────────────────────────────────────────────

const _categorias = [
  (1, '🔧 Reparación'),
  (2, '🧹 Limpieza'),
  (3, '🌿 Césped / Pasto'),
  (4, '💡 Iluminación'),
  (5, '🏗️ Equipamiento'),
  (6, '🎨 Pintura'),
  (7, '📋 Otro'),
];

void _mostrarSheetIniciar(
    BuildContext context, CanchasEstadoProvider prov, EstadoCanchaStaffDto cancha) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SheetIniciar(prov: prov, cancha: cancha),
  );
}

class _SheetIniciar extends StatefulWidget {
  final CanchasEstadoProvider  prov;
  final EstadoCanchaStaffDto   cancha;
  const _SheetIniciar({required this.prov, required this.cancha});

  @override
  State<_SheetIniciar> createState() => _SheetIniciarState();
}

class _SheetIniciarState extends State<_SheetIniciar> {
  int     _categoria  = 1;
  late final TextEditingController _descCtrl;
  late final TextEditingController _costoCtrl;
  late final TextEditingController _provCtrl;
  bool    _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _descCtrl  = TextEditingController();
    _costoCtrl = TextEditingController();
    _provCtrl  = TextEditingController();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _costoCtrl.dispose();
    _provCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + kb),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('🔧 ${widget.cancha.nombre}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          // Categoría
          const Text('Categoría',
              style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _categoria,
            decoration: _dec(''),
            onChanged: (v) { if (v != null) setState(() => _categoria = v); },
            items: _categorias
                .map((t) => DropdownMenuItem(
                    value: t.$1,
                    child: Text(t.$2, style: const TextStyle(fontSize: 13))))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Descripción
          const Text('Descripción *',
              style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('¿Qué se va a hacer?'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          // Costo + Proveedor en fila
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Costo estimado (\$)',
                        style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _costoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: _dec('0.00'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Proveedor',
                        style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _provCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _dec('Ej. Electricista López'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(fontSize: 12, color: AppColors.error)),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Iniciar mantenimiento',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) {
      setState(() => _error = 'La descripción es obligatoria.');
      return;
    }
    setState(() { _guardando = true; _error = null; });

    final ok = await widget.prov.iniciarMantenimiento(
      widget.cancha.canchaId,
      categoria:     _categoria,
      descripcion:   desc,
      costoEstimado: double.tryParse(_costoCtrl.text.trim()),
      proveedor:     _provCtrl.text.trim().isEmpty ? null : _provCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _guardando = false;
        _error = widget.prov.errorMuta ?? 'Error al iniciar mantenimiento.';
      });
    }
  }
}

// ── Sheet: Resolver mantenimiento ──────────────────────────────────────────────

void _mostrarSheetResolver(
    BuildContext context, CanchasEstadoProvider prov, EstadoCanchaStaffDto cancha) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SheetResolver(prov: prov, cancha: cancha),
  );
}

class _SheetResolver extends StatefulWidget {
  final CanchasEstadoProvider prov;
  final EstadoCanchaStaffDto  cancha;
  const _SheetResolver({required this.prov, required this.cancha});

  @override
  State<_SheetResolver> createState() => _SheetResolverState();
}

class _SheetResolverState extends State<_SheetResolver> {
  late final TextEditingController _costoCtrl;
  late final TextEditingController _obsCtrl;
  bool    _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final costoEst = widget.cancha.mantenimientoActivo?.costoEstimado;
    _costoCtrl = TextEditingController(
        text: costoEst != null ? costoEst.toStringAsFixed(2) : '');
    _obsCtrl   = TextEditingController();
  }

  @override
  void dispose() {
    _costoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final mant = widget.cancha.mantenimientoActivo!;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + kb),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('✅ Resolver — ${widget.cancha.nombre}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('${mant.categoriaLabel} · ${mant.descripcion}',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          const SizedBox(height: 14),
          // Costo real
          const Text('Costo real (\$)',
              style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          const SizedBox(height: 6),
          TextField(
            controller: _costoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: _dec('0.00'),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          // Observación
          const Text('Observación de cierre',
              style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          const SizedBox(height: 6),
          TextField(
            controller: _obsCtrl,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('¿Qué se hizo? ¿Quedó resuelto?'),
            style: const TextStyle(fontSize: 13),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(fontSize: 12, color: AppColors.error)),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Marcar como resuelto',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    setState(() { _guardando = true; _error = null; });

    final ok = await widget.prov.resolverMantenimiento(
      widget.cancha.mantenimientoActivo!.id,
      costoReal:   double.tryParse(_costoCtrl.text.trim()),
      observacion: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _guardando = false;
        _error = widget.prov.errorMuta ?? 'Error al resolver mantenimiento.';
      });
    }
  }
}

// ── Modal: Historial ───────────────────────────────────────────────────────────

void _mostrarHistorial(
    BuildContext context, CanchasEstadoProvider prov, EstadoCanchaStaffDto cancha) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ModalHistorial(prov: prov, cancha: cancha),
  );
}

class _ModalHistorial extends StatefulWidget {
  final CanchasEstadoProvider prov;
  final EstadoCanchaStaffDto  cancha;
  const _ModalHistorial({required this.prov, required this.cancha});

  @override
  State<_ModalHistorial> createState() => _ModalHistorialState();
}

class _ModalHistorialState extends State<_ModalHistorial> {
  List<RegistroMantenimientoDto>? _registros;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    widget.prov.historial(widget.cancha.canchaId).then((r) {
      if (mounted) setState(() { _registros = r; _cargando = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Center(
                    child: Container(width: 36, height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Historial — ${widget.cancha.nombre}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textHint),
                    tooltip: '',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : (_registros == null || _registros!.isEmpty)
                      ? const Center(
                          child: Text('Sin registros de mantenimiento',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textHint)))
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                          separatorBuilder: (_, __) => const Divider(
                              height: 16, color: AppColors.border),
                          itemCount: _registros!.length,
                          itemBuilder: (_, i) =>
                              _HistorialRow(reg: _registros![i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorialRow extends StatelessWidget {
  final RegistroMantenimientoDto reg;
  const _HistorialRow({required this.reg});

  @override
  Widget build(BuildContext context) {
    final fechaStr = _fecha(reg.fechaInicio);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(reg.categoriaLabel,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: reg.resuelto
                          ? AppColors.success.withValues(alpha: 0.1)
                          : const Color(0xFFEA580C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      reg.resuelto ? '✅ Resuelto' : '🔧 Activo',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: reg.resuelto
                              ? AppColors.success
                              : const Color(0xFFEA580C)),
                    ),
                  ),
                ],
              ),
            ),
            Text(fechaStr,
                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ],
        ),
        const SizedBox(height: 3),
        Text(reg.descripcion,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          children: [
            if (reg.proveedor != null)
              _Meta('🏢 ${reg.proveedor!}'),
            if (reg.costoEstimado != null)
              _Meta('Est. \$${_fmt(reg.costoEstimado!)}'),
            if (reg.costoReal != null)
              _Meta('Real \$${_fmt(reg.costoReal!)}'),
            _Meta('👤 ${reg.registradoPorNombre}'),
          ],
        ),
        if (reg.observacionCierre != null) ...[
          const SizedBox(height: 4),
          Text('"${reg.observacionCierre!}"',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint,
                  fontStyle: FontStyle.italic)),
        ],
        if (reg.fechaFin != null) ...[
          const SizedBox(height: 3),
          Text('Cerrado: ${_fecha(reg.fechaFin!)}',
              style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
        ],
      ],
    );
  }

  String _fecha(DateTime dt) {
    final l = dt.toLocal();
    final meses = ['ene','feb','mar','abr','may','jun',
                   'jul','ago','sep','oct','nov','dic'];
    return '${l.day} ${meses[l.month - 1]} ${l.year}';
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _Meta extends StatelessWidget {
  final String text;
  const _Meta(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textHint));
}

// ── Error banner ───────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String mensaje;
  const _ErrorBanner({required this.mensaje});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.error.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 16, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(mensaje,
                  style: const TextStyle(fontSize: 12, color: AppColors.error)),
            ),
          ],
        ),
      );
}

// ── Helpers ────────────────────────────────────────────────────────────────────

Color _estadoColor(String estado) => switch (estado) {
  'partido'       => const Color(0xFFDC2626),
  'reserva'       => const Color(0xFFD97706),
  'mantenimiento' => const Color(0xFFEA580C),
  _               => const Color(0xFF16A34A),
};

InputDecoration _dec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.background,
    );
