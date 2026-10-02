import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../data/manager_repository.dart';

class ManagerAlineacionScreen extends StatefulWidget {
  final String equipoId;
  final String partidoId;
  const ManagerAlineacionScreen({super.key, required this.equipoId, required this.partidoId});

  @override
  State<ManagerAlineacionScreen> createState() => _ManagerAlineacionScreenState();
}

class _ManagerAlineacionScreenState extends State<ManagerAlineacionScreen> {
  final _repo = ManagerRepository();

  AlineacionDto?      _alineacion;
  PartidoCompletoDto?  _partido;
  bool    _loading   = false;
  bool    _guardando = false;
  String? _error;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final al = await _repo.obtenerAlineacion(widget.equipoId, widget.partidoId);
      final p  = await _repo.obtenerPartido(widget.partidoId);
      if (al == null) {
        if (mounted) setState(() { _error = 'No se pudo cargar la alineación.'; _loading = false; });
        return;
      }
      if (mounted) setState(() { _alineacion = al; _partido = p; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  (int titulares, int banca) get _counts {
    final al = _alineacion!;
    return (
      al.jugadores.where((j) => j.zona == ZonaJugador.titular).length,
      al.jugadores.where((j) => j.zona == ZonaJugador.banca).length,
    );
  }

  void _toast(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(error ? Icons.error_outline : Icons.check_circle_outline,
              size: 18, color: error ? AppColors.error : AppColors.success),
          const SizedBox(width: 10),
          Expanded(child: Text(mensaje,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: (error ? AppColors.error : AppColors.success).withValues(alpha: 0.3)),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        elevation: 4,
        duration: const Duration(seconds: 3),
      ));
  }

  void _moveTo(String id, ZonaJugador zona, [double x = 50, double y = 50]) {
    final al = _alineacion!;
    final j = al.jugadores.firstWhere((j) => j.jugadorEquipoId == id);
    final (titulares, banca) = _counts;

    if (zona == ZonaJugador.titular && j.zona != ZonaJugador.titular && titulares >= al.jugadoresEnCampo) {
      _toast('Ya tienes ${al.jugadoresEnCampo} titulares.', error: true);
      return;
    }
    if (zona == ZonaJugador.banca && j.zona != ZonaJugador.banca && banca >= al.suplentesPermitidos) {
      _toast('Ya tienes ${al.suplentesPermitidos} jugadores en la banca.', error: true);
      return;
    }

    setState(() {
      j.zona = zona;
      if (zona == ZonaJugador.titular) {
        j.posX = x.clamp(2, 98);
        j.posY = y.clamp(2, 98);
      }
      _selectedId = null;
    });
  }

  void _abrirOpciones(JugadorAlineacion j) {
    if (_alineacion?.editable != true) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text(j.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(j.posicionLabel),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.sports_soccer_outlined),
            title: Text(j.zona == ZonaJugador.titular ? 'Reposicionar en la cancha' : 'Poner como titular'),
            subtitle: const Text('Toca la cancha para colocarlo'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedId = j.jugadorEquipoId);
            },
          ),
          if (j.zona != ZonaJugador.banca)
            ListTile(
              leading: const Icon(Icons.event_seat_outlined),
              title: const Text('Mover a banca'),
              onTap: () { Navigator.pop(context); _moveTo(j.jugadorEquipoId, ZonaJugador.banca); },
            ),
          if (j.zona != ZonaJugador.disponible)
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text('Mover a disponibles'),
              onTap: () { Navigator.pop(context); _moveTo(j.jugadorEquipoId, ZonaJugador.disponible); },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final err = await _repo.guardarAlineacion(widget.equipoId, widget.partidoId, _alineacion!.jugadores);
    if (!mounted) return;
    setState(() => _guardando = false);
    if (err != null) {
      _toast(err, error: true);
    } else {
      _toast('Alineación guardada correctamente');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = RolePalettes.accentForRol('Manager');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Alineación', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(mensaje: _error!, onRetry: _cargar)
              : _buildBody(accent),
      bottomNavigationBar: (_alineacion?.editable == true)
          ? SafeArea(
              minimum: const EdgeInsets.all(14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Guardar alineación', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(Color accent) {
    final al = _alineacion!;
    final (titulares, banca) = _counts;
    final titularesList    = al.jugadores.where((j) => j.zona == ZonaJugador.titular).toList();
    final bancaList        = al.jugadores.where((j) => j.zona == ZonaJugador.banca).toList();
    final disponiblesList  = al.jugadores.where((j) => j.zona == ZonaJugador.disponible).toList();

    return RefreshIndicator(
      color: accent,
      onRefresh: _cargar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_partido != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${_partido!.equipoLocalNombre} vs ${_partido!.equipoVisitanteNombre}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),

          Row(children: [
            Expanded(child: _CountChip(label: 'de ${al.jugadoresEnCampo} titulares', value: titulares, accent: accent)),
            const SizedBox(width: 8),
            Expanded(child: _CountChip(label: 'de ${al.suplentesPermitidos} en banca', value: banca, accent: accent)),
          ]),
          const SizedBox(height: 12),

          if (!al.editable)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: Colors.amber.shade700, width: 3)),
              ),
              child: const Text(
                'Este partido ya no está programado, la alineación es de solo lectura.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),

          if (_selectedId != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Expanded(child: Text(
                  'Toca la cancha para colocar a ${al.jugadores.firstWhere((j) => j.jugadorEquipoId == _selectedId).nombreCompleto}',
                  style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600),
                )),
                TextButton(onPressed: () => setState(() => _selectedId = null), child: const Text('Cancelar')),
              ]),
            ),

          _CanchaWidget(
            titulares: titularesList,
            seleccionado: _selectedId,
            editable: al.editable,
            onTapJugador: _abrirOpciones,
            onTapCancha: (x, y) {
              if (_selectedId != null) _moveTo(_selectedId!, ZonaJugador.titular, x, y);
            },
            onDropCancha: al.editable ? (id, x, y) => _moveTo(id, ZonaJugador.titular, x, y) : null,
            accent: accent,
          ),
          const SizedBox(height: 16),

          _SeccionTitle(icon: Icons.event_seat_outlined, titulo: 'Banca'),
          const SizedBox(height: 8),
          _ZonaDestino(
            editable: al.editable,
            onDrop: (id) => _moveTo(id, ZonaJugador.banca),
            child: bancaList.isEmpty
                ? const _EmptyHint('Sin jugadores en banca')
                : Wrap(spacing: 8, runSpacing: 8, children: bancaList.map((j) => _ChipJugador(
                    jugador: j, accent: accent, seleccionado: _selectedId == j.jugadorEquipoId,
                    editable: al.editable,
                    onTap: () => _abrirOpciones(j),
                  )).toList()),
          ),
          const SizedBox(height: 20),

          _SeccionTitle(icon: Icons.list_alt_outlined, titulo: 'Disponibles'),
          const SizedBox(height: 8),
          _ZonaDestino(
            editable: al.editable,
            onDrop: (id) => _moveTo(id, ZonaJugador.disponible),
            child: disponiblesList.isEmpty
                ? const _EmptyHint('Sin jugadores disponibles')
                : Wrap(spacing: 8, runSpacing: 8, children: disponiblesList.map((j) => _ChipJugador(
                    jugador: j, accent: accent, seleccionado: _selectedId == j.jugadorEquipoId,
                    editable: al.editable,
                    onTap: () => _abrirOpciones(j),
                  )).toList()),
          ),
        ]),
      ),
    );
  }
}

// ── Cancha ────────────────────────────────────────────────────────────────────

class _CanchaWidget extends StatefulWidget {
  final List<JugadorAlineacion> titulares;
  final String? seleccionado;
  final bool   editable;
  final void Function(JugadorAlineacion) onTapJugador;
  final void Function(double x, double y) onTapCancha;
  final void Function(String id, double x, double y)? onDropCancha;
  final Color accent;
  const _CanchaWidget({
    required this.titulares, required this.seleccionado, required this.editable,
    required this.onTapJugador, required this.onTapCancha, required this.onDropCancha,
    required this.accent,
  });

  @override
  State<_CanchaWidget> createState() => _CanchaWidgetState();
}

class _CanchaWidgetState extends State<_CanchaWidget> {
  final _boxKey = GlobalKey();

  Offset? _localFromGlobal(Offset global) {
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.globalToLocal(global);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        const Align(alignment: Alignment.centerLeft, child: Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('⚽ Cancha — Titulares', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        )),
        AspectRatio(
          aspectRatio: 2 / 3,
          child: LayoutBuilder(builder: (context, constraints) {
            return DragTarget<String>(
              onWillAcceptWithDetails: (_) => widget.onDropCancha != null,
              onAcceptWithDetails: (details) {
                final local = _localFromGlobal(details.offset);
                if (local == null) return;
                final x = local.dx / constraints.maxWidth * 100;
                final y = local.dy / constraints.maxHeight * 100;
                widget.onDropCancha?.call(details.data, x, y);
              },
              builder: (context, candidate, rejected) => GestureDetector(
                onTapUp: (details) {
                  final x = details.localPosition.dx / constraints.maxWidth * 100;
                  final y = details.localPosition.dy / constraints.maxHeight * 100;
                  widget.onTapCancha(x, y);
                },
                child: Container(
                  key: _boxKey,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: candidate.isNotEmpty ? Border.all(color: widget.accent, width: 3) : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(children: [
                      CustomPaint(size: Size(constraints.maxWidth, constraints.maxHeight), painter: _CanchaPainter()),
                      ...widget.titulares.map((j) {
                        final ax = (j.posX / 100) * 2 - 1;
                        final ay = (j.posY / 100) * 2 - 1;
                        return Align(
                          alignment: Alignment(ax, ay),
                          child: GestureDetector(
                            onTap: () => widget.onTapJugador(j),
                            child: widget.editable
                                ? LongPressDraggable<String>(
                                    data: j.jugadorEquipoId,
                                    dragAnchorStrategy: pointerDragAnchorStrategy,
                                    feedback: _AvatarCampo(jugador: j, accent: widget.accent, seleccionado: true),
                                    childWhenDragging: Opacity(opacity: 0.3, child: _AvatarCampo(jugador: j, accent: widget.accent, seleccionado: false)),
                                    child: _AvatarCampo(jugador: j, accent: widget.accent, seleccionado: widget.seleccionado == j.jugadorEquipoId),
                                  )
                                : _AvatarCampo(jugador: j, accent: widget.accent, seleccionado: false),
                          ),
                        );
                      }),
                    ]),
                  ),
                ),
              ),
            );
          }),
        ),
        if (widget.editable)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '💡 Mantén presionado un jugador y arrástralo a la cancha, o tócalo para elegir una acción.',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ),
      ]),
    );
  }
}

class _CanchaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF16A34A), Color(0xFF15803D)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final inset = 8.0;
    canvas.drawRect(Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2), line);
    canvas.drawLine(Offset(inset, size.height / 2), Offset(size.width - inset, size.height / 2), line);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 40, line);

    final boxW = 120.0, boxH = 50.0;
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - boxW / 2, inset, boxW, boxH), line);
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - boxW / 2, size.height - inset - boxH, boxW, boxH), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AvatarCampo extends StatelessWidget {
  final JugadorAlineacion jugador;
  final Color accent;
  final bool  seleccionado;
  const _AvatarCampo({required this.jugador, required this.accent, required this.seleccionado});

  @override
  Widget build(BuildContext context) {
    final fotoUrl = Env.toAbsolutePhotoUrl(jugador.fotoUrl);
    return SizedBox(
      width: 54,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: seleccionado ? Colors.amber.shade700 : accent, width: seleccionado ? 3 : 2),
          ),
          clipBehavior: Clip.hardEdge,
          child: fotoUrl != null
              ? CachedNetworkImage(imageUrl: fotoUrl, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _iniciales(accent))
              : _iniciales(accent),
        ),
        const SizedBox(height: 2),
        Text(
          '${jugador.dorsalPartido != null ? '#${jugador.dorsalPartido} ' : ''}${jugador.nombreCompleto.split(' ').first}',
          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white,
              shadows: [Shadow(color: Colors.black54, blurRadius: 2)]),
        ),
      ]),
    );
  }

  Widget _iniciales(Color accent) => Center(
        child: Text(jugador.nombreCompleto.isNotEmpty ? jugador.nombreCompleto[0].toUpperCase() : '?',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent)),
      );
}

// ── Zona destino (Banca / Disponibles) ──────────────────────────────────────────

class _ZonaDestino extends StatelessWidget {
  final bool editable;
  final void Function(String jugadorEquipoId) onDrop;
  final Widget child;
  const _ZonaDestino({required this.editable, required this.onDrop, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!editable) return child;
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidate, rejected) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: candidate.isNotEmpty
              ? Border.all(color: RolePalettes.accentForRol('Manager'), width: 1.5, style: BorderStyle.solid)
              : null,
        ),
        child: child,
      ),
    );
  }
}

// ── Chip de jugador (Banca / Disponibles) ──────────────────────────────────────

class _ChipJugador extends StatelessWidget {
  final JugadorAlineacion jugador;
  final Color accent;
  final bool  seleccionado;
  final bool  editable;
  final VoidCallback onTap;
  const _ChipJugador({
    required this.jugador, required this.accent, required this.seleccionado,
    required this.editable, required this.onTap,
  });

  Widget _contenido(BuildContext context) {
    final fotoUrl = Env.toAbsolutePhotoUrl(jugador.fotoUrl);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: seleccionado ? accent : AppColors.border, width: seleccionado ? 1.5 : 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: accent.withValues(alpha: 0.12),
          backgroundImage: fotoUrl != null ? CachedNetworkImageProvider(fotoUrl) : null,
          child: fotoUrl == null
              ? Text(jugador.nombreCompleto.isNotEmpty ? jugador.nombreCompleto[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent))
              : null,
        ),
        const SizedBox(width: 6),
        if (jugador.dorsal != null) ...[
          Text('#${jugador.dorsal}', style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
        ],
        Text(jugador.nombreCompleto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(width: 6),
        Text(jugador.posicionLabel, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chip = InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: _contenido(context));
    if (!editable) return chip;
    return LongPressDraggable<String>(
      data: jugador.jugadorEquipoId,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(color: Colors.transparent, child: _contenido(context)),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip,
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _CountChip extends StatelessWidget {
  final String label;
  final int    value;
  final Color  accent;
  const _CountChip({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: Column(children: [
      Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
    ]),
  );
}

class _SeccionTitle extends StatelessWidget {
  final IconData icon;
  final String   titulo;
  const _SeccionTitle({required this.icon, required this.titulo});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: AppColors.textSecondary),
    const SizedBox(width: 6),
    Text(titulo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
  ]);
}

class _EmptyHint extends StatelessWidget {
  final String texto;
  const _EmptyHint(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(texto, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
  );
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
        Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ]),
    ),
  );
}
