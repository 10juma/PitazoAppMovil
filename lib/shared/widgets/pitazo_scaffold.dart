import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/role_palettes.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/jugador/providers/jugador_provider.dart';
import '../../features/notificaciones/providers/notificaciones_provider.dart';

class PitazoNavItem {
  final IconData icon;
  final String label;
  const PitazoNavItem({required this.icon, required this.label});
}

class PitazoScaffold extends StatefulWidget {
  final List<PitazoNavItem> primaryNav;
  final List<PitazoNavItem> extraNav;
  final Widget child;
  final void Function(int)? onTabChanged;
  final Widget? floatingActionButton;
  final VoidCallback? onAvatarTap;

  const PitazoScaffold({
    super.key,
    required this.primaryNav,
    this.extraNav = const [],
    required this.child,
    this.onTabChanged,
    this.floatingActionButton,
    this.onAvatarTap,
  });

  @override
  State<PitazoScaffold> createState() => _PitazoScaffoldState();
}

class _PitazoScaffoldState extends State<PitazoScaffold> {
  int  _active   = 0;
  bool _expanded = false;

  String _initials(String? nombre) {
    final parts = (nombre ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _initialsWidget(String? nombre) => Container(
        color: Colors.white.withValues(alpha: 0.2),
        alignment: Alignment.center,
        child: Text(
          _initials(nombre),
          style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      );

  Future<void> _logout(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text(
          '👋  ¿Cerrar sesión?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Tu sesión activa en este dispositivo terminará. '
          'Podrás volver a ingresar cuando quieras.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Sí, salir'),
          ),
        ],
      ),
    );
    if (ok == true && ctx.mounted) {
      await ctx.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final token  = context.watch<AuthProvider>().token;
    final accent = RolePalettes.accentForRol(token?.rol);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context, token, accent),
              Expanded(child: widget.child),
            ],
          ),

          // Overlay que cierra el menú expandido
          if (_expanded)
            GestureDetector(
              onTap: () => setState(() => _expanded = false),
              child: Container(color: Colors.black26),
            ),

          // FAB encima del nav
          if (widget.floatingActionButton != null)
            Positioned(
              bottom: 82, right: 20,
              child: widget.floatingActionButton!,
            ),

          // Nav flotante
          Positioned(
            bottom: 14, left: 14, right: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: _expanded && widget.extraNav.isNotEmpty
                      ? _buildExtraNav(accent)
                      : const SizedBox.shrink(),
                ),
                if (_expanded && widget.extraNav.isNotEmpty)
                  const SizedBox(height: 6),
                _buildPrimaryNav(accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// La foto del Jugador vive en su equipo (JugadorEquipo.FotoUrl), no en Usuario.AvatarUrl
  /// (a diferencia de Manager/Admin/Staff), así que el token no la trae — se lee en vivo
  /// del equipo activo para reflejar cambios sin esperar a un nuevo login.
  String? _fotoHeader(BuildContext ctx, token) {
    if (token?.rol == 'Jugador') {
      return ctx.watch<JugadorProvider>().equipoActivo?.fotoUrl;
    }
    return token?.fotoPerfilUrl;
  }

  Widget _buildHeader(BuildContext ctx, token, Color accent) {
    final fotoUrl = Env.toAbsolutePhotoUrl(_fotoHeader(ctx, token));
    final accentLight = HSLColor.fromColor(accent)
        .withLightness((HSLColor.fromColor(accent).lightness + 0.10).clamp(0.0, 1.0))
        .toColor();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent, accentLight],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Row(
            children: [
              // Avatar (foto si existe, iniciales si no)
              GestureDetector(
                onTap: widget.onAvatarTap,
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: fotoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: fotoUrl,
                            width: 42, height: 42,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _initialsWidget(token?.nombre),
                          )
                        : _initialsWidget(token?.nombre),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Nombre + tenant + badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      token?.nombre ?? '',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      token?.tenantNombre ?? '',
                      style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        token?.rol ?? '',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Botón notificaciones
              GestureDetector(
                onTap: () => ctx.push('/notificaciones'),
                child: Container(
                  width: 34, height: 34,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined, color: Colors.white, size: 17),
                      if (ctx.watch<NotificacionesProvider>().noLeidas > 0)
                        Positioned(
                          top: -2, right: -2,
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Botón logout
              GestureDetector(
                onTap: () => _logout(ctx),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.logout_outlined, color: Colors.white, size: 17),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtraNav(Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: widget.extraNav
            .map((item) => _NavChip(
                  icon: item.icon,
                  label: item.label,
                  active: false,
                  accent: accent,
                  onTap: () => setState(() => _expanded = false),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPrimaryNav(Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Row(
        children: [
          ...widget.primaryNav.asMap().entries.map((e) => Expanded(
                child: _NavChip(
                  icon: e.value.icon,
                  label: e.value.label,
                  active: _active == e.key && !_expanded,
                  accent: accent,
                  onTap: () {
                    setState(() { _active = e.key; _expanded = false; });
                    widget.onTabChanged?.call(e.key);
                  },
                ),
              )),
          if (widget.extraNav.isNotEmpty)
            Expanded(
              child: _NavChip(
                icon: _expanded ? Icons.close : Icons.add,
                label: 'Más',
                active: _expanded,
                accent: accent,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final bool      active;
  final Color     accent;
  final VoidCallback onTap;

  const _NavChip({
    required this.icon, required this.label,
    required this.active, required this.accent, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: active ? accent : AppColors.textHint),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: active ? accent : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
