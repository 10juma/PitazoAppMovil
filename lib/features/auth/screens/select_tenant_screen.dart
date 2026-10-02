import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/auth/tenant_opcion_dto.dart';
import '../providers/auth_provider.dart';

class SelectTenantScreen extends StatefulWidget {
  const SelectTenantScreen({super.key});

  @override
  State<SelectTenantScreen> createState() => _SelectTenantScreenState();
}

class _SelectTenantScreenState extends State<SelectTenantScreen> {
  String? _loadingTenantId;
  String? _error;

  Future<void> _seleccionar(TenantOpcionDto tenant) async {
    setState(() { _loadingTenantId = tenant.tenantId; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      await auth.seleccionarTenant(tenant.usuarioId, tenant.tenantId);
      if (!mounted) return;
      await _ofrecerBiometria(auth);
      auth.confirmarLogin();
    } catch (e) {
      setState(() => _error = 'No se pudo seleccionar la liga. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _loadingTenantId = null);
    }
  }

  Future<void> _ofrecerBiometria(AuthProvider auth) async {
    if (auth.biometriaActiva) return;
    if (!await BiometricService.disponible()) return;
    if (!mounted) return;
    final activar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.fingerprint, size: 36, color: AppColors.primary),
        title: const Text('¿Usar Face ID / huella?'),
        content: const Text('Para no escribir tu contraseña cada vez que abras Pitazo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ahora no')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Activar')),
        ],
      ),
    );
    if (activar == true && mounted) await auth.activarBiometria();
  }

  @override
  Widget build(BuildContext context) {
    final tenants = context.watch<AuthProvider>().pendingTenants ?? [];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text(
          'Selecciona tu liga',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tu correo está registrado en ${tenants.length} liga${tenants.length != 1 ? 's' : ''}. ¿En cuál quieres entrar?',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: ListView.separated(
                  itemCount: tenants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _TenantCard(
                    tenant:   tenants[i],
                    loading:  _loadingTenantId == tenants[i].tenantId,
                    disabled: _loadingTenantId != null,
                    onTap:    () => _seleccionar(tenants[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  final TenantOpcionDto tenant;
  final bool loading;
  final bool disabled;
  final VoidCallback onTap;

  const _TenantCard({
    required this.tenant,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _logo(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.tenantNombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tenant.rol,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              else
                Icon(Icons.chevron_right_rounded,
                    color: disabled ? AppColors.textHint : AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    final url = tenant.tenantLogoUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(url, width: 48, height: 48, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultLogo()),
      );
    }
    return _defaultLogo();
  }

  Widget _defaultLogo() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F4E79), Color(0xFF3b82f6)],
          ),
        ),
        child: const Center(
          child: Text('⚽', style: TextStyle(fontSize: 22)),
        ),
      );
}
