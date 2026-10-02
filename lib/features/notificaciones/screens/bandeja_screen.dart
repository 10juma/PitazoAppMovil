import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/notificaciones_provider.dart';

class BandejaScreen extends StatefulWidget {
  const BandejaScreen({super.key});

  @override
  State<BandejaScreen> createState() => _BandejaScreenState();
}

class _BandejaScreenState extends State<BandejaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificacionesProvider>().cargar());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificacionesProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notificaciones')),
      body: RefreshIndicator(
        onRefresh: () => prov.cargar(),
        child: prov.loading && prov.notificaciones.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : prov.notificaciones.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 120),
                    Center(
                      child: Column(children: [
                        Icon(Icons.notifications_none, size: 40, color: AppColors.textHint),
                        SizedBox(height: 10),
                        Text('No tienes notificaciones', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                      ]),
                    ),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: prov.notificaciones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final n = prov.notificaciones[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => prov.marcarLeida(n.id),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: n.leida ? AppColors.surface : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border, width: 0.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!n.leida)
                                const Padding(
                                  padding: EdgeInsets.only(top: 5, right: 10),
                                  child: CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
                                )
                              else
                                const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.titulo,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: n.leida ? FontWeight.w600 : FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        )),
                                    const SizedBox(height: 4),
                                    Text(n.cuerpo,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                    const SizedBox(height: 6),
                                    Text(_fecha(n.creadaEn),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  static String _dos(int n) => n.toString().padLeft(2, '0');

  String _fecha(DateTime d) {
    final local = d.toLocal();
    return '${_dos(local.day)}/${_dos(local.month)}/${local.year} ${_dos(local.hour)}:${_dos(local.minute)}';
  }
}
