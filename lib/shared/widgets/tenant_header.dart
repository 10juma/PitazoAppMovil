import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class TenantHeader extends StatelessWidget {
  final String? logoUrl;
  final String nombre;
  final Color accentColor;

  const TenantHeader({
    super.key,
    this.logoUrl,
    required this.nombre,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildLogo(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            nombre,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: logoUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.sports_soccer, color: Colors.white, size: 20),
    );
  }
}
