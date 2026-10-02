import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/cancha.dart';
import '../../canchas/data/cancha_repository.dart';

class AdminCanchasScreen extends StatefulWidget {
  const AdminCanchasScreen({super.key});

  @override
  State<AdminCanchasScreen> createState() => _AdminCanchasScreenState();
}

class _AdminCanchasScreenState extends State<AdminCanchasScreen> {
  final _repo = CanchaRepository();
  List<CanchaDto> _canchas  = [];
  bool   _loading  = true;
  bool   _mutating = false;
  String? _error;
  String  _filtroEstado = '';
  final   _searchCtrl   = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _repo.listar();
      setState(() { _canchas = r.canchas; });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Error al cargar canchas.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cambiarEstado(CanchaDto c, String nuevoEstado) async {
    setState(() => _mutating = true);
    try {
      await _repo.cambiarEstado(c.id, nuevoEstado);
      await _cargar();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  List<CanchaDto> get _filtradas {
    final texto = _searchCtrl.text.toLowerCase().trim();
    return _canchas.where((c) {
      final okTexto  = texto.isEmpty ||
          c.nombre.toLowerCase().contains(texto) ||
          (c.claveInterna?.toLowerCase().contains(texto) ?? false);
      final okEstado = _filtroEstado.isEmpty || c.estadoCancha == _filtroEstado;
      return okTexto && okEstado;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null && _canchas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _cargar,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                children: [
                  _SearchBar(ctrl: _searchCtrl),
                  const SizedBox(height: 8),
                  _FiltroEstados(
                    selected: _filtroEstado,
                    onChanged: (v) => setState(() => _filtroEstado = v),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (_filtradas.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        size: 40, color: AppColors.textHint),
                    const SizedBox(height: 10),
                    const Text('Sin resultados',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('${_canchas.length} cancha${_canchas.length != 1 ? 's' : ''} en total',
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CanchaRow(
                      cancha: _filtradas[i],
                      mutating: _mutating,
                      onCambiarEstado: _cambiarEstado,
                    ),
                  ),
                  childCount: _filtradas.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Búsqueda ───────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  const _SearchBar({required this.ctrl});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o clave…',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textHint),
          suffixIcon: ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: AppColors.textHint),
                  tooltip: '',
                  onPressed: ctrl.clear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          filled: true,
          fillColor: AppColors.surface,
        ),
        style: const TextStyle(fontSize: 13),
      );
}

// ── Filtro de estados ──────────────────────────────────────────────────────────

class _FiltroEstados extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _FiltroEstados({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const opciones = [
      ('', 'Todas'),
      ('Activa', '🟢 Activa'),
      ('Inactiva', '⚫ Inactiva'),
      ('EnMantenimiento', '🔧 Mantenimiento'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: opciones.map((o) {
          final active = selected == o.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.border,
                    width: active ? 1.5 : 0.5,
                  ),
                ),
                child: Text(o.$2,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? AppColors.primary : AppColors.textSecondary)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Row de cancha ──────────────────────────────────────────────────────────────

class _CanchaRow extends StatelessWidget {
  final CanchaDto cancha;
  final bool      mutating;
  final Future<void> Function(CanchaDto, String) onCambiarEstado;

  const _CanchaRow({
    required this.cancha,
    required this.mutating,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    final estadoColor = switch (cancha.estadoCancha) {
      'Activa'          => const Color(0xFF16A34A),
      'Inactiva'        => AppColors.textHint,
      'EnMantenimiento' => const Color(0xFFEA580C),
      _ => AppColors.textHint,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumb / icono
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.hardEdge,
                child: cancha.fotoPortadaUrl != null
                    ? Image.network(cancha.fotoPortadaUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.stadium_outlined,
                                size: 22, color: AppColors.textHint))
                    : const Icon(Icons.stadium_outlined,
                        size: 22, color: AppColors.textHint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (cancha.claveInterna != null) ...[
                          Text(cancha.claveInterna!,
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: AppColors.textHint)),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(cancha.nombre,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      children: [
                        _Tag(cancha.estadoLabel, color: estadoColor),
                        if (!cancha.visiblePublico)
                          _Tag('Oculta', color: AppColors.textHint),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Meta
          Wrap(
            spacing: 12,
            runSpacing: 2,
            children: [
              if (cancha.superficieDisplay.isNotEmpty)
                _MetaItem('🌱 ${cancha.superficieDisplay}'),
              if (cancha.tieneIluminacion)
                const _MetaItem('💡 Iluminación'),
              if (cancha.precioBaseHora != null)
                _MetaItem('💰 \$${cancha.precioBaseHora!.toStringAsFixed(0)}/hr'),
              if (cancha.disponibleReservas)
                const _MetaItem('📅 Reservas'),
              if (cancha.disponibleLigas)
                const _MetaItem('🏆 Ligas'),
            ],
          ),
          if (cancha.horarioResumen.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('🕐 ${cancha.horarioResumen}',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ],
          const SizedBox(height: 10),
          // ── Acciones
          Row(
            children: [
              if (cancha.esActiva) ...[
                _BtnEstado(
                  label: 'Desactivar',
                  icon: Icons.pause_circle_outline_rounded,
                  color: AppColors.error,
                  disabled: mutating,
                  onTap: () => _confirmarCambio(context, 'Inactiva'),
                ),
                const SizedBox(width: 8),
                _BtnEstado(
                  label: 'Mantenimiento',
                  icon: Icons.build_outlined,
                  color: const Color(0xFFEA580C),
                  disabled: mutating,
                  onTap: () => _confirmarCambio(context, 'EnMantenimiento'),
                ),
              ] else if (cancha.esInactiva) ...[
                _BtnEstado(
                  label: 'Activar',
                  icon: Icons.play_circle_outline_rounded,
                  color: AppColors.success,
                  disabled: mutating,
                  onTap: () => _confirmarCambio(context, 'Activa'),
                ),
              ] else if (cancha.esEnMantenimiento) ...[
                _BtnEstado(
                  label: 'Activar',
                  icon: Icons.play_circle_outline_rounded,
                  color: AppColors.success,
                  disabled: mutating,
                  onTap: () => _confirmarCambio(context, 'Activa'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _confirmarCambio(BuildContext context, String nuevoEstado) {
    final label = switch (nuevoEstado) {
      'Activa'          => 'Activar',
      'Inactiva'        => 'Desactivar',
      'EnMantenimiento' => 'Poner en Mantenimiento',
      _ => nuevoEstado,
    };
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Text(
            '¿Cambiar "${cancha.nombre}" a $label?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onCambiarEstado(cancha, nuevoEstado);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color  color;
  const _Tag(this.text, {required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}

class _MetaItem extends StatelessWidget {
  final String text;
  const _MetaItem(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textHint));
}

class _BtnEstado extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final bool     disabled;
  final VoidCallback onTap;

  const _BtnEstado({
    required this.label,
    required this.icon,
    required this.color,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: disabled ? 0.45 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ),
      );
}
