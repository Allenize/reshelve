import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/app_store.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/debts_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF080E0F),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final store = AppStore();
  await store.init();

  runApp(ChangeNotifierProvider.value(value: store, child: const ReshelveApp()));
}

class ReshelveApp extends StatelessWidget {
  const ReshelveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reshelve',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  // Balanced 5-tab nav: Home | Stock | [Sale FAB] | Utang | Settings
  // Index mapping:        0      1         2           3       4

  void _goTo(int idx) => setState(() => _idx = idx);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      extendBody: true,
      body: Stack(children: [
        // Background radial glow
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -1),
                  radius: 1.2,
                  colors: [AppColors.accent.withOpacity(0.05), Colors.transparent],
                ),
              ),
            ),
          ),
        ),

        IndexedStack(
          index: _idx,
          children: [
            HomeScreen(goTo: _goTo),
            const InventoryScreen(), // includes Scan FAB inside
            const SalesScreen(),
            const DebtsScreen(),
            const SettingsScreen(),
          ],
        ),
      ]),
      bottomNavigationBar: _BottomNav(currentIndex: _idx, onTap: _goTo),
    );
  }
}

// ── Balanced 5-tab Navigation ─────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xEB080E0F),
        border: const Border(top: BorderSide(color: AppColors.glassBorder)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home,
              label: 'Home', active: currentIndex == 0, onTap: () => onTap(0)),
          _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2,
              label: 'Stock', active: currentIndex == 1, onTap: () => onTap(1)),

          // Center FAB — New Sale
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Transform.translate(
                  offset: const Offset(0, -10),
                  child: Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                        BoxShadow(color: AppColors.accent.withOpacity(0.18), blurRadius: 0, spreadRadius: 6),
                      ],
                    ),
                    child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),

          _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long,
              label: 'Utang', active: currentIndex == 3, onTap: () => onTap(3)),
          _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings,
              label: 'Settings', active: currentIndex == 4, onTap: () => onTap(4)),
        ]),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 20 : 0,
            height: 3,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2)),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(active ? activeIcon : icon,
                key: ValueKey(active), size: 22,
                color: active ? AppColors.accent : AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3,
            color: active ? AppColors.accent : AppColors.muted,
          )),
        ]),
      ),
    );
  }
}
