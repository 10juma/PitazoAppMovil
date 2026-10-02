import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../staff/data/staff_reservas_repository.dart';
import '../../../models/reserva_dto.dart';

// Prefijos ordenados del más largo al más corto para detección correcta
const _kCodigos = [
  ('502', '🇬🇹 +502'), ('503', '🇸🇻 +503'), ('504', '🇭🇳 +504'),
  ('505', '🇳🇮 +505'), ('506', '🇨🇷 +506'), ('507', '🇵🇦 +507'),
  ('52',  '🇲🇽 +52'),  ('57',  '🇨🇴 +57'),  ('58',  '🇻🇪 +58'),
  ('51',  '🇵🇪 +51'),  ('56',  '🇨🇱 +56'),  ('54',  '🇦🇷 +54'),
  ('55',  '🇧🇷 +55'),  ('34',  '🇪🇸 +34'),  ('1',   '🇺🇸 +1'),
];

// ─── Entry point ─────────────────────────────────────────────────────────────

Future<void> showReservaSheet(
  BuildContext context, {
  ReservaDto?          reserva,
  required List<CanchaSimple>   canchas,
  required List<EquipoSimpleR>  equipos,
  required StaffReservasRepository repo,
  required VoidCallback onGuardado,
}) async {
  await showModalBottomSheet(
    context:          context,
    isScrollControlled: true,
    useSafeArea:      true,
    backgroundColor:  Colors.transparent,
    builder: (_) => _ReservaSheet(
      reserva:    reserva,
      canchas:    canchas,
      equipos:    equipos,
      repo:       repo,
      onGuardado: onGuardado,
    ),
  );
}

// ─── Sheet ───────────────────────────────────────────────────────────────────

class _ReservaSheet extends StatefulWidget {
  const _ReservaSheet({
    this.reserva,
    required this.canchas,
    required this.equipos,
    required this.repo,
    required this.onGuardado,
  });

  final ReservaDto?          reserva;
  final List<CanchaSimple>   canchas;
  final List<EquipoSimpleR>  equipos;
  final StaffReservasRepository repo;
  final VoidCallback         onGuardado;

  bool get esNueva => reserva == null;

  @override
  State<_ReservaSheet> createState() => _ReservaSheetState();
}

class _ReservaSheetState extends State<_ReservaSheet> {
  // forma
  late String?   _canchaId;
  late DateTime  _fecha;
  late int       _hora;
  late int       _duracion;
  final _nombre         = TextEditingController();
  String _codigoPais    = '52';
  final _telefonoNumero = TextEditingController();
  final _email          = TextEditingController();
  late String?   _equipoId;
  late int?      _metodoPago;
  late bool      _depositoPagado;
  late bool      _totalPagado;
  final _notaInterna = TextEditingController();
  final _notaCliente = TextEditingController();

  // estado
  bool     _guardando     = false;
  String?  _error;
  bool     _mostrarMotivo = false;
  final _motivo = TextEditingController();

  @override
  void initState() {
    super.initState();
    final r = widget.reserva;
    _canchaId      = r?.canchaId;
    _fecha         = r != null ? _parseFecha(r.fecha) : DateTime.now();
    _hora          = r?.horaInicioNum ?? 9;
    _duracion      = r?.duracionHoras ?? 1;
    _nombre.text   = r?.nombreCliente ?? '';
    _parseTelefono(r?.telefonoCliente);
    _email.text    = r?.emailCliente ?? '';
    _equipoId      = r?.equipoId;
    _metodoPago    = r?.metodoPago;
    _depositoPagado = r?.depositoPagado ?? false;
    _totalPagado    = r?.totalPagado ?? false;
    _notaInterna.text = r?.notaInterna ?? '';
    _notaCliente.text = r?.notaCliente ?? '';
  }

  @override
  void dispose() {
    _nombre.dispose(); _telefonoNumero.dispose(); _email.dispose();
    _notaInterna.dispose(); _notaCliente.dispose(); _motivo.dispose();
    super.dispose();
  }

  void _parseTelefono(String? tel) {
    if (tel == null || tel.isEmpty) { _codigoPais = '52'; return; }
    for (final (codigo, _) in _kCodigos) {
      if (tel.startsWith(codigo)) {
        _codigoPais = codigo;
        _telefonoNumero.text = tel.substring(codigo.length);
        return;
      }
    }
    _codigoPais = '52';
    _telefonoNumero.text = tel;
  }

  DateTime _parseFecha(String s) {
    try { return DateTime.parse(s); } catch (_) { return DateTime.now(); }
  }

  String _fechaStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _seleccionarFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d != null) setState(() => _fecha = d);
  }

  String? get _telefonoCombinado {
    final num = _telefonoNumero.text.trim();
    return num.isEmpty ? null : '$_codigoPais$num';
  }

  Future<void> _guardar() async {
    if (_canchaId == null) {
      setState(() => _error = 'Selecciona una cancha.');
      return;
    }
    if (_nombre.text.trim().isEmpty) {
      setState(() => _error = 'El nombre del cliente es obligatorio.');
      return;
    }
    setState(() { _error = null; _guardando = true; });
    try {
      if (widget.esNueva) {
        await widget.repo.crear(
          canchaId:      _canchaId!,
          fecha:         _fechaStr(_fecha),
          horaInicio:    _hora,
          duracionHoras: _duracion,
          nombreCliente: _nombre.text.trim(),
          telefono:      _telefonoCombinado,
          email:         _email.text.trim().isEmpty ? null : _email.text.trim(),
          equipoId:      _equipoId,
          metodoPago:    _metodoPago,
          depositoPagado: _depositoPagado,
          totalPagado:   _totalPagado,
          notaInterna:   _notaInterna.text.trim().isEmpty ? null : _notaInterna.text.trim(),
          notaCliente:   _notaCliente.text.trim().isEmpty ? null : _notaCliente.text.trim(),
        );
      } else {
        await widget.repo.actualizar(
          widget.reserva!.id,
          canchaId:      _canchaId!,
          fecha:         _fechaStr(_fecha),
          horaInicio:    _hora,
          duracionHoras: _duracion,
          nombreCliente: _nombre.text.trim(),
          telefono:      _telefonoCombinado,
          email:         _email.text.trim().isEmpty ? null : _email.text.trim(),
          equipoId:      _equipoId,
          metodoPago:    _metodoPago,
          depositoPagado: _depositoPagado,
          totalPagado:   _totalPagado,
          notaInterna:   _notaInterna.text.trim().isEmpty ? null : _notaInterna.text.trim(),
          notaCliente:   _notaCliente.text.trim().isEmpty ? null : _notaCliente.text.trim(),
        );
      }
      if (!mounted) return;
      widget.onGuardado();
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Error al guardar. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _cambiarEstado(EstadoReserva estado) async {
    final motivo = estado == EstadoReserva.cancelada ? _motivo.text.trim() : null;
    setState(() { _guardando = true; _error = null; });
    try {
      await widget.repo.cambiarEstado(widget.reserva!.id, estado, motivo: motivo);
      if (!mounted) return;
      widget.onGuardado();
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Error al cambiar estado.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _abrirWa() async {
    final tel = '$_codigoPais${_telefonoNumero.text.trim()}';
    if (_telefonoNumero.text.trim().isEmpty) return;
    final texto = Uri.encodeComponent('Hola ${_nombre.text.trim()}, te contactamos sobre tu reserva.');
    final waApp = Uri.parse('whatsapp://send?phone=$tel&text=$texto');
    final waWeb = Uri.parse('https://wa.me/$tel?text=$texto');
    if (await canLaunchUrl(waApp)) {
      await launchUrl(waApp, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(waWeb, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r  = widget.reserva;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize:     0.5,
      maxChildSize:     0.97,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color:        cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(children: [
          // handle
          const SizedBox(height: 8),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)))),
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(children: [
              Expanded(child: Text(
                widget.esNueva ? 'Nueva reserva' : r!.nombreCliente,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              )),
              if (!widget.esNueva && _telefonoNumero.text.trim().isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                  tooltip: 'WhatsApp cliente',
                  onPressed: _abrirWa,
                ),
              if (!widget.esNueva)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _EstadoBadge(estado: r!.estado),
                ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(height: 16),
          // body
          Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [

              // ── Horario ──────────────────────────────────────────────────
              _SecLabel('Horario'),
              _DropdownField<String?>(
                label: 'Cancha *',
                value: _canchaId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Selecciona —')),
                  ...widget.canchas.map((c) => DropdownMenuItem(value: c.id, child: Text(c.display, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _canchaId = v),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _FechaField(fecha: _fecha, onTap: _seleccionarFecha)),
                const SizedBox(width: 10),
                Expanded(child: _DropdownField<int>(
                  label: 'Hora inicio *',
                  value: _hora,
                  items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text('${i.toString().padLeft(2,'0')}:00'))),
                  onChanged: (v) => setState(() => _hora = v!),
                )),
              ]),
              const SizedBox(height: 10),
              _DropdownField<int>(
                label: 'Duración',
                value: _duracion,
                items: List.generate(8, (i) => DropdownMenuItem(value: i+1, child: Text('${i+1} hora${i > 0 ? 's' : ''}'))),
                onChanged: (v) => setState(() => _duracion = v!),
              ),

              // ── Cliente ───────────────────────────────────────────────────
              const SizedBox(height: 20),
              _SecLabel('Cliente'),
              _Campo(ctrl: _nombre, label: 'Nombre *', hint: 'ej. Juan Pérez'),
              const SizedBox(height: 10),
              _TelefonoField(
                codigo: _codigoPais,
                ctrl:   _telefonoNumero,
                onCodigoChanged: (v) => setState(() => _codigoPais = v),
              ),
              const SizedBox(height: 10),
              _Campo(ctrl: _email, label: 'Email', hint: 'cliente@email.com',
                keyboard: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _DropdownField<String?>(
                label: 'Equipo (opcional)',
                value: _equipoId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Sin equipo —')),
                  ...widget.equipos.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _equipoId = v),
              ),

              // ── Pago ─────────────────────────────────────────────────────
              const SizedBox(height: 20),
              _SecLabel('Pago'),
              if (!widget.esNueva)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('Total: \$${r!.total.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              _DropdownField<int?>(
                label: 'Método de pago',
                value: _metodoPago,
                items: const [
                  DropdownMenuItem(value: null, child: Text('— No especificado —')),
                  DropdownMenuItem(value: 1, child: Text('Efectivo')),
                  DropdownMenuItem(value: 2, child: Text('Transferencia')),
                  DropdownMenuItem(value: 3, child: Text('Tarjeta débito')),
                  DropdownMenuItem(value: 4, child: Text('Tarjeta crédito')),
                  DropdownMenuItem(value: 6, child: Text('Otro')),
                ],
                onChanged: (v) => setState(() => _metodoPago = v),
              ),
              const SizedBox(height: 8),
              if (!widget.esNueva && r!.deposito != null)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Depósito pagado (\$${r.deposito!.toStringAsFixed(0)})'),
                  value: _depositoPagado,
                  onChanged: (v) => setState(() => _depositoPagado = v!),
                ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Total pagado'),
                value: _totalPagado,
                onChanged: (v) => setState(() => _totalPagado = v!),
              ),

              // ── Notas ─────────────────────────────────────────────────────
              const SizedBox(height: 20),
              _SecLabel('Notas'),
              _Campo(ctrl: _notaInterna, label: 'Nota interna (solo admin)', hint: 'ej. Cliente frecuente', maxLines: 2),
              const SizedBox(height: 10),
              _Campo(ctrl: _notaCliente, label: 'Nota para el cliente', hint: 'ej. Trae balón', maxLines: 2),

              // ── Error + Guardar ───────────────────────────────────────────
              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar'),
                ),
              ),

              // ── Cambiar estado (solo edición, no Cancelada) ──────────────
              if (!widget.esNueva && r!.estado != EstadoReserva.cancelada) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                _SecLabel('Cambiar estado'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (r.estado != EstadoReserva.confirmada)
                    _AccionBtn(label: '✅ Confirmar', color: const Color(0xFF16A34A), bg: const Color(0xFFDCFCE7),
                        onTap: _guardando ? null : () => _cambiarEstado(EstadoReserva.confirmada)),
                  if (r.estado != EstadoReserva.completada)
                    _AccionBtn(label: '🏁 Completada', color: const Color(0xFF15803D), bg: const Color(0xFFF0FDF4),
                        onTap: _guardando ? null : () => _cambiarEstado(EstadoReserva.completada)),
                  if (r.estado != EstadoReserva.noShow)
                    _AccionBtn(label: '👻 No Show', color: const Color(0xFFB45309), bg: const Color(0xFFFEF3C7),
                        onTap: _guardando ? null : () => _cambiarEstado(EstadoReserva.noShow)),
                  _AccionBtn(label: '❌ Cancelar', color: const Color(0xFFDC2626), bg: const Color(0xFFFEE2E2),
                      onTap: _guardando ? null : () => setState(() => _mostrarMotivo = !_mostrarMotivo)),
                ]),
                if (_mostrarMotivo) ...[
                  const SizedBox(height: 12),
                  _Campo(ctrl: _motivo, label: 'Motivo de cancelación', hint: 'ej. Cliente canceló...', maxLines: 2),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626), side: const BorderSide(color: Color(0xFFDC2626))),
                      onPressed: _guardando ? null : () => _cambiarEstado(EstadoReserva.cancelada),
                      child: const Text('Confirmar cancelación'),
                    ),
                  ),
                ],
              ],

              if (!widget.esNueva && r!.motivoCancel != null && r.motivoCancel!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Motivo cancelación', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                    const SizedBox(height: 4),
                    Text(r.motivoCancel!, style: const TextStyle(fontSize: 13)),
                  ]),
                ),
              ],
            ],
          )),
        ]),
      ),
    );
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

class _TelefonoField extends StatelessWidget {
  final String  codigo;
  final TextEditingController ctrl;
  final ValueChanged<String>  onCodigoChanged;

  const _TelefonoField({required this.codigo, required this.ctrl, required this.onCodigoChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Teléfono', style: TextStyle(fontSize: 11, color: cs.outline)),
      const SizedBox(height: 4),
      Row(children: [
        // Dropdown código de país
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.outline),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: codigo,
              isDense: true,
              items: _kCodigos.map((e) => DropdownMenuItem(
                value: e.$1,
                child: Text(e.$2, style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (v) { if (v != null) onCodigoChanged(v); },
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Número (10 dígitos)
        Expanded(child: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 10,
          decoration: const InputDecoration(
            hintText: '5512345678',
            counterText: '',
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        )),
      ]),
    ]);
  }
}

class _EstadoBadge extends StatelessWidget {
  final EstadoReserva estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: estado.bg, borderRadius: BorderRadius.circular(6)),
    child: Text(estado.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: estado.color)),
  );
}

class _SecLabel extends StatelessWidget {
  final String text;
  const _SecLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.outline, letterSpacing: 0.5)),
  );
}

class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String  label;
  final String? hint;
  final int     maxLines;
  final TextInputType? keyboard;

  const _Campo({required this.ctrl, required this.label, this.hint, this.maxLines = 1, this.keyboard});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline)),
    const SizedBox(height: 4),
    TextField(
      controller: ctrl,
      maxLines:   maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText:      hint,
        border:        const OutlineInputBorder(),
        isDense:       true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    ),
  ]);
}

class _DropdownField<T> extends StatelessWidget {
  final String                     label;
  final T                          value;
  final List<DropdownMenuItem<T>>  items;
  final ValueChanged<T?>           onChanged;

  const _DropdownField({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline)),
    const SizedBox(height: 4),
    DropdownButtonFormField<T>(
      initialValue: value,
      items:       items,
      onChanged:   onChanged,
      isExpanded:  true,
      decoration:  const InputDecoration(border: OutlineInputBorder(), isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
    ),
  ]);
}

class _FechaField extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback onTap;

  const _FechaField({required this.fecha, required this.onTap});

  String get _label {
    final f = fecha;
    return '${f.day.toString().padLeft(2,'0')}/${f.month.toString().padLeft(2,'0')}/${f.year}';
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Fecha *', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline)),
    const SizedBox(height: 4),
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 16),
          const SizedBox(width: 6),
          Text(_label, style: const TextStyle(fontSize: 14)),
        ]),
      ),
    ),
  ]);
}

class _AccionBtn extends StatelessWidget {
  final String   label;
  final Color    color;
  final Color    bg;
  final VoidCallback? onTap;

  const _AccionBtn({required this.label, required this.color, required this.bg, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, border: Border.all(color: color.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    ),
  );
}
