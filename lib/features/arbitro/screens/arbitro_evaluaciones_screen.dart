import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/role_palettes.dart';
import '../data/arbitro_repository.dart';

class ArbitroEvaluacionesScreen extends StatefulWidget {
  const ArbitroEvaluacionesScreen({super.key});

  @override
  State<ArbitroEvaluacionesScreen> createState() => _ArbitroEvaluacionesScreenState();
}

class _ArbitroEvaluacionesScreenState extends State<ArbitroEvaluacionesScreen> {
  final _repo = ArbitroRepository();

  ResumenEvaluacionesDto       _resumen  = ResumenEvaluacionesDto.vacio;
  List<EvaluacionHistorialDto> _historial = [];
  bool                         _cargando  = false;
  String?                      _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() { _cargando = true; _error = null; });
    try {
      final resumenFut   = _repo.obtenerResumen();
      final historialFut = _repo.listarEvaluaciones();
      final r = await resumenFut;
      final h = await historialFut;
      if (!mounted) return;
      setState(() { _resumen = r; _historial = h; _cargando = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Error al cargar evaluaciones.'; _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = RolePalettes.accentForRol('Arbitro');

    if (_cargando && _historial.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2));
    }

    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 28, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
          const SizedBox(height: 12),
          TextButton(onPressed: _cargar, child: const Text('Reintentar')),
        ]),
      );
    }

    return RefreshIndicator(
      color: accent,
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 104),
        children: [
          // Resumen
          if (_resumen.total > 0) ...[
            _ResumenCard(resumen: _resumen, accent: accent),
            const SizedBox(height: 16),
          ] else ...[
            _EmptyCard(accent: accent),
            const SizedBox(height: 16),
          ],

          // Historial
          if (_historial.isNotEmpty) ...[
            const Text('Historial',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ..._historial.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _EvaluacionCard(eval: e, accent: accent),
                )),
          ],
        ],
      ),
    );
  }
}

// ── Resumen card ──────────────────────────────────────────────────────────────

class _ResumenCard extends StatelessWidget {
  final ResumenEvaluacionesDto resumen;
  final Color                  accent;
  const _ResumenCard({required this.resumen, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Promedio general
        Row(children: [
          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
          const SizedBox(width: 6),
          Text(resumen.promedioGeneral.toStringAsFixed(1),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(width: 6),
          Text('/ 5  · ${resumen.total} evaluación${resumen.total != 1 ? 'es' : ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        ]),
        const SizedBox(height: 14),

        // Desglose criterios
        ...([
          ('⏰ Puntualidad',   resumen.promPuntualidad),
          ('📖 Conocimiento',  resumen.promConocimiento),
          ('🤝 Trato',         resumen.promTrato),
          ('⚖️ Imparcialidad', resumen.promImparcialidad),
        ].map((item) {
          final (lbl, val) = item;
          final pct        = val / 5.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(lbl, style: const TextStyle(fontSize: 12, color: AppColors.textHint))),
                Text(val.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                ),
              ),
            ]),
          );
        })),
      ]),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final Color accent;
  const _EmptyCard({required this.accent});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: const Column(children: [
          Icon(Icons.star_outline, size: 36, color: AppColors.textHint),
          SizedBox(height: 10),
          Text('Sin evaluaciones aún',
              style: TextStyle(fontSize: 13, color: AppColors.textHint)),
          SizedBox(height: 4),
          Text('Los managers y staff pueden evaluar\ntu desempeño al terminar un partido.',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
              textAlign: TextAlign.center),
        ]),
      );
}

// ── Evaluación individual ─────────────────────────────────────────────────────

class _EvaluacionCard extends StatelessWidget {
  final EvaluacionHistorialDto eval;
  final Color                  accent;
  const _EvaluacionCard({required this.eval, required this.accent});

  @override
  Widget build(BuildContext context) {
    final meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    final fecha = eval.creadoEn;
    final fechaStr = '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (eval.partidoLabel != null)
                Text(eval.partidoLabel!,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${eval.evaluadoPorNombre} · ${eval.tipoEvaluadorLabel} · $fechaStr',
                  style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
            ]),
          ),
          const SizedBox(width: 8),
          Row(children: [
            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
            const SizedBox(width: 3),
            Text(eval.promedio.toStringAsFixed(1),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ]),
        ]),

        // Criterios inline
        const SizedBox(height: 10),
        Row(children: [
          _Criterio('Punt.', eval.puntualidad),
          _Criterio('Conoc.', eval.conocimiento),
          _Criterio('Trato', eval.trato),
          _Criterio('Imparc.', eval.imparcialidad),
        ]),

        // Comentario
        if (eval.comentario != null && eval.comentario!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Text('"${eval.comentario}"',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint,
                    fontStyle: FontStyle.italic)),
          ),
        ],
      ]),
    );
  }
}

class _Criterio extends StatelessWidget {
  final String label;
  final int    valor;
  const _Criterio(this.label, this.valor);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text('$valor',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text(label,
              style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
        ]),
      );
}
