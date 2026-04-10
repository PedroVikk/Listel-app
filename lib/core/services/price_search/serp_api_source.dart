import 'package:supabase_flutter/supabase_flutter.dart';
import 'price_source.dart';

/// Fonte SerpAPI — cobre lojas sem API direta (Amazon, Shopee, Americanas, etc.)
/// via Google Shopping. Chamada apenas quando o usuário solicitar explicitamente.
class SerpApiSource implements PriceSource {
  final SupabaseClient _supabase;
  final Set<String> _excludeDomains;

  SerpApiSource(this._supabase, {required Set<String> excludeDomains})
      : _excludeDomains = excludeDomains;

  @override
  // SerpApiSource não declara domínios próprios — cobre "o resto".
  Set<String> get coveredDomains => const {};

  @override
  String get sourceName => 'Outras lojas';

  @override
  Future<List<PriceAlternative>> search({
    required String productName,
    required double currentPrice,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'price-search',
        body: {
          'query': productName,
          'currentPrice': currentPrice,
          'excludeDomains': _excludeDomains.toList(),
        },
      );
      if (response.data == null) return [];
      return (response.data as List)
          .map((e) => PriceAlternative.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
