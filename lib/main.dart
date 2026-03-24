import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/isar_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/share_intent_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/domain/entities/theme_settings.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Isar (banco local)
  await IsarService.getInstance();

  // Inicializa notificações locais
  await NotificationService.init();

  runApp(const ProviderScope(child: WishNesitaApp()));
}

class WishNesitaApp extends ConsumerStatefulWidget {
  const WishNesitaApp({super.key});

  @override
  ConsumerState<WishNesitaApp> createState() => _WishNesitaAppState();
}

class _WishNesitaAppState extends ConsumerState<WishNesitaApp> {
  @override
  void initState() {
    super.initState();
    _initShareIntent();
  }

  void _initShareIntent() {
    shareIntentServiceInstance.init(
      onShared: (data) {
        // Navega para a tela de recebimento com os dados do share
        appRouter.go('/share-received', extra: data);
      },
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
      routerConfig: appRouter,
      theme: AppTheme.light(settings.primaryColor),
      darkTheme: AppTheme.dark(settings.primaryColor),
      themeMode: settings.themeMode,
    );
  }
}
