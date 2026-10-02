import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/pitazo_button.dart';
import '../../../shared/widgets/pitazo_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword  = true;
  bool _loading          = false;
  bool _biometriaLoading = false;
  String? _error;
  bool _intentoAutomaticoHecho = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Ingresa tu correo y contraseña.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;

      // Usuario en múltiples ligas — mostrar selector antes de continuar.
      if (auth.pendingTenants != null) {
        context.push('/select-tenant');
        return;
      }

      await _ofrecerActivarBiometria(auth);
      // Recién ahora se notifica el cambio — así el router no navega fuera
      // de esta pantalla antes de que el diálogo de Face ID llegue a mostrarse.
      auth.confirmarLogin();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Tras un login exitoso con contraseña, si el dispositivo soporta
  /// biometría y el usuario aún no la activó, se le ofrece como atajo para
  /// la próxima vez — nunca se pregunta dos veces ni se exige.
  Future<void> _ofrecerActivarBiometria(AuthProvider auth) async {
    if (auth.biometriaActiva) return;
    if (!await BiometricService.disponible()) return;
    if (!mounted) return;
    final activar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.fingerprint, size: 36, color: AppColors.primary),
        title: const Text('¿Usar Face ID / huella?'),
        content: const Text('Para no escribir tu contraseña cada vez que abras Pitazo en este dispositivo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ahora no')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Activar')),
        ],
      ),
    );
    if (activar == true) await auth.activarBiometria();
  }

  Future<void> _desbloquearConBiometria() async {
    setState(() { _biometriaLoading = true; _error = null; });
    final ok = await context.read<AuthProvider>().desbloquearConBiometria();
    if (!mounted) return;
    setState(() {
      _biometriaLoading = false;
      if (!ok) _error = 'No se pudo verificar tu identidad. Intenta de nuevo o usa tu contraseña.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final requiereDesbloqueo = auth.requiereDesbloqueo;

    // Ofrece Face ID/huella de inmediato al volver a abrir la app con una
    // sesión guardada — el usuario siempre puede ignorarlo y usar su contraseña.
    if (requiereDesbloqueo && !_intentoAutomaticoHecho && !_biometriaLoading) {
      _intentoAutomaticoHecho = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _desbloquearConBiometria());
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.surface],
            stops: [0, 0.5],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: -80,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.10),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    _buildForm(requiereDesbloqueo, auth),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Image.asset('assets/images/logo.png'),
          ),
          const SizedBox(height: 22),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'PITA', style: TextStyle(color: AppColors.textPrimary)),
                TextSpan(text: 'ZO', style: TextStyle(color: AppColors.primary)),
              ],
            ),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Inicia sesión para continuar',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool requiereDesbloqueo, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PitazoTextField(
            controller: _emailCtrl,
            label: 'Correo electrónico',
            hint: 'tu@correo.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textHint, size: 20),
          ),
          const SizedBox(height: 16),
          PitazoTextField(
            controller: _passwordCtrl,
            label: 'Contraseña',
            hint: '••••••••',
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textHint,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: const Text('¿Olvidaste tu contraseña?',
                  style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 26),
          PitazoButton(
            label: 'Iniciar sesión',
            onPressed: _loading ? null : _login,
            loading: _loading,
            trailingIcon: Icons.arrow_forward_rounded,
          ),
          if (requiereDesbloqueo) ...[
            const SizedBox(height: 24),
            Row(
              children: const [
                Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                ),
                Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _biometriaLoading ? null : _desbloquearConBiometria,
                icon: _biometriaLoading
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Icon(Icons.fingerprint, size: 20, color: AppColors.primary),
                label: const Text(
                  'Usar Face ID / huella',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  backgroundColor: AppColors.surfaceAlt,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => auth.desactivarBiometria(),
                child: const Text('No volver a pedir Face ID / huella en este dispositivo',
                    style: TextStyle(fontSize: 11, color: AppColors.textHint)),
              ),
            ),
          ],
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
