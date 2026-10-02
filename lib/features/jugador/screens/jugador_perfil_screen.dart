import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../shared/widgets/biometria_switch.dart';
import '../../../shared/widgets/pitazo_button.dart';
import '../data/jugador_repository.dart';
import '../providers/jugador_perfil_provider.dart';
import '../providers/jugador_provider.dart';

const _paises = [
  ('+52',  '🇲🇽', 'México'),
  ('+1',   '🇺🇸', 'EE.UU. / Canadá'),
  ('+54',  '🇦🇷', 'Argentina'),
  ('+57',  '🇨🇴', 'Colombia'),
  ('+56',  '🇨🇱', 'Chile'),
  ('+51',  '🇵🇪', 'Perú'),
  ('+58',  '🇻🇪', 'Venezuela'),
  ('+502', '🇬🇹', 'Guatemala'),
  ('+503', '🇸🇻', 'El Salvador'),
  ('+504', '🇭🇳', 'Honduras'),
  ('+505', '🇳🇮', 'Nicaragua'),
  ('+506', '🇨🇷', 'Costa Rica'),
  ('+507', '🇵🇦', 'Panamá'),
  ('+34',  '🇪🇸', 'España'),
];

class JugadorPerfilScreen extends StatelessWidget {
  const JugadorPerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jugadorEquipoId = context.read<JugadorProvider>().equipoActivo?.jugadorEquipoId;
    return ChangeNotifierProvider(
      create: (_) => JugadorPerfilProvider(jugadorEquipoId: jugadorEquipoId)..load(),
      child: const _JugadorPerfilView(),
    );
  }
}

class _JugadorPerfilView extends StatefulWidget {
  const _JugadorPerfilView();

  @override
  State<_JugadorPerfilView> createState() => _JugadorPerfilViewState();
}

class _JugadorPerfilViewState extends State<_JugadorPerfilView> {
  final _formKey   = GlobalKey<FormState>();
  final _cNombre   = TextEditingController();
  final _cApellido = TextEditingController();
  final _cTelefono = TextEditingController();
  bool   _inicializado = false;
  String _dialCode     = '+52';

  @override
  void dispose() {
    _cNombre.dispose();
    _cApellido.dispose();
    _cTelefono.dispose();
    super.dispose();
  }

  void _inicializar(JugadorPerfilDto? data) {
    if (_inicializado || data == null) return;
    _inicializado = true;
    _cNombre.text   = data.fNombre;
    _cApellido.text = data.fApellido;
    _parseTelefono(data.fTelefono);
  }

  void _parseTelefono(String? tel) {
    if (tel == null || tel.isEmpty) return;
    final sorted = [..._paises]..sort((a, b) => b.$1.length.compareTo(a.$1.length));
    for (final e in sorted) {
      if (tel.startsWith(e.$1)) {
        _dialCode = e.$1;
        _cTelefono.text = tel.substring(e.$1.length);
        return;
      }
    }
    _cTelefono.text = tel;
  }

  Future<void> _seleccionarPais(BuildContext ctx) async {
    final code = await showModalBottomSheet<String>(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetCtx) => SizedBox(
        height: 420,
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(alignment: Alignment.centerLeft,
                child: Text('Código de país', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint))),
          ),
          Expanded(child: ListView.builder(
            itemCount: _paises.length,
            itemBuilder: (_, i) {
              final (c, f, n) = _paises[i];
              return ListTile(
                leading: Text(f, style: const TextStyle(fontSize: 22)),
                title: Text(n, style: const TextStyle(fontSize: 14)),
                trailing: Text(c, style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
                selected: _dialCode == c,
                onTap: () => Navigator.pop(sheetCtx, c),
              );
            },
          )),
        ]),
      ),
    );
    if (code != null && mounted) setState(() => _dialCode = code);
  }

  void _toast(BuildContext ctx, String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(ctx)
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

  Future<void> _guardar(BuildContext ctx) async {
    if (!_formKey.currentState!.validate()) return;
    final p   = ctx.read<JugadorPerfilProvider>();
    final err = await p.guardar(
      nombre:   _cNombre.text.trim(),
      apellido: _cApellido.text.trim(),
      telefono: _cTelefono.text.trim().isEmpty ? null : '$_dialCode${_cTelefono.text.trim()}',
    );
    if (!ctx.mounted) return;
    if (err == null) {
      _toast(ctx, 'Datos actualizados correctamente');
    } else {
      _toast(ctx, err, error: true);
    }
  }

  Future<void> _cambiarFoto(BuildContext ctx) async {
    final xfile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xfile == null || !ctx.mounted) return;

    final p   = ctx.read<JugadorPerfilProvider>();
    final err = await p.subirFoto(File(xfile.path));
    if (!ctx.mounted) return;
    if (err != null) { _toast(ctx, err, error: true); return; }
    final urlAbs = Env.toAbsolutePhotoUrl(p.fotoUrl);
    if (urlAbs != null) await CachedNetworkImage.evictFromCache(urlAbs);
    if (ctx.mounted) _toast(ctx, 'Foto actualizada correctamente');
  }

  String _initials(String nombre) {
    final parts = nombre.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final accent = RolePalettes.accentForRol('Jugador');
    final p      = context.watch<JugadorPerfilProvider>();

    _inicializar(p.data);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: p.loading && p.data == null
          ? Center(child: CircularProgressIndicator(color: accent))
          : p.error != null && p.data == null
              ? _ErrorView(mensaje: p.error!, onRetry: () => p.load())
              : _buildForm(context, p, accent),
    );
  }

  Widget _buildForm(BuildContext ctx, JugadorPerfilProvider p, Color accent) {
    final fotoUrl = Env.toAbsolutePhotoUrl(p.fotoUrl);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Stack(children: [
              GestureDetector(
                onTap: p.guardando ? null : () => _cambiarFoto(ctx),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.22),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: fotoUrl != null
                        ? ClipOval(child: CachedNetworkImage(
                            imageUrl: fotoUrl, width: 88, height: 88, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _initialsWidget(p, accent),
                          ))
                        : _initialsWidget(p, accent),
                  ),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: p.guardando ? null : () => _cambiarFoto(ctx),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                    child: p.guardando
                        ? const Padding(padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 28),

          _Campo(label: 'Nombre *', child: TextFormField(
            controller: _cNombre,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDeco('ej. Juan', accent),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Requerido' : null,
          )),
          const SizedBox(height: 14),

          _Campo(label: 'Apellido *', child: TextFormField(
            controller: _cApellido,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDeco('ej. Pérez', accent),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Requerido' : null,
          )),
          const SizedBox(height: 14),

          _Campo(
            label: 'Teléfono',
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                InkWell(
                  onTap: () => _seleccionarPais(ctx),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_paises.firstWhere((e) => e.$1 == _dialCode, orElse: () => _paises[0]).$2,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(_dialCode, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textHint),
                    ]),
                  ),
                ),
                Container(width: 1, height: 24, color: AppColors.border),
                Expanded(child: TextFormField(
                  controller: _cTelefono,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  decoration: const InputDecoration(
                    hintText: '10 dígitos',
                    hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                )),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          _Campo(
            label: 'Email',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(p.data?.email ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textHint)),
            ),
          ),
          const SizedBox(height: 14),
          BiometriaSwitch(accent: accent),
          const SizedBox(height: 32),

          PitazoButton(
            label: 'Guardar cambios',
            onPressed: p.guardando ? null : () => _guardar(ctx),
            loading: p.guardando,
            color: accent,
          ),

          // ── Ficha técnica (solo lectura) ──────────────────────────────────
          if (p.fichaCargada && p.ficha != null) ...[
            const SizedBox(height: 32),
            _FichaTecnicaCard(ficha: p.ficha!, avanzadasActivas: p.estadisticasAvanzadasActivas, accent: accent),
          ],
        ]),
      ),
    );
  }

  Widget _initialsWidget(JugadorPerfilProvider p, Color accent) => Text(
        _initials(p.data?.nombreCompleto ?? '?'),
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: accent),
      );

  InputDecoration _inputDeco(String hint, Color accent) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accent, width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red)),
      );
}

// ── Ficha técnica ─────────────────────────────────────────────────────────────

class _FichaTecnicaCard extends StatelessWidget {
  final FichaTecnicaDto ficha;
  final bool  avanzadasActivas;
  final Color accent;
  const _FichaTecnicaCard({required this.ficha, required this.avanzadasActivas, required this.accent});

  @override
  Widget build(BuildContext context) {
    final f = ficha;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🎮 Mi Ficha Técnica', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(children: [
            Text('${f.overall}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
            const Text('OVR', style: TextStyle(fontSize: 11, color: Colors.white, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(f.nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
            Text('${f.posicionLabel}${f.dorsal != null ? ' · #${f.dorsal}' : ''}',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
        ),
        if (avanzadasActivas) ...[
          const SizedBox(height: 16),
          ...[
            ('Ritmo', '⚡', f.ritmo), ('Tiro', '🎯', f.tiro), ('Pase', '🎁', f.pase),
            ('Regate', '🌀', f.regate), ('Defensa', '🛡️', f.defensa), ('Físico', '💪', f.fisico),
          ].map((a) => _AtributoBar(label: a.$1, icon: a.$2, valor: a.$3)),
        ],
      ]),
    );
  }
}

class _AtributoBar extends StatelessWidget {
  final String label;
  final String icon;
  final int    valor;
  const _AtributoBar({required this.label, required this.icon, required this.valor});

  @override
  Widget build(BuildContext context) {
    final color = valor >= 80 ? const Color(0xFF16A34A)
        : valor >= 60 ? const Color(0xFF65A30D)
        : valor >= 40 ? const Color(0xFFD97706)
        : const Color(0xFFDC2626);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('$icon $label', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          const Spacer(),
          Text('$valor', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: valor / 100, minHeight: 6,
            backgroundColor: AppColors.border, color: color,
          ),
        ),
      ]),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Campo extends StatelessWidget {
  final String label;
  final Widget child;
  const _Campo({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          child,
        ],
      );
}

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorView({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 32, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ]),
        ),
      );
}
