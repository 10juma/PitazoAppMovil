import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/biometria_switch.dart';
import '../data/arbitro_repository.dart';
import '../providers/arbitro_provider.dart';

class ArbitroPerfilScreen extends StatefulWidget {
  const ArbitroPerfilScreen({super.key});

  @override
  State<ArbitroPerfilScreen> createState() => _ArbitroPerfilScreenState();
}

class _ArbitroPerfilScreenState extends State<ArbitroPerfilScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final p       = context.read<ArbitroProvider>();
      final auth    = context.read<AuthProvider>();
      final fotoUrl = p.perfil?.fotoUrl;
      final urlAbs  = Env.toAbsolutePhotoUrl(fotoUrl);
      if (urlAbs != null) await CachedNetworkImage.evictFromCache(urlAbs);
      if (!mounted) return;
      await auth.updateFoto(fotoUrl);
      if (mounted) setState(() {});
    });
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

  Future<void> _cambiarFoto(BuildContext ctx) async {
    final xfile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xfile == null || !ctx.mounted) return;

    final p    = ctx.read<ArbitroProvider>();
    final auth = ctx.read<AuthProvider>();
    final err  = await p.subirFoto(File(xfile.path));
    if (!ctx.mounted) return;
    if (err != null) { _toast(err, error: true); return; }
    final urlAbs = Env.toAbsolutePhotoUrl(p.perfil?.fotoUrl);
    if (urlAbs != null) await CachedNetworkImage.evictFromCache(urlAbs);
    if (!ctx.mounted) return;
    await auth.updateFoto(p.perfil?.fotoUrl);
    if (ctx.mounted) _toast('Foto actualizada correctamente');
  }

  String _iniciales(String nombre) {
    final parts = nombre.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final accent = RolePalettes.accentForRol('Arbitro');
    final p      = context.watch<ArbitroProvider>();
    final perfil = p.perfil;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: p.loading && perfil == null
          ? Center(child: CircularProgressIndicator(color: accent))
          : perfil == null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_outlined, size: 32, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    const Text('Error al cargar perfil',
                        style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                    const SizedBox(height: 16),
                    TextButton(onPressed: () => p.load(), child: const Text('Reintentar')),
                  ]),
                )
              : _buildBody(context, p, perfil, accent),
    );
  }

  Widget _buildBody(BuildContext ctx, ArbitroProvider p, ArbitroPerfilDto perfil, Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Avatar
        Center(
          child: Stack(children: [
            GestureDetector(
              onTap: p.subiendo ? null : () => _cambiarFoto(ctx),
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
                  child: Env.toAbsolutePhotoUrl(perfil.fotoUrl) != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: Env.toAbsolutePhotoUrl(perfil.fotoUrl)!,
                            width: 88, height: 88,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _inicialesWidget(perfil, accent),
                          ),
                        )
                      : _inicialesWidget(perfil, accent),
                ),
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: p.subiendo ? null : () => _cambiarFoto(ctx),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: accent, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: p.subiendo
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(perfil.nombreCompleto,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent)),
        ),
        const SizedBox(height: 24),

        // Stats
        Row(children: [
          _StatChip(valor: '${perfil.totalPartidos}',     label: 'Partidos',   accent: accent),
          const SizedBox(width: 8),
          _StatChip(valor: '${perfil.partidosEsteAnio}',  label: 'Este año',   accent: accent),
          const SizedBox(width: 8),
          if (perfil.totalCalificaciones > 0)
            _StatChip(
              valor: '${perfil.calificacionPromedio.toStringAsFixed(1)}★',
              label: 'Promedio',
              accent: const Color(0xFFF59E0B),
            )
          else
            _StatChip(valor: '—', label: 'Sin eval.', accent: AppColors.textHint),
        ]),
        const SizedBox(height: 24),

        // Datos personales (solo lectura)
        _SectionTitle('Datos personales'),
        const SizedBox(height: 12),
        _Campo(label: 'Email',    value: perfil.email),
        const SizedBox(height: 12),
        _Campo(label: 'Teléfono', value: perfil.telefono ?? '—'),
        const SizedBox(height: 24),

        // Datos profesionales
        _SectionTitle('Datos profesionales'),
        const SizedBox(height: 12),
        _Campo(label: 'Licencia', value: perfil.licencia ?? '—'),
        const SizedBox(height: 12),
        _Campo(
          label: 'Tarifa por partido',
          value: perfil.tarifaPorPartido != null
              ? '\$${perfil.tarifaPorPartido!.toStringAsFixed(0)} MXN'
              : '—',
        ),

        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Los datos personales y profesionales son administrados por tu organización.',
            style: TextStyle(fontSize: 11, color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        BiometriaSwitch(accent: accent),
      ]),
    );
  }

  Widget _inicialesWidget(ArbitroPerfilDto perfil, Color accent) => Text(
        _iniciales(perfil.nombreCompleto),
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: accent),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String valor;
  final String label;
  final Color  accent;
  const _StatChip({required this.valor, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(children: [
            Text(valor,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent, height: 1.1)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ]),
        ),
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
  final String  label;
  final String  value;
  const _Campo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColors.textHint, letterSpacing: 0.4)),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          ),
        ],
      );
}
