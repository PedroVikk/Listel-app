import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/services/isar_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/share_intent_service.dart';
import 'core/services/onboarding_service.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/domain/entities/theme_settings.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.getInstance();
  await NotificationService.init();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  final seenOnboarding = await OnboardingService.hasSeenOnboarding();

  // Cold start: verifica se o app foi aberto por um deep link
  final appLinks = AppLinks();
  final initialUri = await appLinks.getInitialLink();

  runApp(ProviderScope(
    child: WishNesitaApp(
      initialLocation: seenOnboarding ? AppRoutes.home : AppRoutes.onboarding,
      coldStartUri: initialUri,
    ),
  ));
}

class WishNesitaApp extends ConsumerStatefulWidget {
  final String initialLocation;
  final Uri? coldStartUri;

  const WishNesitaApp({
    super.key,
    required this.initialLocation,
    this.coldStartUri,
  });

  @override
  ConsumerState<WishNesitaApp> createState() => _WishNesitaAppState();
}

class _WishNesitaAppState extends ConsumerState<WishNesitaApp> {
  late final _router = createAppRouter(initialLocation: widget.initialLocation);
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();

    shareIntentServiceInstance.init(
      onShared: (data) => _router.go(AppRoutes.shareReceived, extra: data),
    );

    // Cold start: navega para a rota do deep link após o app estar pronto
    if (widget.coldStartUri != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDeepLink(widget.coldStartUri!);
      });
    }

    // Hot start: app já estava aberto e recebeu um link
    _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'listel') return;

    if (uri.host == 'invite') {
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        _router.go('${AppRoutes.sharedJoin}?code=$code');
      }
    }
  }

  @override
  void dispose() {
    shareIntentServiceInstance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(themeSettingsProvider);
    final settings = settingsAsync.valueOrNull ?? ThemeSettings.defaults;

    return MaterialApp.router(
      title: 'Listel',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.light(settings.primaryColor),
      darkTheme: AppTheme.dark(settings.primaryColor),
      themeMode: settings.themeMode,
    );
  }
}
