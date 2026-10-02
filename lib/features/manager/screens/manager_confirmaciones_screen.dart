import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../data/manager_repository.dart';

class ManagerConfirmacionesScreen extends StatefulWidget {
  final String equipoId;
  final String partidoId;
  const ManagerConfirmacionesScreen({
    super.key, required this.equipoId, required this.partidoId,
  });

  @override
  State<ManagerConfirmacionesScreen> createState() => _ManagerConfirmacionesScreenState();
}

class _ManagerConfirmacionesScreenState extends State<ManagerConfirmacionesScreen> {
  final _repo = ManagerRepository();

  List<ConfirmacionDto> _lista    = [];
  bool    _loading  = false;
  String? _error;
  final Set<String> _actualizando = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _repo.obtenerConfirmaciones(widget.equipoId, widget.partidoId);
      if (mounted) setState(() { _lista = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _abrirOpciones(ConfirmacionDto item, Color accent) async {
    final accion = await showModalBottomSheet<_AccionConfirmacion>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _OpcionesConfirmacionSheet(item: item, accent: accent),
    );
    if (accion == null || !mounted) return;

    setState(() => _actualizando.add(item.id));
    final ok = await _repo.actualizarConfirmacion(
      widget.equipoId, widget.partidoId,
      jugadorEquipoId: item.jugadorEquipoId,
      confirma: accion.confirma,
      motivo:   accion.motivo,
    );
    if (mounted) {
      setState(() => _actualizando.remove(item.id));
      if (ok) {
        await _cargar();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar la confirmación')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent    = RolePalettes.accentForRol('Manager');
    final confirmados = _lista.where((c) => c.confirma == true).length;
    final declinados  = _lista.where((c) => c.confirma == false).length;
    final pendientes  = _lista.where((c) => c.confirma == null).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Confirmaciones', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(mensaje: _error!, onRetry: _cargar)
              : Column(children: [
                  // Resumen
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ResumenChip(
                          icon: Icons.check_circle_outline,
                          label: '$confirmados',
                          sub: 'Confirmados',
                          color: AppColors.success,
                        ),
                        _ResumenChip(
                          icon: Icons.cancel_outlined,
                          label: '$declinados',
                          sub: 'Declinados',
                          color: AppColors.error,
                        ),
                        _ResumenChip(
                          icon: Icons.help_outline,
                          label: '$pendientes',
                          sub: 'Sin respuesta',
                          color: AppColors.textHint,
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: Row(children: [
                      Icon(Icons.touch_app_outlined, size: 12, color: AppColors.textHint),
                      SizedBox(width: 6),
                      Expanded(child: Text(
                        'Toca un jugador para registrar su confirmación manualmente',
                        style: TextStyle(fontSize: 10, color: AppColors.textHint),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  const Divider(height: 0, thickness: 0.5, color: AppColors.border),
                  Expanded(
                    child: RefreshIndicator(
                      color: accent,
                      onRefresh: _cargar,
                      child: _lista.isEmpty
                          ? const Center(
                              child: Text('Sin jugadores registrados',
                                  style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
                              itemCount: _lista.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (_, i) => _ConfirmacionRow(
                                item: _lista[i],
                                accent: accent,
                                actualizando: _actualizando.contains(_lista[i].id),
                                onTap: () => _abrirOpciones(_lista[i], accent),
                              ),
                            ),
                    ),
                  ),
                ]),
    );
  }
}

class _ResumenChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   sub;
  final Color    color;
  const _ResumenChip({required this.icon, required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, size: 18, color: color),
    const SizedBox(height: 4),
    Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
    const SizedBox(height: 2),
    Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
  ]);
}

class _ConfirmacionRow extends StatelessWidget {
  final ConfirmacionDto item;
  final Color accent;
  final bool  actualizando;
  final VoidCallback onTap;
  const _ConfirmacionRow({
    required this.item, required this.accent,
    required this.actualizando, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (iconData, iconColor, bgColor) = switch (item.confirma) {
      true  => (Icons.check_circle,  AppColors.success, const Color(0xFFDCFCE7)),
      false => (Icons.cancel,        AppColors.error,   const Color(0xFFFEE2E2)),
      _     => (Icons.help,          AppColors.textHint, AppColors.border),
    };

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: actualizando ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: accent.withValues(alpha: 0.12),
              child: Text(
                item.nombreCompleto.isNotEmpty ? item.nombreCompleto[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (item.dorsal != null) ...[
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('#${item.dorsal}',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: accent)),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(child: Text(item.nombreCompleto,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              if (item.motivoLabel != null && item.confirma == false) ...[
                const SizedBox(height: 2),
                Text(item.motivoLabel!,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ])),
            if (actualizando)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(iconData, size: 16, color: iconColor),
              ),
          ]),
        ),
      ),
    );
  }
}

// ── Opciones de confirmación (BottomSheet) ────────────────────────────────────

class _AccionConfirmacion {
  final bool? confirma;
  final int?  motivo;
  const _AccionConfirmacion({this.confirma, this.motivo});
}

class _OpcionesConfirmacionSheet extends StatelessWidget {
  final ConfirmacionDto item;
  final Color accent;
  const _OpcionesConfirmacionSheet({required this.item, required this.accent});

  static const _motivos = [
    (1, 'Lesión'),
    (2, 'Trabajo'),
    (3, 'Personal'),
    (4, 'Suspensión'),
    (5, 'Otro'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.nombreCompleto,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Registrar confirmación manualmente',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
            title: const Text('Confirmar asistencia', style: TextStyle(fontSize: 13)),
            onTap: () => Navigator.pop(context, const _AccionConfirmacion(confirma: true)),
          ),
          const Divider(height: 0, thickness: 0.5, color: AppColors.border),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            leading: const Icon(Icons.cancel_outlined, color: AppColors.error),
            title: const Text('Declinar', style: TextStyle(fontSize: 13)),
            children: _motivos.map((m) => ListTile(
              contentPadding: const EdgeInsets.only(left: 32),
              dense: true,
              title: Text(m.$2, style: const TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(context, _AccionConfirmacion(confirma: false, motivo: m.$1)),
            )).toList(),
          ),
          const Divider(height: 0, thickness: 0.5, color: AppColors.border),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline, color: AppColors.textHint),
            title: const Text('Marcar como sin respuesta', style: TextStyle(fontSize: 13)),
            onTap: () => Navigator.pop(context, const _AccionConfirmacion()),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorBody({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 36, color: AppColors.textHint),
        const SizedBox(height: 10),
        Text(mensaje, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ]),
    ),
  );
}
