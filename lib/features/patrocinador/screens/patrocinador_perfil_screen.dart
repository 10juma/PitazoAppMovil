import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../shared/widgets/pitazo_button.dart';
import '../providers/patrocinador_provider.dart';

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

class PatrocinadorPerfilScreen extends StatefulWidget {
  const PatrocinadorPerfilScreen({super.key});

  @override
  State<PatrocinadorPerfilScreen> createState() => _PatrocinadorPerfilScreenState();
}

class _PatrocinadorPerfilScreenState extends State<PatrocinadorPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cSitioWeb = TextEditingController();
  final _cContactoNombre = TextEditingController();
  final _cContactoTelefono = TextEditingController();

  bool _inicializado = false;
  bool _guardando = false;
  String _dialCode = '+52';

  @override
  void dispose() {
    _cSitioWeb.dispose();
    _cContactoNombre.dispose();
    _cContactoTelefono.dispose();
    super.dispose();
  }

  void _inicializar(PatrocinadorProvider p) {
    if (_inicializado || p.perfil == null) return;
    _inicializado = true;
    _cSitioWeb.text = p.perfil!.sitioWeb ?? '';
    _cContactoNombre.text = p.perfil!.contactoNombre ?? '';
    _parseTelefono(p.perfil!.contactoTelefono);
  }

  void _parseTelefono(String? tel) {
    if (tel == null || tel.isEmpty) return;
    final sorted = [..._paises]..sort((a, b) => b.$1.length.compareTo(a.$1.length));
    for (final e in sorted) {
      if (tel.startsWith(e.$1)) {
        _dialCode = e.$1;
        _cContactoTelefono.text = tel.substring(e.$1.length);
        return;
      }
    }
    _cContactoTelefono.text = tel;
  }

  Future<void> _seleccionarPais(BuildContext ctx) async {
    final code = await showModalBottomSheet<String>(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SizedBox(
        height: 420,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Código de país', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHint)),
              ),
            ),
            Expanded(
              child: ListView.builder(
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
              ),
            ),
          ],
        ),
      ),
    );
    if (code != null && mounted) setState(() => _dialCode = code);
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

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final p = context.read<PatrocinadorProvider>();
    final err = await p.actualizarPerfil(
      logoUrl: p.perfil?.logoUrl,
      sitioWeb: _cSitioWeb.text.trim().isEmpty ? null : _cSitioWeb.text.trim(),
      contactoNombre: _cContactoNombre.text.trim().isEmpty ? null : _cContactoNombre.text.trim(),
      contactoTelefono: _cContactoTelefono.text.trim().isEmpty
          ? null
          : '$_dialCode${_cContactoTelefono.text.trim()}',
      contactoEmail: p.perfil?.contactoEmail,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (err == null) {
      _toast('Datos actualizados correctamente');
    } else {
      _toast(err, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = RolePalettes.accentForRol('Patrocinador');
    final p = context.watch<PatrocinadorProvider>();
    _inicializar(p);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi cuenta'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: p.loading && p.perfil == null
          ? Center(child: CircularProgressIndicator(color: accent))
          : p.perfil == null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_outlined, size: 32, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    const Text('Error al cargar tu cuenta', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                    const SizedBox(height: 16),
                    TextButton(onPressed: () => p.load(), child: const Text('Reintentar')),
                  ]),
                )
              : _buildForm(context, p, accent),
    );
  }

  Widget _buildForm(BuildContext ctx, PatrocinadorProvider p, Color accent) {
    final perfil = p.perfil!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle('Datos de la organización'),
            const SizedBox(height: 12),
            _Campo(label: 'Nombre', child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(perfil.nombre, style: const TextStyle(fontSize: 14, color: AppColors.textHint)),
            )),
            const SizedBox(height: 14),
            _Campo(label: 'Sitio web', child: TextFormField(
              controller: _cSitioWeb,
              keyboardType: TextInputType.url,
              decoration: _inputDeco('https://tunegocio.com'),
            )),
            const SizedBox(height: 14),
            _Campo(label: 'Nombre de contacto', child: TextFormField(
              controller: _cContactoNombre,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDeco('ej. Juan Pérez'),
            )),
            const SizedBox(height: 14),
            _Campo(
              label: 'Teléfono de contacto',
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _seleccionarPais(ctx),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _paises.firstWhere((e) => e.$1 == _dialCode, orElse: () => _paises[0]).$2,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 4),
                            Text(_dialCode, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                            const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textHint),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 24, color: AppColors.border),
                    Expanded(
                      child: TextFormField(
                        controller: _cContactoTelefono,
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Campo(label: 'Email de contacto', child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(perfil.contactoEmail ?? '—', style: const TextStyle(fontSize: 14, color: AppColors.textHint)),
            )),
            const SizedBox(height: 24),
            PitazoButton(
              label: 'Guardar cambios',
              onPressed: _guardando ? null : _guardar,
              loading: _guardando,
              color: accent,
            ),

            const SizedBox(height: 32),
            _SectionTitle('Dónde se muestra tu publicidad'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'Tu logo aparece en la página pública de la liga, equipos, jugadores, partidos y el marcador en vivo.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                _LinkRow(
                  label: 'Ver página pública',
                  onTap: () => launchUrl(Uri.parse('${Env.webUrl}/c/${perfil.tenantSlug}'),
                      mode: LaunchMode.externalApplication),
                ),
                const SizedBox(height: 6),
                _LinkRow(
                  label: 'Ver partidos en vivo',
                  onTap: () => launchUrl(Uri.parse('${Env.webUrl}/c/${perfil.tenantSlug}/envivo'),
                      mode: LaunchMode.externalApplication),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: RolePalettes.accentForRol('Patrocinador'))),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: AppColors.textHint, letterSpacing: 0.5),
      );
}

class _Campo extends StatelessWidget {
  final String label;
  final Widget child;
  const _Campo({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.textHint, letterSpacing: 0.4)),
          const SizedBox(height: 5),
          child,
        ],
      );
}

class _LinkRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LinkRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Row(children: [
          Icon(Icons.open_in_new, size: 14, color: RolePalettes.accentForRol('Patrocinador')),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RolePalettes.accentForRol('Patrocinador'))),
        ]),
      );
}
