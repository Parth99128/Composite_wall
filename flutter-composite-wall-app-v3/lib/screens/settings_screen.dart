import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _tHot, _tAmb, _hConv, _area;
  bool _apiAvailable = false;
  bool _saved = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tHot = TextEditingController(text: '200');
    _tAmb = TextEditingController(text: '50');
    _hConv = TextEditingController(text: '4');
    _area = TextEditingController(text: '1');
    _fetchFromApi();
  }

  Future<void> _fetchFromApi() async {
    try {
      final bc = await ApiService.getBoundaryConditions();
      setState(() {
        _tHot.text = bc.tHot.toString();
        _tAmb.text = bc.tAmbient.toString();
        _hConv.text = bc.hConv.toString();
        _area.text = bc.area.toString();
        _apiAvailable = true;
      });
    } catch (_) {
      setState(() => _apiAvailable = false);
    }
  }

  Future<void> _save() async {
    final tHot = double.tryParse(_tHot.text) ?? 200;
    final tAmb = double.tryParse(_tAmb.text) ?? 50;
    if (tHot <= tAmb) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Hot surface must be hotter than ambient!',
            style: GoogleFonts.inter()),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _saving = true);
    final bc = BoundaryConditions(
      tHot: tHot,
      tAmbient: tAmb,
      hConv: double.tryParse(_hConv.text) ?? 4,
      area: double.tryParse(_area.text) ?? 1,
    );

    if (_apiAvailable) {
      try {
        await ApiService.updateBoundaryConditions(bc);
      } catch (_) {}
    }

    setState(() { _saving = false; _saved = true; });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  double get _deltaT =>
      (double.tryParse(_tHot.text) ?? 200) - (double.tryParse(_tAmb.text) ?? 50);
  double get _rConv =>
      1 / ((double.tryParse(_hConv.text) ?? 4) * (double.tryParse(_area.text) ?? 1));
  double get _maxQ =>
      _deltaT * (double.tryParse(_hConv.text) ?? 4) * (double.tryParse(_area.text) ?? 1);

  @override
  void dispose() {
    for (final c in [_tHot, _tAmb, _hConv, _area]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PENTAS INSULATIONS',
                  style: GoogleFonts.jetBrainsMono(
                      color: AppColors.textSecondary, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text('Boundary Conditions',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800)),

              if (!_apiAvailable) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Text('⚠️  Offline — changes not synced',
                      style: GoogleFonts.inter(color: AppColors.warning, fontSize: 12)),
                ),
              ],

              const SizedBox(height: 20),

              _BcField(
                label: 'Hot Surface Temperature (Ts)',
                description: 'Inner wall face — heat source side',
                controller: _tHot,
                unit: '°C',
                accentColor: AppColors.hot,
                icon: '🔥',
              ).animate().fadeIn(delay: 100.ms),

              _BcField(
                label: 'Ambient Temperature (T∞)',
                description: 'Surrounding air temperature',
                controller: _tAmb,
                unit: '°C',
                accentColor: AppColors.cold,
                icon: '❄️',
              ).animate().fadeIn(delay: 180.ms),

              _BcField(
                label: 'Convective Coefficient (h)',
                description: 'Heat transfer at outer surface',
                controller: _hConv,
                unit: 'W/m²K',
                accentColor: AppColors.accentAlt,
                icon: '💨',
              ).animate().fadeIn(delay: 260.ms),

              _BcField(
                label: 'Wall Area (A)',
                description: 'Cross-sectional area',
                controller: _area,
                unit: 'm²',
                accentColor: AppColors.accentGreen,
                icon: '📐',
              ).animate().fadeIn(delay: 340.ms),

              // Reference box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentAlt.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accentAlt.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📋 Pentas Insulations Design Values',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.accentAlt, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    for (final row in [
                      ['Ts (hot surface)', '200°C'],
                      ['T∞ (ambient)', '50°C'],
                      ['h (conv. coeff.)', '4 W/m²K'],
                      ['k ref temperature', '300°C'],
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(row[0], style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                            Text(row[1], style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 16),

              // Derived parameters
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DERIVED PARAMETERS',
                        style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textSecondary, fontSize: 10, letterSpacing: 2)),
                    const SizedBox(height: 12),
                    _DerivedRow('ΔT (Total)', '${_deltaT.toStringAsFixed(1)} °C'),
                    _DerivedRow('R_conv = 1/(h·A)', '${_rConv.toStringAsFixed(4)} m²K/W'),
                    _DerivedRow('Max q (no insulation)', '${_maxQ.toStringAsFixed(2)} W'),
                  ],
                ),
              ).animate().fadeIn(delay: 450.ms),

              const SizedBox(height: 20),

              GradientButton(
                label: _saved ? '✓ Saved!' : 'Save Boundary Conditions',
                isLoading: _saving,
                onPressed: _save,
                colors: _saved
                    ? [AppColors.success, AppColors.success]
                    : [AppColors.accent, const Color(0xFFFF8C42)],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _BcField extends StatelessWidget {
  final String label;
  final String description;
  final TextEditingController controller;
  final String unit;
  final Color accentColor;
  final String icon;

  const _BcField({
    required this.label,
    required this.description,
    required this.controller,
    required this.unit,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  Text(description,
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.spaceGrotesk(
                              color: accentColor, fontSize: 22, fontWeight: FontWeight.w800),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Text(unit,
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DerivedRow extends StatelessWidget {
  final String label;
  final String value;
  const _DerivedRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
          Text(value, style: GoogleFonts.jetBrainsMono(
              color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
