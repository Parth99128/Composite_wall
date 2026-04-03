import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class WallSchematicWidget extends StatelessWidget {
  final List<WallMaterial> materials;
  final BoundaryConditions bc;
  final CalculationResult? result;

  const WallSchematicWidget({
    super.key,
    required this.materials,
    required this.bc,
    this.result,
  });

  @override
  Widget build(BuildContext context) {
    final totalMm = materials.fold(0.0, (s, m) => s + m.thickness);

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Hot side label
          _TempLabel(
            temp: bc.tHot,
            label: 'Ts',
            color: AppColors.hot,
            isHot: true,
          ),

          // Wall layers
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: materials.map((mat) {
                  final flex = ((mat.thickness / totalMm) * 100).round().clamp(1, 99);
                  return Expanded(
                    flex: flex,
                    child: _LayerBlock(material: mat, result: result),
                  );
                }).toList(),
              ),
            ),
          ),

          // Cold side + convection
          _TempLabel(
            temp: bc.tAmbient,
            label: 'T∞',
            color: AppColors.cold,
            isHot: false,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
    );
  }
}

class _LayerBlock extends StatelessWidget {
  final WallMaterial material;
  final CalculationResult? result;

  const _LayerBlock({required this.material, this.result});

  @override
  Widget build(BuildContext context) {
    // Find temperature at this layer from result
    LayerResult? lr;
    if (result != null) {
      try {
        lr = result!.layerAnalysis.firstWhere((l) => l.name == material.name);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: material.color.withOpacity(0.15),
        border: Border(
          right: BorderSide(color: material.color.withOpacity(0.4), width: 1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            material.name.replaceAll('Material ', 'M'),
            style: GoogleFonts.jetBrainsMono(
              color: material.color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '${material.thickness}mm',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 8,
            ),
            textAlign: TextAlign.center,
          ),
          if (lr != null) ...[
            const SizedBox(height: 2),
            Text(
              'ΔT ${lr.dT.toStringAsFixed(1)}°',
              style: GoogleFonts.jetBrainsMono(
                color: material.color.withOpacity(0.8),
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _TempLabel extends StatelessWidget {
  final double temp;
  final String label;
  final Color color;
  final bool isHot;

  const _TempLabel({
    required this.temp,
    required this.label,
    required this.color,
    required this.isHot,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(isHot ? '🔥' : '❄️', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            '$label',
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 9,
            ),
          ),
          Text(
            '${temp.toStringAsFixed(0)}°C',
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Temperature gradient visualization (color strip)
class ThermalGradientStrip extends StatelessWidget {
  final List<LayerResult> layers;
  final double tHot;
  final double tCold;

  const ThermalGradientStrip({
    super.key,
    required this.layers,
    required this.tHot,
    required this.tCold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF4500),
            Color(0xFFFF8C42),
            Color(0xFFFFD700),
            Color(0xFF4FC3F7),
            Color(0xFF00BFFF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4500).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${tHot.toStringAsFixed(0)}°C',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${tCold.toStringAsFixed(0)}°C',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
