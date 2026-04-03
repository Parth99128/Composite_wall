import 'package:flutter/material.dart';

class WallMaterial {
  final String id;
  final String name;
  final String label;
  final double k; // thermal conductivity W/mK
  final double density; // kg/m³
  final double specificHeat; // J/kgK
  final double thickness; // mm
  final Color color;

  WallMaterial({
    required this.id,
    required this.name,
    this.label = '',
    required this.k,
    required this.density,
    this.specificHeat = 840,
    required this.thickness,
    required this.color,
  });

  WallMaterial copyWith({
    String? id,
    String? name,
    String? label,
    double? k,
    double? density,
    double? specificHeat,
    double? thickness,
    Color? color,
  }) {
    return WallMaterial(
      id: id ?? this.id,
      name: name ?? this.name,
      label: label ?? this.label,
      k: k ?? this.k,
      density: density ?? this.density,
      specificHeat: specificHeat ?? this.specificHeat,
      thickness: thickness ?? this.thickness,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'label': label,
        'k': k,
        'density': density,
        'specificHeat': specificHeat,
        'thickness': thickness,
        'color': color.value.toString(),
      };

  factory WallMaterial.fromJson(Map<String, dynamic> json) => WallMaterial(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        label: json['label'] ?? '',
        k: (json['k'] as num).toDouble(),
        density: (json['density'] as num).toDouble(),
        specificHeat: (json['specificHeat'] as num? ?? 840).toDouble(),
        thickness: (json['thickness'] as num).toDouble(),
        color: Color(int.parse(json['color'] ?? '4294927155')),
      );
}

class BoundaryConditions {
  final double tHot;
  final double tAmbient;
  final double hConv;
  final double area;

  const BoundaryConditions({
    this.tHot = 200,
    this.tAmbient = 50,
    this.hConv = 4,
    this.area = 1,
  });

  BoundaryConditions copyWith({
    double? tHot,
    double? tAmbient,
    double? hConv,
    double? area,
  }) =>
      BoundaryConditions(
        tHot: tHot ?? this.tHot,
        tAmbient: tAmbient ?? this.tAmbient,
        hConv: hConv ?? this.hConv,
        area: area ?? this.area,
      );

  Map<String, dynamic> toJson() => {
        'T_hot': tHot,
        'T_ambient': tAmbient,
        'h_conv': hConv,
        'area': area,
      };
}

class TemperaturePoint {
  final double position; // mm from hot side
  final double temperature;
  final String label;

  const TemperaturePoint({
    required this.position,
    required this.temperature,
    required this.label,
  });
}

class LayerResult {
  final String name;
  final String label;
  final double thicknessMm;
  final double kWmK;
  final double densityKgM3;
  final double rConduction;
  final double tIn;
  final double tOut;
  final double dT;
  final double heatFluxW;
  final Color color;

  const LayerResult({
    required this.name,
    required this.label,
    required this.thicknessMm,
    required this.kWmK,
    required this.densityKgM3,
    required this.rConduction,
    required this.tIn,
    required this.tOut,
    required this.dT,
    required this.heatFluxW,
    required this.color,
  });
}

class CalculationResult {
  final double heatFluxW;
  final double heatFluxWPerM2;
  final double rTotal;
  final double rConductionTotal;
  final double rConvection;
  final double deltaTTotal;
  final double totalThicknessMm;
  final double biotNumber;
  final List<TemperaturePoint> temperatureProfile;
  final List<LayerResult> layerAnalysis;
  final bool isOffline;
  final DateTime computedAt;
  String? aiInsight;

  CalculationResult({
    required this.heatFluxW,
    required this.heatFluxWPerM2,
    required this.rTotal,
    required this.rConductionTotal,
    required this.rConvection,
    required this.deltaTTotal,
    required this.totalThicknessMm,
    required this.biotNumber,
    required this.temperatureProfile,
    required this.layerAnalysis,
    this.isOffline = false,
    required this.computedAt,
    this.aiInsight,
  });
}

// Default Pentas Insulations materials (hot→cold order)
final defaultMaterials = [
  WallMaterial(
    id: 'mat4',
    name: 'Material 4',
    label: 'Cementitious Outer Layer',
    k: 0.7,
    density: 1200,
    specificHeat: 880,
    thickness: 0.5,
    color: const Color(0xFFA78BFA),
  ),
  WallMaterial(
    id: 'mat1',
    name: 'Material 1',
    label: 'Mineral Wool Insulation',
    k: 0.1,
    density: 160,
    specificHeat: 840,
    thickness: 25,
    color: const Color(0xFFFF6B35),
  ),
  WallMaterial(
    id: 'mat2',
    name: 'Material 2',
    label: 'Aerogel Blanket',
    k: 0.037,
    density: 170,
    specificHeat: 1000,
    thickness: 6,
    color: const Color(0xFF00D4FF),
  ),
  WallMaterial(
    id: 'mat3',
    name: 'Material 3',
    label: 'Cementitious Inner Layer',
    k: 0.7,
    density: 1200,
    specificHeat: 880,
    thickness: 0.5,
    color: const Color(0xFFFFD700),
  ),
];
