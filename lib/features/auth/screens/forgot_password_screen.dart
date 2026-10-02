import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/pitazo_button.dart';
import '../../../shared/widgets/pitazo_text_field.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _repo = AuthRepository();

  final _emailCtrl    = TextEditingController();
  final _codigoCtrl   = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  String? _verificacionId;
  bool _obscurePassword = true;
  bool _loading = false;
  bool _reenviando = false;
  String? _error;
  String? _mensaje;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codigoCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _solicitarCodigo() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa tu correo.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final id = await _repo.olvidePassword(_emailCtrl.text.trim());
      if (!mounted) return;
      if (id == null) {
        setState(() => _mensaje = 'Si el correo existe, te enviamos un código de verificación.');
      } else {
        setState(() => _verificacionId = id);
      }
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'No pudimos procesar tu solicitud.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reenviarCodigo() async {
    if (_verificacionId == null) return;
    setState(() { _reenviando = true; _error = null; });
    try {
      await _repo.reenviarCodigoRecuperacion(_verificacionId!);
      if (mounted) setState(() => _mensaje = 'Te enviamos un código nuevo.');
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'No pudimos reenviar el código.');
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  Future<void> _restablecer() async {
    if (_codigoCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Completa el código y tu nueva contraseña.');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (_passwordCtrl.text != _confirmarCtrl.text) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _repo.restablecerPassword(_verificacionId!, _codigoCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, size: 36, color: AppColors.primary),
          title: const Text('Contraseña actualizada'),
          content: const Text('Ya puedes iniciar sesión con tu nueva contraseña.'),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
          ],
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'No pudimos restablecer tu contraseña.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _verificacionId == null ? _buildPasoEmail() : _buildPasoCodigo(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPasoEmail() {
    return [
      const Text('¿Olvidaste tu contraseña?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      const Text('Ingresa tu correo y te enviaremos un código para restablecerla.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 24),
      PitazoTextField(
        controller: _emailCtrl,
        label: 'Correo electrónico',
        hint: 'tu@correo.com',
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _solicitarCodigo(),
        prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textHint, size: 20),
      ),
      ..._buildAvisos(),
      const SizedBox(height: 26),
      PitazoButton(
        label: 'Enviar código',
        onPressed: _loading ? null : _solicitarCodigo,
        loading: _loading,
        trailingIcon: Icons.arrow_forward_rounded,
      ),
    ];
  }

  List<Widget> _buildPasoCodigo() {
    return [
      const Text('Revisa tu correo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text('Te enviamos un código de verificación a ${_emailCtrl.text.trim()}.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 24),
      PitazoTextField(
        controller: _codigoCtrl,
        label: 'Código de verificación',
        hint: '123456',
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.textHint, size: 20),
      ),
      const SizedBox(height: 16),
      PitazoTextField(
        controller: _passwordCtrl,
        label: 'Nueva contraseña',
        hint: '••••••••',
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.next,
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textHint, size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      const SizedBox(height: 16),
      PitazoTextField(
        controller: _confirmarCtrl,
        label: 'Confirmar contraseña',
        hint: '••••••••',
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _restablecer(),
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint, size: 20),
      ),
      ..._buildAvisos(),
      const SizedBox(height: 26),
      PitazoButton(
        label: 'Restablecer contraseña',
        onPressed: _loading ? null : _restablecer,
        loading: _loading,
        trailingIcon: Icons.check_rounded,
      ),
      const SizedBox(height: 12),
      Center(
        child: TextButton(
          onPressed: _reenviando ? null : _reenviarCodigo,
          child: Text(_reenviando ? 'Enviando...' : '¿No te llegó? Reenviar código',
              style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
        ),
      ),
    ];
  }

  List<Widget> _buildAvisos() {
    return [
      if (_error != null) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
            ],
          ),
        ),
      ],
      if (_mensaje != null) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_mensaje!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
            ],
          ),
        ),
      ],
    ];
  }
}
