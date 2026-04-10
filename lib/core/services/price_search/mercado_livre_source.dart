import 'dart:convert';
import 'package:http/http.dart' as http;
import 'price_source.dart';

class MercadoLivreSource implements PriceSource {
  @override
  Set<String> get coveredDomains => const {
        'mercadolivre.com.br',
        'mercadolibre.com.br',
        'produto.mercadolivre.com.br',
      };

  @override
  String get sourceName => 'Mercado Livre';

  @override
  Future<List<PriceAlternative>> search({
    required String productName,
    required double currentPrice,
  }) async {
    try {
      final uri =
          Uri.parse('https://api.mercadolibre.com/sites/MLB/search').replace(
        queryParameters: {
          'q': _normalize(productName),
          'limit': '10',
          'sort': 'price_asc',
        },
      );
      final res =
          await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['results'] as List)
          .where((r) => r['price'] != null)
          .map((r) => PriceAlternative(
                title: r['title'] as String,
                price: (r['price'] as num).toDouble(),
                url: r['permalink'] as String,
                thumbnailUrl: (r['thumbnail'] as String?)
                  ?.replaceFirst('http://', 'https://'),
                source: sourceName,
                condition: r['condition'] as String?,
              ))
          .where((a) => a.price < currentPrice * 0.95)
          .take(5)
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _normalize(String name) {
    // Remove apenas caracteres que quebram queries (aspas, colchetes, etc.)
    // mas preserva letras Unicode (ã, é, ç, ô...) essenciais para o português.
    final cleaned = name
        .replaceAll(RegExp(r'[<>"{}[\]\\^`|]'), '')
        .trim();
    return cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
  }

  static const _timeout = Duration(seconds: 8);
  static const _headers = {'User-Agent': 'WishNesita/1.0'};
}
