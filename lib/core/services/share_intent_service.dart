import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareIntentService {
  StreamSubscription? _subscription;

  /// Inicia o listener de share intent e chama [onShared] com os dados recebidos.
  void init({required void Function(Map<String, dynamic> data) onShared}) {
    // Texto/URL compartilhado enquanto o app estava fechado
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      if (files.isNotEmpty) {
        final data = _parseFiles(files);
        if (data != null) onShared(data);
        ReceiveSharingIntent.instance.reset();
      }
    });

    // Texto/URL compartilhado com o app aberto
    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) {
        if (files.isNotEmpty) {
          final data = _parseFiles(files);
          if (data != null) onShared(data);
          ReceiveSharingIntent.instance.reset();
        }
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  Map<String, dynamic>? _parseFiles(List<SharedMediaFile> files) {
    final text = files
        .where((f) => f.type == SharedMediaType.text || f.type == SharedMediaType.url)
        .map((f) => f.path)
        .firstOrNull;

    if (text == null) return null;

    return {
      'url': _extractUrl(text),
      'rawText': text,
      'store': _inferStore(text),
    };
  }

  String? _extractUrl(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    return urlRegex.firstMatch(text)?.group(0);
  }

  String? _inferStore(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('shopee')) return 'Shopee';
    if (lower.contains('shein')) return 'Shein';
    if (lower.contains('mercadolivre') || lower.contains('mercadolibre')) return 'Mercado Livre';
    if (lower.contains('amazon')) return 'Amazon';
    if (lower.contains('aliexpress')) return 'AliExpress';
    if (lower.contains('magalu') || lower.contains('magazineluiza')) return 'Magazine Luiza';
    if (lower.contains('americanas')) return 'Americanas';
    if (lower.contains('submarino')) return 'Submarino';
    return null;
  }
}

// Provider acessível globalmente via InheritedWidget / ref — inicializado no main
final shareIntentServiceInstance = ShareIntentService();
