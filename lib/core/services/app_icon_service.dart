import 'package:flutter/services.dart';

/// Variante de ícone do launcher disponível no app.
class AppIconVariant {
  final String id;
  final String label;

  const AppIconVariant({required this.id, required this.label});

  static const all = [
    AppIconVariant(id: 'default', label: 'Padrão'),
    AppIconVariant(id: 'pink', label: 'Rosa'),
    AppIconVariant(id: 'dark', label: 'Escuro'),
  ];
}

/// Troca o ícone do launcher do Android via ActivityAlias + PackageManager.
///
/// Requer que os `<activity-alias>` correspondentes estejam declarados no
/// AndroidManifest.xml e que os recursos mipmap existam.
class AppIconService {
  static const _channel = MethodChannel('com.wishnesita/app_icon');

  /// Ativa a variante [iconId] e desativa todas as outras.
  static Future<void> setIcon(String iconId) async {
    await _channel.invokeMethod<void>('setIcon', {'icon': iconId});
  }

  /// Retorna o id da variante atualmente ativa (ex: `"default"`).
  static Future<String> getActiveIcon() async {
    return await _channel.invokeMethod<String>('getActiveIcon') ?? 'default';
  }
}
