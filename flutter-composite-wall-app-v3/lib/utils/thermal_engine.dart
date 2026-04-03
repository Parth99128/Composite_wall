import 'package:flutter/material.dart';
import '../models/models.dart';

class ThermalEngine {
  /// Core 1D steady-state heat transfer through composite wall
  static CalculationResult compute(
    List<WallMaterial> materials,
    BoundaryConditions bc, {
    bool isOffline = true,
  }) {
    final area = bc.area;

    // Compute resistances
    final layers = materials.map((mat) {
      final thicknessM = mat.thickness / 1000.0;
      final r = thicknessM / (mat.k * area);
      return _LayerIntermediate(mat: mat, thicknessM: thicknessM, rConduction: r);
    }).toList();

    final rConv = 1.0 / (bc.hConv * area);
    final rConductionTotal = layers.fold(0.0, (s, l) => s + l.rConduction);
    final rTotal = rConductionTotal + rConv;

    final deltaT = bc.tHot - bc.tAmbient;
    final q = deltaT / rTotal; // Watts

    // Temperature profile
    final profile = <TemperaturePoint>[];
    var tCurrent = bc.tHot;
    var cumMm = 0.0;

    profile.add(TemperaturePoint(
      position: 0,
      temperature: tCurrent,
      label: 'Hot Surface (Ts)',
    ));

    final layerResults = <LayerResult>[];

    for (int i = 0; i < layers.length; i++) {
      final layer = layers[i];
      final tIn = tCurrent;
      final dTLayer = q * layer.rConduction;
      tCurrent -= dTLayer;
      cumMm += layer.mat.thickness;

      profile.add(TemperaturePoint(
        position: cumMm,
        temperature: double.parse(tCurrent.toStringAsFixed(4)),
        label: 'After ${layer.mat.name}',
      ));

      layerResults.add(LayerResult(
        name: layer.mat.name,
        label: layer.mat.label,
        thicknessMm: layer.mat.thickness,
        kWmK: layer.mat.k,
        densityKgM3: layer.mat.density,
        rConduction: layer.rConduction,
        tIn: tIn,
        tOut: double.parse(tCurrent.toStringAsFixed(4)),
        dT: double.parse((tIn - tCurrent).toStringAsFixed(4)),
        heatFluxW: double.parse(q.toStringAsFixed(4)),
        color: layer.mat.color,
      ));
    }

    profile.add(TemperaturePoint(
      position: cumMm,
      temperature: bc.tAmbient,
      label: 'Ambient (T∞)',
    ));

    // Biot number (dominant layer)
    final dominant = layers.reduce((a, b) => a.rConduction > b.rConduction ? a : b);
    final bi = (bc.hConv * dominant.thicknessM) / dominant.mat.k;

    return CalculationResult(
      heatFluxW: double.parse(q.toStringAsFixed(4)),
      heatFluxWPerM2: double.parse((q / area).toStringAsFixed(4)),
      rTotal: double.parse(rTotal.toStringAsFixed(6)),
      rConductionTotal: double.parse(rConductionTotal.toStringAsFixed(6)),
      rConvection: double.parse(rConv.toStringAsFixed(6)),
      deltaTTotal: deltaT,
      totalThicknessMm: materials.fold(0.0, (s, m) => s + m.thickness),
      biotNumber: double.parse(bi.toStringAsFixed(4)),
      temperatureProfile: profile,
      layerAnalysis: layerResults,
      isOffline: isOffline,
      computedAt: DateTime.now(),
    );
  }

  /// Generate AI prompt context for Claude
  static String buildAiPromptContext(
    CalculationResult result,
    List<WallMaterial> materials,
    BoundaryConditions bc,
  ) {
    final sb = StringBuffer();
    sb.writeln('You are a thermal engineering expert for Pentas Insulations Pvt Ltd.');
    sb.writeln('Analyze this composite wall CFD result and provide a concise, expert insight (150 words max).');
    sb.writeln('Focus on: performance assessment, potential improvements, and industrial applicability.');
    sb.writeln('');
    sb.writeln('=== WALL CONFIGURATION ===');
    for (final mat in materials) {
      sb.writeln('• ${mat.name} (${mat.label}): k=${mat.k} W/mK, ρ=${mat.density} kg/m³, t=${mat.thickness}mm');
    }
    sb.writeln('');
    sb.writeln('=== BOUNDARY CONDITIONS ===');
    sb.writeln('Hot surface: ${bc.tHot}°C | Ambient: ${bc.tAmbient}°C | h: ${bc.hConv} W/m²K');
    sb.writeln('');
    sb.writeln('=== RESULTS ===');
    sb.writeln('Heat flux: ${result.heatFluxWPerM2} W/m²');
    sb.writeln('Total R: ${result.rTotal} m²K/W');
    sb.writeln('Biot number: ${result.biotNumber}');
    sb.writeln('');
    sb.writeln('Temperature profile:');
    for (final pt in result.temperatureProfile) {
      sb.writeln('  ${pt.label}: ${pt.temperature.toStringAsFixed(1)}°C');
    }
    sb.writeln('');
    sb.writeln('Layer drops:');
    for (final lr in result.layerAnalysis) {
      sb.writeln('  ${lr.name}: ΔT=${lr.dT.toStringAsFixed(2)}°C, R=${lr.rConduction.toStringAsFixed(5)} m²K/W');
    }
    sb.writeln('');
    sb.writeln('Provide your expert analysis in plain text (no markdown). Be specific and actionable.');
    return sb.toString();
  }

  /// Get thermal efficiency rating
  static String efficiencyRating(double rTotal) {
    if (rTotal >= 1.0) return 'Excellent';
    if (rTotal >= 0.5) return 'Good';
    if (rTotal >= 0.2) return 'Moderate';
    return 'Low';
  }

  static Color efficiencyColor(double rTotal) {
    if (rTotal >= 1.0) return const Color(0xFF10B981);
    if (rTotal >= 0.5) return const Color(0xFF3B82F6);
    if (rTotal >= 0.2) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _LayerIntermediate {
  final WallMaterial mat;
  final double thicknessM;
  final double rConduction;

  _LayerIntermediate({
    required this.mat,
    required this.thicknessM,
    required this.rConduction,
  });
}
