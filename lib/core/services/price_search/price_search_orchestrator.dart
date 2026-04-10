import 'price_source.dart';
import 'serp_api_source.dart';

class PriceSearchOrchestrator {
  final List<PriceSource> _directSources;
  final SerpApiSource? _serpApiSource;

  PriceSearchOrchestrator(this._directSources, {SerpApiSource? serpApiSource})
      : _serpApiSource = serpApiSource;

  /// Domínios cobertos por fontes diretas — a Edge Function exclui esses do SerpAPI.
  Set<String> get coveredDomains =>
      _directSources.expand((s) => s.coveredDomains).toSet();

  /// Indica se a Fase 2 (SerpAPI) está disponível.
  bool get hasExternalSearch => _serpApiSource != null;

  /// Fase 1: busca em todas as fontes diretas em paralelo (grátis, sem limite).
  Future<List<PriceAlternative>> searchDirect({
    required String productName,
    required double currentPrice,
  }) async {
    final results = await Future.wait(
      _directSources.map((s) => s.search(
            productName: productName,
            currentPrice: currentPrice,
          )),
    );
    return results.expand((list) => list).toList()
      ..sort((a, b) => a.price.compareTo(b.price));
  }

  /// Fase 2: SerpAPI — só para lojas NÃO cobertas por fontes diretas.
  /// Nunca chamado automaticamente — requer ação explícita do usuário.
  Future<List<PriceAlternative>> searchExternal({
    required String productName,
    required double currentPrice,
  }) async {
    if (_serpApiSource == null) return [];
    return _serpApiSource.search(
      productName: productName,
      currentPrice: currentPrice,
    );
  }
}
