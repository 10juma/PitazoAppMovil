import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/equipo_dto.dart';
import '../../../shared/enums/estado_equipo.dart';
import '../../../shared/enums/estado_jugador.dart';
import '../../staff/data/staff_equipos_repository.dart';

/// Abre el panel de detalle del equipo.
Future<void> showEquipoDetalleSheet(
  BuildContext context,
  EquipoDto equipo, {
  required bool tieneWhatsApp,
}) async {
  final repo = StaffEquiposRepository();
  await showModalBottomSheet<void>(
    context:            context,
    isScrollControlled: true,
    useSafeArea:        true,
    backgroundColor:    Colors.transparent,
    builder: (_) => _EquipoDetalleSheet(
      equipoInicial:  equipo,
      tieneWhatsApp:  tieneWhatsApp,
      repo:           repo,
    ),
  );
}

// ─── Sheet raíz ─────────────────────────────────────────────────────────────

class _EquipoDetalleSheet extends StatefulWidget {
  const _EquipoDetalleSheet({
    required this.equipoInicial,
    required this.tieneWhatsApp,
    required this.repo,
  });
  final EquipoDto               equipoInicial;
  final bool                    tieneWhatsApp;
  final StaffEquiposRepository  repo;

  @override
  State<_EquipoDetalleSheet> createState() => _EquipoDetalleSheetState();
}

class _EquipoDetalleSheetState extends State<_EquipoDetalleSheet>
    with SingleTickerProviderStateMixin {
  late EquipoDto   _equipo;
  bool             _cargandoDetalle = false;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _equipo = widget.equipoInicial;
    _tabs   = TabController(length: 2, vsync: this);
    // Si la lista no trajo jugadores, cargar el detalle completo
    if (_equipo.jugadores.isEmpty) _cargarDetalle();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _cargarDetalle() async {
    setState(() => _cargandoDetalle = true);
    try {
      final detalle = await widget.repo.obtener(_equipo.id);
      if (mounted) setState(() { _equipo = detalle; _cargandoDetalle = false; });
    } catch (_) {
      if (mounted) setState(() => _cargandoDetalle = false);
    }
  }

  void _marcarCambio() => _cargarDetalle();

  @override
  Widget build(BuildContext context) {
    final colorEq = _hexColor(_equipo.colorPrincipal) ?? const Color(0xFF2563EB);

    return Container(
      height:     MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _DragHandle(),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _EquipoHeader(
              equipo:        _equipo,
              colorEq:       colorEq,
              tieneWhatsApp: widget.tieneWhatsApp,
              onCambiarEstado: (e) async {
                  await widget.repo.cambiarEstado(_equipo.id, e);
                  _marcarCambio();
                },
            ),
          ),
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Plantilla'),
              Tab(text: 'Editar'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // Tab 1: Plantilla
                _cargandoDetalle
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _TabPlantilla(
                        equipo:           _equipo,
                        repo:             widget.repo,
                        onCambio:         _marcarCambio,
                      ),
                // Tab 2: Editar
                _TabEditar(
                  equipo:   _equipo,
                  repo:     widget.repo,
                  onGuardado: _marcarCambio,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _EquipoHeader extends StatelessWidget {
  const _EquipoHeader({
    required this.equipo,
    required this.colorEq,
    required this.tieneWhatsApp,
    required this.onCambiarEstado,
  });
  final EquipoDto          equipo;
  final Color              colorEq;
  final bool               tieneWhatsApp;
  final Future<void> Function(EstadoEquipo) onCambiarEstado;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: colorEq.withValues(alpha: 0.15),
          radius: 28,
          child: Env.toAbsolutePhotoUrl(equipo.logoUrl) != null
              ? ClipOval(child: Image.network(Env.toAbsolutePhotoUrl(equipo.logoUrl)!, width: 56, height: 56, fit: BoxFit.cover))
              : Text(equipo.nombre.isNotEmpty ? equipo.nombre[0].toUpperCase() : '?',
                  style: TextStyle(color: colorEq, fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(equipo.nombre,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  ),
                  _EstadoBadgeLg(estado: equipo.estado, label: equipo.estadoLabel),
                ],
              ),
              const SizedBox(height: 2),
              Text('${equipo.tipoLabel}  ·  ${equipo.totalActivos} activos / ${equipo.totalJugadores} jugadores',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              if (equipo.colorPrincipal != null) ...[
                const SizedBox(height: 3),
                Row(children: [
                  _ColorDot(hex: equipo.colorPrincipal),
                  if (equipo.colorSecundario != null) ...[
                    const SizedBox(width: 3),
                    _ColorDot(hex: equipo.colorSecundario),
                  ],
                ]),
              ],
            ],
          ),
        ),
        // Botones rápidos
        Column(
          children: [
            if (tieneWhatsApp && equipo.manager?.telefono.isNotEmpty == true)
              IconButton(
                icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                tooltip: 'WhatsApp manager',
                onPressed: () => _abrirWa(context),
              ),
            _MenuEstado(equipo: equipo, onChange: onCambiarEstado),
          ],
        ),
      ],
    );
  }

  void _abrirWa(BuildContext context) async {
    final tel = equipo.manager!.telefono.replaceAll(RegExp(r'[+\s\-]'), '');
    final texto = Uri.encodeComponent(
      'Hola ${equipo.manager!.nombre}, te contactamos sobre el equipo ${equipo.nombre}.',
    );
    // Esquema nativo de WhatsApp (abre la app directamente)
    final waApp  = Uri.parse('whatsapp://send?phone=$tel&text=$texto');
    // Fallback web si WhatsApp no está instalado
    final waWeb  = Uri.parse('https://wa.me/$tel?text=$texto');
    if (await canLaunchUrl(waApp)) {
      await launchUrl(waApp, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(waWeb, mode: LaunchMode.externalApplication);
    }
  }
}

class _MenuEstado extends StatefulWidget {
  const _MenuEstado({required this.equipo, required this.onChange});
  final EquipoDto equipo;
  final Future<void> Function(EstadoEquipo) onChange;

  @override
  State<_MenuEstado> createState() => _MenuEstadoState();
}

class _MenuEstadoState extends State<_MenuEstado> {
  bool _guardando = false;

  Future<void> _cambiar(EstadoEquipo e) async {
    setState(() => _guardando = true);
    try {
      await widget.onChange(e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_guardando) {
      return const SizedBox(width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2));
    }

    final opciones = EstadoEquipo.values
        .where((e) => e != widget.equipo.estado)
        .toList();

    return PopupMenuButton<EstadoEquipo>(
      icon: const Icon(Icons.more_vert, color: AppColors.textHint),
      tooltip: 'Cambiar estado',
      onSelected: _cambiar,
      itemBuilder: (_) => opciones.map((e) => PopupMenuItem(
        value: e,
        child: Text(_estadoLabel(e)),
      )).toList(),
    );
  }

  String _estadoLabel(EstadoEquipo e) => switch (e) {
        EstadoEquipo.activo   => 'Activar',
        EstadoEquipo.inactivo => 'Desactivar',
        EstadoEquipo.disuelto => 'Marcar como disuelto',
      };
}

// ─── Tab: Plantilla ──────────────────────────────────────────────────────────

class _TabPlantilla extends StatelessWidget {
  const _TabPlantilla({
    required this.equipo,
    required this.repo,
    required this.onCambio,
  });
  final EquipoDto              equipo;
  final StaffEquiposRepository repo;
  final VoidCallback           onCambio;

  @override
  Widget build(BuildContext context) {
    final colorEq = _hexColor(equipo.colorPrincipal) ?? const Color(0xFF2563EB);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Info manager
        if (equipo.manager != null) _ManagerCard(manager: equipo.manager!),
        const SizedBox(height: 12),
        // Botón agregar jugador
        OutlinedButton.icon(
          onPressed: () => _abrirAgregarJugador(context),
          icon:  const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('Agregar jugador'),
        ),
        const SizedBox(height: 12),
        // Lista de jugadores
        if (equipo.jugadores.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Sin jugadores registrados.',
                style: TextStyle(color: AppColors.textHint)),
            ),
          )
        else
          ...equipo.jugadores.map((j) => _JugadorTile(
            jugador:  j,
            colorEq:  colorEq,
            equipoId: equipo.id,
            repo:     repo,
            onCambio: onCambio,
          )),
      ],
    );
  }

  void _abrirAgregarJugador(BuildContext context) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      useSafeArea:        true,
      backgroundColor:    Colors.transparent,
      builder: (_) => _AgregarJugadorSheet(
        equipoId: equipo.id,
        repo:     repo,
        onAgregado: onCambio,
      ),
    );
  }
}

class _ManagerCard extends StatelessWidget {
  const _ManagerCard({required this.manager});
  final ManagerEquipoDto manager;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Manager', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          const SizedBox(height: 4),
          Text(manager.nombreCompleto,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          if (manager.telefono.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(manager.telefono,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ],
          if (manager.email != null) ...[
            const SizedBox(height: 2),
            Text(manager.email!,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ],
        ],
      ),
    ),
  );
}

class _JugadorTile extends StatefulWidget {
  const _JugadorTile({
    required this.jugador,
    required this.colorEq,
    required this.equipoId,
    required this.repo,
    required this.onCambio,
  });
  final JugadorEquipoDto       jugador;
  final Color                  colorEq;
  final String                 equipoId;
  final StaffEquiposRepository repo;
  final VoidCallback           onCambio;

  @override
  State<_JugadorTile> createState() => _JugadorTileState();
}

class _JugadorTileState extends State<_JugadorTile> {
  bool _guardando = false;

  Future<void> _cambiarEstado(EstadoJugador e) async {
    setState(() => _guardando = true);
    try {
      await widget.repo.cambiarEstadoJugador(widget.equipoId, widget.jugador.id, e);
      widget.onCambio();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cambiar estado'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.jugador;
    final (badgeBg, badgeFg) = _colorEstadoJugador(j.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            backgroundColor: widget.colorEq.withValues(alpha: 0.15),
            radius: 18,
            child: Env.toAbsolutePhotoUrl(j.fotoUrl) != null
                ? ClipOval(child: Image.network(Env.toAbsolutePhotoUrl(j.fotoUrl)!, width: 36, height: 36, fit: BoxFit.cover))
                : Text(j.nombre.isNotEmpty ? j.nombre[0].toUpperCase() : '?',
                    style: TextStyle(color: widget.colorEq, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (j.dorsalBase != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Text('#${j.dorsalBase}',
                          style: TextStyle(fontSize: 11, color: widget.colorEq, fontWeight: FontWeight.bold)),
                      ),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(j.nombreCompleto,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis),
                          ),
                          if (j.tieneSancionActiva) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 10, height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD97706), shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.all(Radius.circular(2)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (j.posicionLabel != null && j.posicionLabel!.isNotEmpty) j.posicionLabel!,
                    if (j.edad != null) '${j.edad} años',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          // Badge estado + cambio
          _guardando
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : PopupMenuButton<EstadoJugador>(
                  padding: EdgeInsets.zero,
                  tooltip: 'Cambiar estado',
                  onSelected: _cambiarEstado,
                  itemBuilder: (_) => EstadoJugador.values
                      .where((e) => e != j.estado)
                      .map((e) => PopupMenuItem(
                            value: e,
                            child: Text(_estadoJugadorLabel(e)),
                          ))
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(j.estadoLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeFg)),
                  ),
                ),
        ],
      ),
    );
  }

  (Color, Color) _colorEstadoJugador(EstadoJugador e) => switch (e) {
        EstadoJugador.activo     => (const Color(0xFF166534).withValues(alpha: 0.1), const Color(0xFF166534)),
        EstadoJugador.suspendido => (const Color(0xFFD97706).withValues(alpha: 0.1), const Color(0xFFD97706)),
        EstadoJugador.lesionado  => (const Color(0xFFDC2626).withValues(alpha: 0.1), const Color(0xFFDC2626)),
        EstadoJugador.inactivo   => (const Color(0xFF6B7280).withValues(alpha: 0.1), const Color(0xFF6B7280)),
      };

  String _estadoJugadorLabel(EstadoJugador e) => switch (e) {
        EstadoJugador.activo     => 'Activo',
        EstadoJugador.suspendido => 'Suspendido',
        EstadoJugador.lesionado  => 'Lesionado',
        EstadoJugador.inactivo   => 'Inactivo',
      };
}

// ─── Tab: Editar equipo ────────────────────────────────────────────────────────

class _TabEditar extends StatefulWidget {
  const _TabEditar({required this.equipo, required this.repo, required this.onGuardado});
  final EquipoDto              equipo;
  final StaffEquiposRepository repo;
  final VoidCallback           onGuardado;

  @override
  State<_TabEditar> createState() => _TabEditarState();
}

class _TabEditarState extends State<_TabEditar> {
  late TextEditingController _nombre;
  late TextEditingController _logoUrl;
  late EstadoEquipo          _estado;
  // Manager
  late TextEditingController _mNombre;
  late TextEditingController _mApellido;
  late TextEditingController _mTelefonoNum;
  String                     _codigoPais = '+52';
  late TextEditingController _mEmail;

  bool    _guardando = false;
  String? _feedback;
  bool    _feedbackError = false;

  static const _paises = [
    ('+52',  '🇲🇽', 'México',    10),
    ('+1',   '🇺🇸', 'EE.UU.',    10),
    ('+57',  '🇨🇴', 'Colombia',  10),
    ('+54',  '🇦🇷', 'Argentina', 10),
    ('+56',  '🇨🇱', 'Chile',      9),
    ('+51',  '🇵🇪', 'Perú',       9),
    ('+55',  '🇧🇷', 'Brasil',    11),
    ('+34',  '🇪🇸', 'España',     9),
    ('+502', '🇬🇹', 'Guatemala',  8),
    ('+58',  '🇻🇪', 'Venezuela', 10),
  ];

  int get _digitosEsperados =>
      _paises.firstWhere((p) => p.$1 == _codigoPais, orElse: () => _paises.first).$4;

  @override
  void initState() {
    super.initState();
    final eq  = widget.equipo;
    final tel = eq.manager?.telefono ?? '';

    // Detectar código de país en el teléfono guardado
    final codigo = _paises
        .map((p) => p.$1)
        .where((c) => tel.startsWith(c))
        .fold('', (a, b) => b.length > a.length ? b : a);

    _codigoPais   = codigo.isNotEmpty ? codigo : '+52';
    _mTelefonoNum = TextEditingController(
      text: codigo.isNotEmpty ? tel.substring(codigo.length) : tel.replaceAll(RegExp(r'\D'), ''),
    );

    _nombre    = TextEditingController(text: eq.nombre);
    _logoUrl   = TextEditingController(text: eq.logoUrl ?? '');
    _estado    = eq.estado;
    _mNombre   = TextEditingController(text: eq.manager?.nombre ?? '');
    _mApellido = TextEditingController(text: eq.manager?.apellido ?? '');
    _mEmail    = TextEditingController(text: eq.manager?.email ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose(); _logoUrl.dispose(); _mNombre.dispose(); _mApellido.dispose();
    _mTelefonoNum.dispose(); _mEmail.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del equipo es obligatorio')),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      await widget.repo.actualizarEquipo(
        widget.equipo.id,
        nombre:  _nombre.text.trim(),
        logoUrl: _logoUrl.text.trim().isEmpty ? null : _logoUrl.text.trim(),
        estado:  _estado,
      );
      if (_mNombre.text.trim().isNotEmpty && _mApellido.text.trim().isNotEmpty) {
        await widget.repo.actualizarManager(
          widget.equipo.id,
          nombre:   _mNombre.text.trim(),
          apellido: _mApellido.text.trim(),
          telefono: '$_codigoPais${_mTelefonoNum.text.trim()}',
          email:    _mEmail.text.trim().isEmpty ? null : _mEmail.text.trim(),
        );
      }
      if (!mounted) return;
      widget.onGuardado();
      setState(() { _feedback = 'Cambios guardados'; _feedbackError = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _feedback = 'Error al guardar: $e'; _feedbackError = true; });
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Equipo ──
          const _SectionLabel('Datos del equipo'),
          const SizedBox(height: 8),
          _Campo(ctrl: _nombre, label: 'Nombre *'),
          const SizedBox(height: 10),
          _Campo(ctrl: _logoUrl, label: 'URL del logo', hint: 'https://...'),
          const SizedBox(height: 10),
          DropdownButtonFormField<EstadoEquipo>(
            initialValue: _estado,
            decoration: const InputDecoration(
              labelText: 'Estado', border: OutlineInputBorder(), isDense: true),
            items: EstadoEquipo.values.map((e) => DropdownMenuItem(
              value: e,
              child: Text(_estadoLabel(e)),
            )).toList(),
            onChanged: (v) { if (v != null) setState(() => _estado = v); },
          ),
          const SizedBox(height: 20),
          // ── Manager ──
          const _SectionLabel('Manager / Contacto'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _Campo(ctrl: _mNombre,   label: 'Nombre')),
            const SizedBox(width: 10),
            Expanded(child: _Campo(ctrl: _mApellido, label: 'Apellido')),
          ]),
          const SizedBox(height: 10),
          // ── Teléfono: código de país + número ──
          const _SectionLabel('Teléfono WhatsApp'),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de código
              Container(
                height: 42,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _codigoPais,
                    isDense: true,
                    onChanged: (v) { if (v != null) setState(() { _codigoPais = v; _mTelefonoNum.clear(); }); },
                    items: _paises.map((p) => DropdownMenuItem(
                      value: p.$1,
                      child: Text('${p.$2} ${p.$1}',
                        style: const TextStyle(fontSize: 13)),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Número
              Expanded(
                child: TextField(
                  controller: _mTelefonoNum,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_digitosEsperados),
                  ],
                  decoration: InputDecoration(
                    hintText: '1' * _digitosEsperados,
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Campo(ctrl: _mEmail, label: 'Email', hint: 'manager@ejemplo.com',
            tipo: TextInputType.emailAddress),
          const SizedBox(height: 24),
          if (_feedback != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _feedbackError
                      ? const Color(0xFFDC2626).withValues(alpha: 0.4)
                      : const Color(0xFF166534).withValues(alpha: 0.4),
                ),
              ),
              child: Row(children: [
                Icon(
                  _feedbackError ? Icons.error_outline : Icons.check_circle_outline,
                  size: 16,
                  color: _feedbackError ? const Color(0xFFDC2626) : const Color(0xFF166534),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _feedback!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _feedbackError ? const Color(0xFFDC2626) : const Color(0xFF166534),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ]),
            ),
          FilledButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }

  String _estadoLabel(EstadoEquipo e) => switch (e) {
        EstadoEquipo.activo   => 'Activo',
        EstadoEquipo.inactivo => 'Inactivo',
        EstadoEquipo.disuelto => 'Disuelto',
      };
}

// ─── Sheet: Agregar jugador ──────────────────────────────────────────────────

class _AgregarJugadorSheet extends StatefulWidget {
  const _AgregarJugadorSheet({required this.equipoId, required this.repo, required this.onAgregado});
  final String                 equipoId;
  final StaffEquiposRepository repo;
  final VoidCallback           onAgregado;

  @override
  State<_AgregarJugadorSheet> createState() => _AgregarJugadorSheetState();
}

class _AgregarJugadorSheetState extends State<_AgregarJugadorSheet> {
  final _nombre     = TextEditingController();
  final _apellido   = TextEditingController();
  final _dorsal     = TextEditingController();
  final _identificador = TextEditingController();
  DateTime? _fechaNac;
  String?   _posicion;
  bool      _guardando = false;
  String?   _error;

  static const _posiciones = ['Portero', 'Defensa', 'Mediocampista', 'Delantero'];

  @override
  void dispose() {
    _nombre.dispose(); _apellido.dispose(); _dorsal.dispose(); _identificador.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    // Validación visible en el form (no SnackBar que queda detrás del teclado)
    if (_nombre.text.trim().isEmpty || _apellido.text.trim().isEmpty) {
      setState(() => _error = 'Nombre y apellido son obligatorios.');
      return;
    }
    if (_fechaNac == null) {
      setState(() => _error = 'Selecciona la fecha de nacimiento.');
      return;
    }
    setState(() { _error = null; _guardando = true; });
    try {
      final fn = _fechaNac!;
      await widget.repo.agregarJugador(
        widget.equipoId,
        nombre:             _nombre.text.trim(),
        apellido:           _apellido.text.trim(),
        fechaNacimiento:    '${fn.year}-${fn.month.toString().padLeft(2,'0')}-${fn.day.toString().padLeft(2,'0')}',
        dorsal:             _dorsal.text.trim().isEmpty ? null : int.tryParse(_dorsal.text.trim()),
        posicion:           _posicion,
        identificadorUnico: _identificador.text.trim().isEmpty ? null : _identificador.text.trim(),
      );
      if (!mounted) return;
      widget.onAgregado();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error al guardar. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    final fechaStr = _fechaNac == null
        ? 'Seleccionar fecha'
        : '${_fechaNac!.day} ${meses[_fechaNac!.month-1]} ${_fechaNac!.year}';

    return Container(
      height:     MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _DragHandle(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Agregar jugador',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.of(context).viewInsets.bottom + 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(child: _Campo(ctrl: _nombre,   label: 'Nombre *')),
                    const SizedBox(width: 10),
                    Expanded(child: _Campo(ctrl: _apellido, label: 'Apellido *')),
                  ]),
                  const SizedBox(height: 10),
                  // Fecha nacimiento
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context:     context,
                        initialDate: DateTime(2000),
                        firstDate:   DateTime(1950),
                        lastDate:    DateTime.now(),
                      );
                      if (d != null) setState(() => _fechaNac = d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de nacimiento *',
                        border: OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                      ),
                      child: Text(fechaStr, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _Campo(ctrl: _dorsal, label: 'Dorsal',
                        tipo: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly]),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _posicion,
                        decoration: const InputDecoration(
                          labelText: 'Posición', border: OutlineInputBorder(), isDense: true),
                        hint: const Text('Sin asignar'),
                        items: _posiciones.map((p) => DropdownMenuItem(
                          value: p, child: Text(p))).toList(),
                        onChanged: (v) => setState(() => _posicion = v),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  _Campo(ctrl: _identificador, label: 'Identificador (CURP/INE)', hint: 'Opcional'),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(_error!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                        textAlign: TextAlign.center),
                    ),
                  FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Agregar jugador'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets compartidos ─────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Center(
      child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
        color: AppColors.textHint, letterSpacing: 0.5));
}

class _Campo extends StatelessWidget {
  const _Campo({required this.ctrl, required this.label, this.hint, this.tipo, this.formatters});
  final TextEditingController      ctrl;
  final String                     label;
  final String?                    hint;
  final TextInputType?             tipo;
  final List<TextInputFormatter>?  formatters;

  @override
  Widget build(BuildContext context) => TextField(
    controller:       ctrl,
    keyboardType:     tipo,
    inputFormatters:  formatters,
    decoration: InputDecoration(
      labelText:   label,
      hintText:    hint,
      border:      const OutlineInputBorder(),
      isDense:     true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.hex});
  final String? hex;

  @override
  Widget build(BuildContext context) {
    final c = _hexColor(hex);
    if (c == null) return const SizedBox.shrink();
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: c, shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
    );
  }
}

class _EstadoBadgeLg extends StatelessWidget {
  const _EstadoBadgeLg({required this.estado, required this.label});
  final EstadoEquipo estado;
  final String       label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (estado) {
      EstadoEquipo.activo   => (const Color(0xFF166534).withValues(alpha: 0.08), const Color(0xFF166534)),
      EstadoEquipo.inactivo => (const Color(0xFF6B7280).withValues(alpha: 0.1),  const Color(0xFF6B7280)),
      EstadoEquipo.disuelto => (const Color(0xFFDC2626).withValues(alpha: 0.08), const Color(0xFFDC2626)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color? _hexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  try {
    final h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    if (h.length == 8) return Color(int.parse(h, radix: 16));
  } catch (_) {}
  return null;
}
