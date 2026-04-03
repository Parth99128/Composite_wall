import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/materials_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/ai_assistant_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bgCard,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const CompositeWallApp());
}

class CompositeWallApp extends StatelessWidget {
  const CompositeWallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Composite Wall CFD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final _screens = const [
    DashboardScreen(),
    MaterialsScreen(),
    AiAssistantScreen(),
    SettingsScreen(),
  ];

  final _navItems = [
    _NavItem(icon: '📊', label: 'Dashboard'),
    _NavItem(icon: '🧱', label: 'Materials'),
    _NavItem(icon: '🤖', label: 'AI Chat'),
    _NavItem(icon: '⚙️', label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        items: _navItems,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

class _NavItem {
  final String icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final selected = selectedIndex == i;
          final isAi = i == 2; // AI Chat gets special styling

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? (isAi
                          ? AppColors.accentAlt.withOpacity(0.15)
                          : AppColors.accent.withOpacity(0.15))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: selected
                      ? Border.all(
                          color: isAi
                              ? AppColors.accentAlt.withOpacity(0.4)
                              : AppColors.accent.withOpacity(0.4),
                          width: 1,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.icon,
                      style: TextStyle(
                        fontSize: 20,
                        color: selected ? null : const Color(0xFF3A4A5C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: GoogleFonts.inter(
                        color: selected
                            ? (isAi ? AppColors.accentAlt : AppColors.accent)
                            : AppColors.textDim,
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
