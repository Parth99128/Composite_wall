import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  List<WallMaterial> _materials = List.from(defaultMaterials);
  bool _apiAvailable = false;

  @override
  void initState() {
    super.initState();
    _syncWithApi();
  }

  Future<void> _syncWithApi() async {
    try {
      final mats = await ApiService.getMaterials();
      setState(() {
        _materials = mats;
        _apiAvailable = true;
      });
    } catch (_) {
      setState(() => _apiAvailable = false);
    }
  }

  void _openForm({WallMaterial? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MaterialForm(
        existing: existing,
        colorIndex: _materials.length % AppColors.matColors.length,
        onSave: (mat) async {
          if (existing != null) {
            if (_apiAvailable) {
              try { await ApiService.updateMaterial(mat); } catch (_) {}
            }
            setState(() {
              final idx = _materials.indexWhere((m) => m.id == mat.id);
              if (idx >= 0) _materials[idx] = mat;
            });
          } else {
            WallMaterial saved = mat;
            if (_apiAvailable) {
              try { saved = await ApiService.addMaterial(mat); } catch (_) {}
            }
            setState(() => _materials.add(saved));
          }
        },
      ),
    );
  }

  void _deleteMaterial(WallMaterial mat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('Delete Material',
            style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Remove "${mat.name}" from the wall?',
            style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_apiAvailable) {
                try { await ApiService.deleteMaterial(mat.id); } catch (_) {}
              }
              setState(() => _materials.removeWhere((m) => m.id == mat.id));
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalThickness = _materials.fold(0.0, (s, m) => s + m.thickness);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PENTAS INSULATIONS',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        letterSpacing: 2,
                      )),
                  const SizedBox(height: 4),
                  Text('Material Library',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 8),
                  if (!_apiAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Text('⚠️  Offline — changes are local only',
                          style: GoogleFonts.inter(color: AppColors.warning, fontSize: 12)),
                    ),
                ],
              ),
            ),

            // Summary bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _SummaryBadge(
                      label: 'Layers',
                      value: '${_materials.length}',
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 24),
                    _SummaryBadge(
                      label: 'Total Thickness',
                      value: '${totalThickness.toStringAsFixed(1)} mm',
                      color: AppColors.accentAlt,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _syncWithApi,
                      child: Text('🔄', style: TextStyle(fontSize: 20)),
                    ),
                  ],
                ),
              ),
            ),

            // Material list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _materials.length,
                itemBuilder: (_, i) => _MaterialCard(
                  material: _materials[i],
                  index: i,
                  onEdit: () => _openForm(existing: _materials[i]),
                  onDelete: () => _deleteMaterial(_materials[i]),
                ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn().slideX(begin: 0.05),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.accentGreen,
        foregroundColor: Colors.black,
        icon: const Text('＋', style: TextStyle(fontSize: 20)),
        label: Text('Add Layer', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
        Text(value, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 17, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final WallMaterial material;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaterialCard({
    required this.material,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
            height: 100,
            decoration: BoxDecoration(
              color: material.color,
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
                      Expanded(
                        child: Text(
                          material.name,
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onEdit,
                        icon: const Text('✏️', style: TextStyle(fontSize: 16)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Text('🗑️', style: TextStyle(fontSize: 16)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Text(
                    material.label,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _Stat('k', '${material.k}', 'W/mK'),
                      const SizedBox(width: 16),
                      _Stat('ρ', '${material.density.toInt()}', 'kg/m³'),
                      const SizedBox(width: 16),
                      _Stat('t', '${material.thickness}', 'mm', color: material.color),
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

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? color;

  const _Stat(this.label, this.value, this.unit, {this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 10)),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: value,
              style: GoogleFonts.spaceGrotesk(
                color: color ?? AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: ' $unit',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
            ),
          ]),
        ),
      ],
    );
  }
}

// ─── Material Form Bottom Sheet ─────────────────────────────────────────────

class _MaterialForm extends StatefulWidget {
  final WallMaterial? existing;
  final int colorIndex;
  final Future<void> Function(WallMaterial) onSave;

  const _MaterialForm({this.existing, required this.colorIndex, required this.onSave});

  @override
  State<_MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends State<_MaterialForm> {
  late TextEditingController _name, _label, _k, _density, _specificHeat, _thickness;
  late Color _selectedColor;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _name = TextEditingController(text: m?.name ?? '');
    _label = TextEditingController(text: m?.label ?? '');
    _k = TextEditingController(text: m?.k.toString() ?? '');
    _density = TextEditingController(text: m?.density.toString() ?? '');
    _specificHeat = TextEditingController(text: m?.specificHeat.toString() ?? '840');
    _thickness = TextEditingController(text: m?.thickness.toString() ?? '');
    _selectedColor = m?.color ?? AppColors.matColors[widget.colorIndex];
  }

  @override
  void dispose() {
    for (final c in [_name, _label, _k, _density, _specificHeat, _thickness]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.isEmpty || _k.text.isEmpty || _density.text.isEmpty || _thickness.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fill in all required fields', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final mat = WallMaterial(
      id: widget.existing?.id ?? 'local_${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      label: _label.text.trim(),
      k: double.tryParse(_k.text) ?? 0.1,
      density: double.tryParse(_density.text) ?? 160,
      specificHeat: double.tryParse(_specificHeat.text) ?? 840,
      thickness: double.tryParse(_thickness.text) ?? 10,
      color: _selectedColor,
    );
    await widget.onSave(mat);
    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.existing != null ? 'Edit Material' : 'Add Material Layer',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _Field(label: 'Name *', controller: _name, hint: 'e.g. Material 5'),
            _Field(label: 'Description', controller: _label, hint: 'e.g. Fire Board'),
            Row(
              children: [
                Expanded(child: _Field(label: 'k (W/mK) *', controller: _k, hint: '0.1', keyboard: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _Field(label: 'Density (kg/m³) *', controller: _density, hint: '160', keyboard: TextInputType.number)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _Field(label: 'Specific Heat (J/kgK)', controller: _specificHeat, hint: '840', keyboard: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _Field(label: 'Thickness (mm) *', controller: _thickness, hint: '25', keyboard: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Color', style: GoogleFonts.jetBrainsMono(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Row(
              children: AppColors.matColors.map((c) {
                final selected = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 36, height: 36,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selected ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: selected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 10)] : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: widget.existing != null ? 'Save Changes' : 'Add Layer',
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboard;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              color: AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}
