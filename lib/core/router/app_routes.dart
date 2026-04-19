abstract class AppRoutes {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const collectionDetail = '/collection/:id';
  static const createCollection = '/collection/create';
  static const editCollection = '/collection/:id/edit';
  static const itemDetail = '/item/:id';
  static const editItem = '/item/:id/edit';
  static const createItem = '/collection/:collectionId/item/create';
  static const shareReceived = '/share-received';
  static const settings = '/settings';
  static const profile = '/profile';

  // Auth
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const resetPassword = '/auth/reset-password';

  static const search = '/search';
  static const friends = '/friends';

  // Listas compartilhadas
  static const createSharedCollection = '/shared/create';
  static const sharedJoin = '/shared/join';
  static const sharedInvite = '/shared/:id/invite';
  static const sharedMembers = '/shared/:id/members';
}
