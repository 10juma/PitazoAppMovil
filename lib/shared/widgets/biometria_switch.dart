import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/biometric_service.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Switch para activar/desactivar Face ID/huella desde "Mi perfil", sin
/// depender de que el usuario haya aceptado el diálogo justo al loguearse.
/// Se oculta por completo si el dispositivo no tiene biometría disponible.
class BiometriaSwitch extends StatefulWidget {
  final Color accent;
  const BiometriaSwitch({super.key, required this.accent});

  @override
  State<BiometriaSwitch> createState() => _BiometriaSwitchState();
}

class _BiometriaSwitchState extends State<BiometriaSwitch> {
  bool? _disponible;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    BiometricService.disponible().then((v) {
      if (mounted) setState(() => _disponible = v);
    });
  }

  Future<void> _onChanged(bool activar) async {
    final auth = context.read<AuthProvider>();
    setState(() => _procesando = true);
    if (activar) {
      final ok = await BiometricService.autenticar(
        razon: 'Confirma tu identidad para activar Face ID / huella',
      );
      if (ok) {
        await auth.activarBiometria();
      } else if (mounted) {
        final detalle = BiometricService.ultimoError;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(detalle == null
              ? 'No se pudo confirmar tu identidad. Intenta de nuevo.'
              : 'No se pudo activar Face ID / huella: $detalle'),
        ));
      }
    } else {
      await auth.desactivarBiometria();
    }
    if (mounted) setState(() => _procesando = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_disponible != true) return const SizedBox.shrink();
    final activa = context.watch<AuthProvider>().biometriaActiva;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Face ID / huella', style: TextStyle(fontSize: 14)),
        subtitle: const Text('Entrar sin escribir tu contraseña en este dispositivo',
            style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        value: activa,
        activeThumbColor: widget.accent,
        onChanged: _procesando ? null : _onChanged,
      ),
    );
  }
}
