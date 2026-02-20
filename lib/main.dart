import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/revenue_cat_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/coach_screen.dart';
import 'screens/log_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/pro_paywall_screen.dart';
import 'screens/insights_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try { await RevenueCatService.initialize(); } catch (_) {}
  runApp(const CalSnapApp());
}

class CalSnapApp extends StatelessWidget {
  const CalSnapApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CalSnap',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    home: const _AppGate(),
    routes: {
      '/onboarding': (_) => const OnboardingScreen(),
      '/auth':       (_) => const LoginScreen(),
      '/home':       (_) => const MainShell(),
      '/scan':       (_) => const ScanScreen(),
      '/coach':      (_) => const MainShell(initialIndex: 2),
      '/pro':        (_) => const ProPaywallScreen(),
      '/insights':   (_) => const InsightsScreen(),
    },
  );
}

class _AppGate extends StatelessWidget {
  const _AppGate();

  Future<bool> _onboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_done') ?? false;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _onboardingDone(),
    builder: (_, snap) {
      if (!snap.hasData) return const _Splash();
      if (!snap.data!) return const OnboardingScreen();
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (_, authSnap) {
          if (authSnap.connectionState == ConnectionState.waiting) return const _Splash();
          if (authSnap.hasData) return const MainShell();
          return const LoginScreen();
        },
      );
    },
  );
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 90, height: 90,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.primaryGradient),
        child: const Center(child: Text('📸', style: TextStyle(fontSize: 44))),
      ),
      const SizedBox(height: 20),
      const CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
    ])),
  );
}

// ── Main Shell ───────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;
  @override
  void initState() { super.initState(); _index = widget.initialIndex; }

  final _pages = const [HomeScreen(), LogScreen(), CoachScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _index, children: _pages),
    bottomNavigationBar: _BottomNav(
      currentIndex: _index,
      onTap: (i) => setState(() => _index = i),
    ),
    floatingActionButton: _CameraFAB(),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
  );
}

class _CameraFAB extends StatefulWidget {
  @override
  State<_CameraFAB> createState() => _CameraFABState();
}

class _CameraFABState extends State<_CameraFAB> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulse = Tween(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _pulse,
    child: GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/scan'),
      child: Container(
        width: 65, height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.primaryGradient,
          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 4)],
        ),
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
      ),
    ),
  );
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('🏠', 'Bosh', 0), ('📋', 'Log', 1), ('🤖', 'Coach', 2), ('👤', 'Profil', 3),
    ];
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        // Left 2 tabs
        ...items.take(2).map((item) => _NavTile(item: item, selected: currentIndex == item.$3, onTap: () => onTap(item.$3))),
        // Center space for FAB
        const SizedBox(width: 80),
        // Right 2 tabs
        ...items.skip(2).map((item) => _NavTile(item: item, selected: currentIndex == item.$3, onTap: () => onTap(item.$3))),
      ]),
    );
  }
}

class _NavTile extends StatelessWidget {
  final (String, String, int) item;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(item.$1, style: TextStyle(fontSize: selected ? 24 : 20)),
      ),
      Text(item.$2, style: TextStyle(fontSize: 10,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        color: selected ? AppTheme.primary : AppTheme.muted)),
    ]),
  ));
}

// End of main.dart
