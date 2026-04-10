abstract class PriceSource {
  /// Domínios cobertos diretamente por esta fonte.
  /// O orquestrador usa isso para saber que NÃO precisa do SerpAPI nesses domínios.
  Set<String> get coveredDomains;

  /// Nome legível da fonte (ex: "Mercado Livre")
  String get sourceName;

  Future<List<PriceAlternative>> search({
    required String productName,
    required double currentPrice,
  });
}

class PriceAlternative {
  final String title;
  final double price;
  final String url;
  final String? thumbnailUrl;
  final String source;
  final String? condition;

  const PriceAlternative({
    required this.title,
    required this.price,
    required this.url,
    this.thumbnailUrl,
    required this.source,
    this.condition,
  });

  factory PriceAlternative.fromJson(Map<String, dynamic> json) {
    return PriceAlternative(
      title: (json['title'] as String?) ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      url: (json['link'] as String?) ?? '',
      thumbnailUrl: json['thumbnail'] as String?,
      source: (json['store'] as String?) ?? 'Loja',
    );
  }

  double percentDiff(double originalPrice) =>
      ((price - originalPrice) / originalPrice) * 100;
}
