import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/thermal_engine.dart';
import '../widgets/common_widgets.dart';
import '../widgets/wall_schematic.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<WallMaterial> _materials = List.from(defaultMaterials);
  BoundaryConditions _bc = const BoundaryConditions();
  CalculationResult? _result;
  bool _loading = false;
  bool _aiLoading = false;
  bool _isOnline = false;
  String? _statusMsg;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    setState(() { _loading = true; _statusMsg = null; });

    // Try API
    final online = await ApiService.isBackendReachable();
    setState(() => _isOnline = online);

    CalculationResult result;
    if (online) {
      try {
        final data = await ApiService.calculate(_bc);
        result = parseApiResult(data, _materials);
        setState(() => _statusMsg = 'Results from server');
      } catch (_) {
        result = ThermalEngine.compute(_materials, _bc);
        setState(() => _statusMsg = 'Offline calculation');
      }
    } else {
      result = ThermalEngine.compute(_materials, _bc);
      setState(() => _statusMsg = 'Offline calculation');
    }

    setState(() {
      _result = result;
      _loading = false;
    });

    // Auto-fetch AI insight
    _fetchAiInsight();
  }

  Future<void> _fetchAiInsight() async {
    if (_result == null) return;
    setState(() => _aiLoading = true);

    final prompt = ThermalEngine.buildAiPromptContext(_result!, _materials, _bc);
    String? insight;

    if (_isOnline) {
      insight = await ApiService.getAiInsightViaBackend(prompt);
    }

    // Fallback to built-in heuristic insight
    insight ??= _buildHeuristicInsight(_result!);

    setState(() {
      _result!.aiInsight = insight;
      _aiLoading = false;
    });
  }

  String _buildHeuristicInsight(CalculationResult r) {
    final rating = ThermalEngine.efficiencyRating(r.rTotal);
    final dominant = r.layerAnalysis.reduce((a, b) => a.dT > b.dT ? a : b);
    final pct = ((dominant.rConduction / r.rTotal) * 100).toStringAsFixed(0);
    return 'Thermal performance is $rating (R=${r.rTotal.toStringAsFixed(3)} m²K/W). '
        '${dominant.name} (${dominant.label}) accounts for $pct% of total resistance '
        'with a drop of ${dominant.dT.toStringAsFixed(1)}°C — the dominant insulating layer. '
        'Heat flux of ${r.heatFluxWPerM2.toStringAsFixed(2)} W/m² indicates '
        '${r.heatFluxWPerM2 < 100 ? 'good' : 'high'} heat loss. '
        '${r.biotNumber < 0.1 ? 'Biot number < 0.1 confirms uniform temperature assumption is valid.' : 'Biot number suggests significant surface resistance — verify convection model.'} '
        'Consider increasing Material 1 thickness for improved insulation efficiency.';
  }

  List<FlSpot> _buildChartSpots() {
    if (_result == null) return [];
    final profile = _result!.temperatureProfile;
    return List.generate(profile.length, (i) {
      return FlSpot(profile[i].position, profile[i].temperature);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Wall schematic
                  WallSchematicWidget(
                    materials: _materials,
                    bc: _bc,
                    result: _result,
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 12),

                  // Thermal gradient strip
                  if (_result != null)
                    ThermalGradientStrip(
                      layers: _result!.layerAnalysis,
                      tHot: _bc.tHot,
                      tCold: _bc.tAmbient,
                    ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 12),

                  // Run button
                  GradientButton(
                    label: 'Run CFD Analysis',
                    icon: '⚡',
                    isLoading: _loading,
                    onPressed: _runAnalysis,
                  ),

                  // Status chip
                  if (_statusMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _isOnline ? AppColors.success : AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _statusMsg!,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_loading) ...[
                    const SizedBox(height: 20),
                    const LoadingCard(height: 80),
                    const SizedBox(height: 10),
                    const LoadingCard(height: 80),
                  ] else if (_result != null) ...[
                    // Key metrics
                    const SectionHeader('Key Results'),
                    _buildMetricsGrid(),

                    // AI Insight
                    const SectionHeader('AI Engineering Insight'),
                    AiInsightCard(
                      insight: _result!.aiInsight,
                      isLoading: _aiLoading,
                      onRefresh: _fetchAiInsight,
                    ).animate().fadeIn(delay: 500.ms),

                    // Temperature chart
                    const SectionHeader('Temperature Profile'),
                    _buildTempChart(),

                    // Layer analysis
                    const SectionHeader('Layer Analysis'),
                    ..._buildLayerCards(),

                    // Resistance breakdown
                    const SectionHeader('Thermal Resistance Breakdown'),
                    _buildResistanceCard(),

                    const SizedBox(height: 100),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PENTAS INSULATIONS PVT LTD',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Composite Wall CFD',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (_isOnline ? AppColors.success : AppColors.warning).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (_isOnline ? AppColors.success : AppColors.warning).withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _isOnline ? AppColors.success : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _isOnline ? 'Live API' : 'Offline',
                  style: GoogleFonts.inter(
                    color: _isOnline ? AppColors.success : AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildMetricsGrid() {
    final r = _result!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        MetricCard(
          label: 'Heat Flux',
          value: r.heatFluxWPerM2.toStringAsFixed(2),
          unit: 'W/m²',
          color: AppColors.hot,
          icon: '🔥',
          animDelay: 0,
        ),
        MetricCard(
          label: 'Total ΔT',
          value: r.deltaTTotal.toStringAsFixed(1),
          unit: '°C',
          color: AppColors.accentAlt,
          icon: '🌡️',
          animDelay: 80,
        ),
        MetricCard(
          label: 'R Total',
          value: r.rTotal.toStringAsFixed(4),
          unit: 'm²K/W',
          color: ThermalEngine.efficiencyColor(r.rTotal),
          icon: '🛡️',
          animDelay: 160,
        ),
        MetricCard(
          label: 'Biot No.',
          value: r.biotNumber.toStringAsFixed(4),
          unit: '',
          color: AppColors.accentYellow,
          icon: '📐',
          animDelay: 240,
        ),
      ],
    );
  }

  Widget _buildTempChart() {
    final spots = _buildChartSpots();
    if (spots.isEmpty) return const SizedBox();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.transparent,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 50,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}°',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}mm',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              gradient: const LinearGradient(colors: [
                Color(0xFFFF4500),
                Color(0xFFFF8C42),
                Color(0xFFFFD700),
                Color(0xFF4FC3F7),
                Color(0xFF00BFFF),
              ]),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.bgCard,
                  strokeWidth: 2,
                  strokeColor: AppColors.accent,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF4500).withOpacity(0.15),
                    const Color(0xFF00BFFF).withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  List<Widget> _buildLayerCards() {
    return _result!.layerAnalysis.asMap().entries.map((entry) {
      final i = entry.key;
      final lr = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 110,
              decoration: BoxDecoration(
                color: lr.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          lr.name,
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: lr.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${lr.thicknessMm}mm',
                            style: GoogleFonts.jetBrainsMono(
                              color: lr.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      lr.label,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatChip(label: 'k', value: '${lr.kWmK}', unit: 'W/mK'),
                        const SizedBox(width: 12),
                        _StatChip(label: 'ρ', value: '${lr.densityKgM3.toInt()}', unit: 'kg/m³'),
                        const SizedBox(width: 12),
                        _StatChip(
                          label: 'ΔT',
                          value: lr.dT.toStringAsFixed(2),
                          unit: '°C',
                          valueColor: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${lr.tIn.toStringAsFixed(1)}°C',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.hot,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.hot, AppColors.cold],
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '${lr.tOut.toStringAsFixed(1)}°C',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.cold,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: 100 * i)).fadeIn().slideX(begin: 0.05, end: 0);
    }).toList();
  }

  Widget _buildResistanceCard() {
    final r = _result!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ...r.layerAnalysis.map((lr) => ResistanceBar(
                label: lr.name,
                value: lr.rConduction,
                total: r.rTotal,
                color: lr.color,
              )),
          ResistanceBar(
            label: 'Convection',
            value: r.rConvection,
            total: r.rTotal,
            color: AppColors.cold,
          ),
          const Divider(color: AppColors.border, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Efficiency Rating',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ThermalEngine.efficiencyColor(r.rTotal).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ThermalEngine.efficiencyRating(r.rTotal),
                  style: GoogleFonts.spaceGrotesk(
                    color: ThermalEngine.efficiencyColor(r.rTotal),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? valueColor;

  const _StatChip({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 10,
            )),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.spaceGrotesk(
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
