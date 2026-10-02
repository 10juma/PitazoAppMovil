import 'package:flutter/material.dart';
import 'app_colors.dart';

class RolePalettes {
  static const Map<String, Color> _accents = {
    'Admin':       Color(0xFF1F4E79),
    'Staff':       Color(0xFF065F46),
    'Arbitro':     Color(0xFF92400E),
    'Manager':     Color(0xFF735889),
    'Jugador':     Color(0xFF9A3412),
    'Patrocinador':Color(0xFFA16207),
  };

  static Color accentForRol(String? rol) =>
      _accents[rol] ?? AppColors.primary;

  static Color lightForRol(String? rol) {
    final base = accentForRol(rol);
    return Color.lerp(base, Colors.white, 0.3) ?? base;
  }
}
