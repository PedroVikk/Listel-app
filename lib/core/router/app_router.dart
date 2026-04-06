import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/collections/domain/entities/collection.dart';
import '../../features/collections/presentation/pages/home_page.dart';
import '../../features/collections/presentation/pages/collection_detail_page.dart';
import '../../features/collections/presentation/pages/create_edit_collection_page.dart';
import '../../features/items/presentation/pages/item_detail_page.dart';
import '../../features/items/presentation/pages/create_item_page.dart';
import '../../features/share_intent/presentation/pages/share_received_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/sharing/presentation/pages/create_shared_collection_page.dart';
import '../../features/sharing/presentation/pages/join_collection_page.dart';
import '../../features/sharing/presentation/pages/members_page.dart';
import 'app_routes.dart';

GoRouter createAppRouter({String initialLocation = AppRoutes.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const OnboardingPage(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.createCollection,
        builder: (context, state) => const CreateEditCollectionPage(),
      ),
      GoRoute(
        path: AppRoutes.collectionDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra;
          final initialCollection =
              extra is Collection ? extra : null;
          return CollectionDetailPage(
            collectionId: id,
            initialCollection: initialCollection,
          );
        },
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CreateEditCollectionPage(collectionId: id);
            },
          ),
          GoRoute(
            path: 'item/create',
            builder: (context, state) {
              final collectionId = state.pathParameters['id']!;
              return CreateItemPage(collectionId: collectionId);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.itemDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ItemDetailPage(itemId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.shareReceived,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ShareReceivedPage(sharedData: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          final redirectTo = state.uri.queryParameters['redirectTo'];
          return LoginPage(redirectTo: redirectTo);
        },
      ),
      GoRoute(
        path: AppRoutes.createSharedCollection,
        builder: (context, state) => const CreateSharedCollectionPage(),
      ),
      GoRoute(
        path: AppRoutes.sharedJoin,
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return JoinCollectionPage(code: code);
        },
      ),
      GoRoute(
        path: AppRoutes.sharedMembers,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MembersPage(collectionRemoteId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Rota não encontrada: ${state.uri}')),
    ),
  );
}
