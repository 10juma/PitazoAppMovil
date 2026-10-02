import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../staff/data/staff_comunicados_repository.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/comunicado_dto.dart';

// ─── Entry points ─────────────────────────────────────────────────────────────

Future<void> showComunicadoNuevoSheet(
  BuildContext context, {
  required StaffComunicadosRepository repo,
  required bool                   comunicacionEquiposActiva,
  required List<TemporadaOpcion>  temporadas,
  required List<EquipoOpcionC>    equipos,
  required VoidCallback           onEnviado,
}) async {
  await showModalBottomSheet(
    context:          context,
    isScrollControlled: true,
    useSafeArea:      true,
    backgroundColor:  Colors.transparent,
    builder: (_) => _ComunicadoNuevoSheet(
      repo:                     repo,
      comunicacionEquiposActiva: comunicacionEquiposActiva,
      temporadas:                temporadas,
      equipos:                   equipos,
      onEnviado:                 onEnviado,
    ),
  );
}

Future<void> showComunicadoDetalleSheet(
  BuildContext context, {
  required ComunicadoDto comunicado,
}) async {
  await showModalBottomSheet(
    context:          context,
    isScrollControlled: true,
    useSafeArea:      true,
    backgroundColor:  Colors.transparent,
    builder: (_) => _ComunicadoDetalleSheet(comunicado: comunicado),
  );
}

// ─── Compose sheet ────────────────────────────────────────────────────────────

class _ComunicadoNuevoSheet extends StatefulWidget {
  final StaffComunicadosRepository repo;
  final bool                   comunicacionEquiposActiva;
  final List<TemporadaOpcion>  temporadas;
  final List<EquipoOpcionC>    equipos;
  final VoidCallback           onEnviado;

  const _ComunicadoNuevoSheet({
    required this.repo,
    required this.comunicacionEquiposActiva,
    required this.temporadas,
    required this.equipos,
    required this.onEnviado,
  });

  @override
  State<_ComunicadoNuevoSheet> createState() => _ComunicadoNuevoSheetState();
}

class _ComunicadoNuevoSheetState extends State<_ComunicadoNuevoSheet> {
  final _titulo = TextEditingController();
  final _cuerpo = TextEditingController();

  int     _audiencia     = 1;   // Todos
  int     _audienciaRol  = 5;   // Manager por defecto
  String? _temporadaId;
  String? _equipoId;

  bool    _enviando = false;
  String? _error;

  @override
  void dispose() {
    _titulo.dispose();
    _cuerpo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_titulo.text.trim().isEmpty) {
      setState(() => _error = 'El título es obligatorio.');
      return;
    }
    if (_cuerpo.text.trim().isEmpty) {
      setState(() => _error = 'El mensaje es obligatorio.');
      return;
    }
    if (_audiencia == 3 && _temporadaId == null) {
      setState(() => _error = 'Selecciona una temporada.');
      return;
    }
    if (_audiencia == 4 && _equipoId == null) {
      setState(() => _error = 'Selecciona un equipo.');
      return;
    }

    setState(() { _enviando = true; _error = null; });
    try {
      await widget.repo.enviar(
        titulo:              _titulo.text.trim(),
        cuerpo:              _cuerpo.text.trim(),
        audiencia:           _audiencia,
        audienciaRol:        _audiencia == 2 ? _audienciaRol : null,
        audienciaTemporadaId: _audiencia == 3 ? _temporadaId : null,
        audienciaEquipoId:   _audiencia == 4 ? _equipoId    : null,
      );
      if (!mounted) return;
      widget.onEnviado();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Error al enviar. Intenta de nuevo.';
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
          const SizedBox(height: 8),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(children: [
              const Expanded(child: Text('Nuevo aviso',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(height: 16),
          Expanded(child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [

              _SecLabel('Mensaje'),
              _Campo(ctrl: _titulo, label: 'Título *', hint: 'ej. Cambio de horario — semana del 16 jun',
                  maxLength: 150),
              const SizedBox(height: 10),
              _Campo(ctrl: _cuerpo, label: 'Mensaje *',
                  hint: 'Escribe el mensaje que verán tus destinatarios...',
                  maxLines: 5, maxLength: 2000),

              const SizedBox(height: 20),
              _SecLabel('Audiencia'),
              _AudienciaSelector(
                value:    _audiencia,
                onChanged: (v) => setState(() { _audiencia = v; }),
                mostrarEquipo: widget.comunicacionEquiposActiva,
              ),

              if (_audiencia == 2) ...[
                const SizedBox(height: 10),
                _SecLabel('Rol'),
                _RolDropdown(
                  value:    _audienciaRol,
                  onChanged: (v) => setState(() => _audienciaRol = v),
                ),
              ],

              if (_audiencia == 3) ...[
                const SizedBox(height: 10),
                _SecLabel('Temporada'),
                if (widget.temporadas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('No hay temporadas disponibles.',
                        style: TextStyle(fontSize: 12, color: cs.outline)),
                  )
                else
                  _TemporadaDropdown(
                    value:      _temporadaId,
                    temporadas: widget.temporadas,
                    onChanged:  (v) => setState(() => _temporadaId = v),
                  ),

              ],

              if (_audiencia == 4) ...[
                const SizedBox(height: 10),
                _SecLabel('Equipo'),
                if (widget.equipos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('No hay equipos disponibles.',
                        style: TextStyle(fontSize: 12, color: cs.outline)),
                  )
                else
                  _EquipoDropdown(
                    value:     _equipoId,
                    equipos:   widget.equipos,
                    onChanged: (v) => setState(() => _equipoId = v),
                  ),
              ],

              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _enviando ? null : _enviar,
                  icon: _enviando
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_outlined, size: 16),
                  label: const Text('Enviar aviso'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Esta acción no se puede deshacer — los destinatarios lo recibirán de inmediato.',
                style: TextStyle(fontSize: 11, color: cs.outline),
                textAlign: TextAlign.center,
              ),
            ],
          )),
        ]),
      ),
    );
  }
}

// ─── Detalle sheet (solo lectura) ─────────────────────────────────────────────

class _ComunicadoDetalleSheet extends StatelessWidget {
  final ComunicadoDto comunicado;
  const _ComunicadoDetalleSheet({required this.comunicado});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c  = comunicado;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize:     0.4,
      maxChildSize:     0.97,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color:        cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(children: [
          const SizedBox(height: 8),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(children: [
              Expanded(child: Text(c.titulo,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(height: 16),
          Expanded(child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:        cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(c.cuerpo,
                    style: const TextStyle(fontSize: 14, height: 1.5)),
              ),
              const SizedBox(height: 20),
              _DetalleGrid(comunicado: c),
            ],
          )),
        ]),
      ),
    );
  }
}

class _DetalleGrid extends StatelessWidget {
  final ComunicadoDto comunicado;
  const _DetalleGrid({required this.comunicado});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c  = comunicado;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: [
        _GridCell(label: 'Audiencia',     value: c.audienciaResumen, cs: cs),
        _GridCell(label: 'Destinatarios', value: c.totalDestinatarios.toString(), cs: cs),
        _GridCell(label: 'Enviado',       value: c.fechaFormateada, cs: cs),
        _GridCell(label: 'Por',           value: c.creadoPorNombre ?? '—', cs: cs),
      ],
    );
  }
}

class _GridCell extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  const _GridCell({required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, color: cs.outline)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          maxLines: 2, overflow: TextOverflow.ellipsis),
    ],
  );
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

class _AudienciaSelector extends StatelessWidget {
  final int      value;
  final bool     mostrarEquipo;
  final ValueChanged<int> onChanged;
  const _AudienciaSelector({required this.value, required this.onChanged, required this.mostrarEquipo});

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final opciones = [
      (1, '📣 Todos los usuarios'),
      (2, '🏷️ Por rol'),
      (3, '🏆 Por temporada'),
      if (mostrarEquipo) (4, '⚽ Por equipo'),
    ];
    return Column(
      children: opciones.map((o) {
        final sel = value == o.$1;
        return GestureDetector(
          onTap: () => onChanged(o.$1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:  sel ? cs.primary.withValues(alpha: 0.08) : Colors.transparent,
              border: Border.all(color: sel ? cs.primary : cs.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Expanded(child: Text(o.$2,
                  style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                      color: sel ? cs.primary : cs.onSurface))),
              if (sel) Icon(Icons.check_circle, size: 16, color: cs.primary),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

class _RolDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _RolDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final label = rolesDisponibles.where((r) => r.valor == value).map((r) => r.label).firstOrNull;
    return _SelectorCampo(
      texto:       label,
      placeholder: '— Selecciona un rol —',
      onTap: () async {
        final sel = await _mostrarOpciones(
          context,
          opciones:     rolesDisponibles.map((r) => (id: r.valor.toString(), label: r.label)).toList(),
          seleccionado: value.toString(),
        );
        if (sel != null) onChanged(int.parse(sel));
      },
    );
  }
}

class _TemporadaDropdown extends StatelessWidget {
  final String?              value;
  final List<TemporadaOpcion> temporadas;
  final ValueChanged<String>  onChanged;
  const _TemporadaDropdown({required this.value, required this.temporadas, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final etiqueta = value == null
        ? null
        : temporadas.where((t) => t.id == value).map((t) => t.etiqueta).firstOrNull;
    return _SelectorCampo(
      texto:       etiqueta,
      placeholder: '— Selecciona una temporada —',
      onTap: () async {
        final sel = await _mostrarOpciones(
          context,
          opciones:      temporadas.map((t) => (id: t.id, label: t.etiqueta)).toList(),
          seleccionado:  value,
        );
        if (sel != null) onChanged(sel);
      },
    );
  }
}

class _EquipoDropdown extends StatelessWidget {
  final String?             value;
  final List<EquipoOpcionC> equipos;
  final ValueChanged<String> onChanged;
  const _EquipoDropdown({required this.value, required this.equipos, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final nombre = value == null
        ? null
        : equipos.where((e) => e.id == value).map((e) => e.nombre).firstOrNull;
    return _SelectorCampo(
      texto:       nombre,
      placeholder: '— Selecciona un equipo —',
      onTap: () async {
        final sel = await _mostrarOpciones(
          context,
          opciones:      equipos.map((e) => (id: e.id, label: e.nombre)).toList(),
          seleccionado:  value,
        );
        if (sel != null) onChanged(sel);
      },
    );
  }
}

Future<String?> _mostrarOpciones(
  BuildContext context, {
  required List<({String id, String label})> opciones,
  String? seleccionado,
}) {
  return showModalBottomSheet<String>(
    context:           context,
    isScrollControlled: true,
    backgroundColor:   Colors.transparent,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 4),
          Flexible(child: ListView(shrinkWrap: true, children: [
            for (final o in opciones)
              ListTile(
                title: Text(o.label),
                trailing: o.id == seleccionado ? Icon(Icons.check, color: cs.primary) : null,
                onTap: () => Navigator.pop(ctx, o.id),
              ),
          ])),
          const SizedBox(height: 8),
        ]),
      );
    },
  );
}

class _SelectorCampo extends StatelessWidget {
  final String?  texto;
  final String   placeholder;
  final VoidCallback onTap;
  const _SelectorCampo({required this.texto, required this.placeholder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          Expanded(child: Text(
            texto ?? placeholder,
            style: TextStyle(
              color: texto == null ? cs.outline : cs.onSurface,
              overflow: TextOverflow.ellipsis,
            ),
          )),
          Icon(Icons.arrow_drop_down, color: cs.outline),
        ]),
      ),
    );
  }
}

class _SecLabel extends StatelessWidget {
  final String text;
  const _SecLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.outline, letterSpacing: 0.5)),
  );
}

class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String  label;
  final String? hint;
  final int     maxLines;
  final int?    maxLength;

  const _Campo({required this.ctrl, required this.label, this.hint,
      this.maxLines = 1, this.maxLength});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline)),
    const SizedBox(height: 4),
    TextField(
      controller: ctrl,
      maxLines:   maxLines,
      maxLength:  maxLength,
      inputFormatters: [if (maxLength != null) LengthLimitingTextInputFormatter(maxLength)],
      decoration: InputDecoration(
        hintText:       hint,
        border:         const OutlineInputBorder(),
        isDense:        true,
        counterText:    '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    ),
  ]);
}
