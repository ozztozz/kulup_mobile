import "package:flutter/material.dart";
import "core/offline_queue_service.dart";
import "features/auth/auth_service.dart";
import "features/auth/login_page.dart";
import "features/dashboard/dashboard_page.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KulupApp());
}

class KulupApp extends StatelessWidget {
  const KulupApp({super.key});

  @override
  Widget build(BuildContext context) {
    const paletteNavy = Color(0xFF3A3D55);
    const paletteNavyStrong = Color(0xFF2F3248);
    const paletteSlate = Color(0xFF7E8CAA);
    const paletteTeal = Color(0xFFA5BBBE);
    const paletteMist = Color(0xFFE6EBEA);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: paletteSlate,
      brightness: Brightness.light,
    ).copyWith(
      primary: paletteNavy,
      onPrimary: Colors.white,
      primaryContainer: paletteSlate.withValues(alpha: 0.24),
      onPrimaryContainer: paletteNavy,
      secondary: paletteSlate,
      onSecondary: Colors.white,
      secondaryContainer: paletteSlate.withValues(alpha: 0.2),
      onSecondaryContainer: paletteNavy,
      tertiary: paletteTeal,
      onTertiary: paletteNavy,
      tertiaryContainer: paletteTeal.withValues(alpha: 0.26),
      onTertiaryContainer: paletteNavy,
      surface: paletteMist,
      onSurface: paletteNavyStrong,
      onSurfaceVariant: const Color(0xFF4F5B70),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF2F5F5),
      surfaceContainer: const Color(0xFFE9EDED),
      outline: const Color(0xFF8E9AAC),
      outlineVariant: const Color(0xFFB8C1CC),
    );

    final base = ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      useMaterial3: true,
    );

    return MaterialApp(
      title: "Alpha Academy",
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return HeroMode(
          enabled: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: base.copyWith(
        textTheme: base.textTheme.apply(
          bodyColor: base.colorScheme.onSurface,
          displayColor: base.colorScheme.onSurface,
        ),
        appBarTheme: AppBarTheme(
          elevation: 1,
          centerTitle: false,
          backgroundColor: base.colorScheme.surfaceContainerLowest,
          foregroundColor: base.colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: base.colorScheme.onSurface),
        dividerTheme: DividerThemeData(
          color: base.colorScheme.outlineVariant,
          thickness: 1,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: base.colorScheme.surfaceContainerLowest,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: base.colorScheme.outlineVariant),
          ),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: base.colorScheme.primary,
          textColor: base.colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: base.colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: base.colorScheme.primary, width: 1.2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: base.colorScheme.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  final AuthService _authService = AuthService();
  final OfflineQueueService _offlineQueueService = OfflineQueueService();
  bool _checkingSession = true;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final hasSession = await _authService.hasSession();
    if (hasSession) {
      await _offlineQueueService.syncPendingCreates();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _authenticated = hasSession;
      _checkingSession = false;
    });
  }

  void _onLoginSuccess() {
    _offlineQueueService.syncPendingCreates();
    setState(() {
      _authenticated = true;
    });
  }

  void _onLogout() {
    setState(() {
      _authenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_authenticated) {
      return DashboardPage(onLogout: _onLogout);
    }

    return LoginPage(onLoginSuccess: _onLoginSuccess);
  }
}
