import 'dart:ui';
import 'package:dio/dio.dart';
import '../models/models.dart';

// ⚠️ CHANGE THIS to your deployed backend URL
// Local dev (find your IP: run `ifconfig` on Mac/Linux or `ipconfig` on Windows):
//   const String kBackendBaseUrl = 'http://192.168.X.X:3000';
// Production (after deploying to Railway/Render):
//   const String kBackendBaseUrl = 'https://your-app.up.railway.app';
const String kBackendBaseUrl = 'https://compositewall-production.up.railway.app'; // Ensure no trailing slash `/`

final _dio = Dio(BaseOptions(
  baseUrl: kBackendBaseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
  headers: {'Content-Type': 'application/json'},
));

class ApiService {
  // ─── Materials ───────────────────────────────────────────────
  static Future<List<WallMaterial>> getMaterials() async {
    final res = await _dio.get('/api/materials');
    return (res.data['materials'] as List)
        .map((m) => WallMaterial.fromJson(m))
        .toList();
  }

  static Future<WallMaterial> addMaterial(WallMaterial mat) async {
    final res = await _dio.post('/api/materials', data: mat.toJson());
    return WallMaterial.fromJson(res.data['material']);
  }

  static Future<WallMaterial> updateMaterial(WallMaterial mat) async {
    final res = await _dio.put('/api/materials/${mat.id}', data: mat.toJson());
    return WallMaterial.fromJson(res.data['material']);
  }

  static Future<void> deleteMaterial(String id) async {
    await _dio.delete('/api/materials/$id');
  }

  // ─── Boundary Conditions ────────────────────────────────────
  static Future<BoundaryConditions> getBoundaryConditions() async {
    final res = await _dio.get('/api/boundary-conditions');
    final bc = res.data['boundaryConditions'];
    return BoundaryConditions(
      tHot: (bc['T_hot'] as num).toDouble(),
      tAmbient: (bc['T_ambient'] as num).toDouble(),
      hConv: (bc['h_conv'] as num).toDouble(),
      area: (bc['area'] as num).toDouble(),
    );
  }

  static Future<void> updateBoundaryConditions(BoundaryConditions bc) async {
    await _dio.put('/api/boundary-conditions', data: bc.toJson());
  }

  // ─── Calculate ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> calculate(BoundaryConditions bc) async {
    final res = await _dio.post('/api/calculate', data: bc.toJson());
    return res.data as Map<String, dynamic>;
  }

  // ─── AI (Google Gemini FREE) ─────────────────────────────────

  /// Check if AI is available on the backend
  static Future<Map<String, dynamic>> getAiStatus() async {
    final res = await _dio.get('/api/ai/status');
    return res.data as Map<String, dynamic>;
  }

  /// Get engineering insight from a calculation result
  static Future<String?> getAiInsight(String prompt) async {
    try {
      final res = await _dio.post('/api/ai/insight', data: {'prompt': prompt});
      return res.data['insight'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Chat assistant — pass full message history for context
  static Future<String?> chat(String message, List<Map<String, dynamic>> history) async {
    try {
      final res = await _dio.post('/api/ai/chat', data: {
        'message': message,
        'history': history,
      });
      return res.data['reply'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Get material improvement suggestions
  static Future<String?> suggestMaterials(
      List<WallMaterial> materials, BoundaryConditions bc) async {
    try {
      final res = await _dio.post('/api/ai/suggest-materials', data: {
        'materials': materials.map((m) => m.toJson()).toList(),
        'boundaryConditions': bc.toJson(),
      });
      return res.data['suggestion'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Get optimized wall configuration
  static Future<String?> optimizeWall({
    double targetFlux = 100,
    double maxThickness = 50,
    String budget = 'medium',
    double temperature = 200,
  }) async {
    try {
      final res = await _dio.post('/api/ai/optimize', data: {
        'targetFlux': targetFlux,
        'maxThickness': maxThickness,
        'budget': budget,
        'temperature': temperature,
      });
      return res.data['optimization'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Explain a specific parameter value
  static Future<String?> explainParameter(
      String parameter, String value, String context) async {
    try {
      final res = await _dio.post('/api/ai/explain', data: {
        'parameter': parameter,
        'value': value,
        'context': context,
      });
      return res.data['explanation'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ─── Connectivity ────────────────────────────────────────────
  static Future<bool> isBackendReachable() async {
    try {
      await _dio.get('/',
          options: Options(receiveTimeout: const Duration(seconds: 5)));
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Parse backend calculation response into CalculationResult
CalculationResult parseApiResult(
    Map<String, dynamic> data, List<WallMaterial> materials) {
  final results = data['results'] as Map<String, dynamic>;
  final profile = (data['temperatureProfile'] as List).map((p) {
    return TemperaturePoint(
      position: (p['position'] as num).toDouble(),
      temperature: (p['temperature'] as num).toDouble(),
      label: p['label'] as String,
    );
  }).toList();

  final layers = data['layerAnalysis'] as List;
  final matColors = materials.map((m) => m.color).toList();

  final layerResults = List<LayerResult>.generate(layers.length, (i) {
    final l = layers[i];
    return LayerResult(
      name: l['name'] as String,
      label: (l['label'] as String?) ?? '',
      thicknessMm: (l['thickness_mm'] as num).toDouble(),
      kWmK: (l['k_W_mK'] as num).toDouble(),
      densityKgM3: (l['density_kg_m3'] as num).toDouble(),
      rConduction: (l['R_conduction'] as num).toDouble(),
      tIn: (l['T_in'] as num).toDouble(),
      tOut: (l['T_out'] as num).toDouble(),
      dT: (l['dT'] as num).toDouble(),
      heatFluxW: (l['heatFlux_W'] as num).toDouble(),
      color: i < matColors.length ? matColors[i] : const Color(0xFF888888),
    );
  });

  return CalculationResult(
    heatFluxW: (results['heatFlux_W'] as num).toDouble(),
    heatFluxWPerM2: (results['heatFlux_W_per_m2'] as num).toDouble(),
    rTotal: (results['R_total'] as num).toDouble(),
    rConductionTotal: (results['R_conduction_total'] as num).toDouble(),
    rConvection: (results['R_convection'] as num).toDouble(),
    deltaTTotal: (results['deltaT_total'] as num).toDouble(),
    totalThicknessMm: (results['totalThickness_mm'] as num).toDouble(),
    biotNumber: (results['biotNumber'] as num).toDouble(),
    temperatureProfile: profile,
    layerAnalysis: layerResults,
    isOffline: false,
    computedAt: DateTime.now(),
  );
}
