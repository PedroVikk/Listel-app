import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final seenOnboarding = await OnboardingService.hasSeenOnboarding();
  runApp(ProviderScope(
    child: WishNesitaApp(
      initialLocation:
          seenOnboarding ? AppRoutes.home : AppRoutes.onboarding,
    ),
  ));
}

class WishNesitaApp extends ConsumerStatefulWidget {
  final String initialLocation;
  const WishNesitaApp({super.key, required this.initialLocation});

  @override
  ConsumerState<WishNesitaApp> createState() => _WishNesitaAppState();
}

class _WishNesitaAppState extends ConsumerState<WishNesitaApp> {
  late final _router = createAppRouter(initialLocation: widget.initialLocation);

  @override
  void initState() {
    super.initState();
    shareIntentServiceInstance.init(
      onShared: (data) => _router.go(AppRoutes.shareReceived, extra: data),
    );
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
