import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/price_search/price_source.dart';
import '../../../../core/services/price_search/price_search_orchestrator.dart';
import '../../../../core/services/price_search/mercado_livre_source.dart';
import '../../../../core/services/price_search/serp_api_source.dart';

final priceSearchOrchestratorProvider = Provider((ref) {
  final directSources = <PriceSource>[
    MercadoLivreSource(),
    // Adicionar novas fontes diretas aqui quando surgirem
  ];

  final coveredDomains =
      directSources.expand((s) => s.coveredDomains).toSet();

  final serpApiSource = SerpApiSource(
    Supabase.instance.client,
    excludeDomains: coveredDomains,
  );

  return PriceSearchOrchestrator(directSources, serpApiSource: serpApiSource);
});

/// Fase 1 — fontes diretas (Mercado Livre). Sem SerpAPI.
final directPriceSearchProvider = FutureProvider.autoDispose
    .family<List<PriceAlternative>, ({String name, double price})>(
  (ref, args) => ref
      .read(priceSearchOrchestratorProvider)
      .searchDirect(productName: args.name, currentPrice: args.price),
);

/// Fase 2 — SerpAPI (acionado manualmente pelo usuário).
/// Nunca chamado automaticamente — só via botão explícito na UI.
final externalPriceSearchProvider = FutureProvider.autoDispose
    .family<List<PriceAlternative>, ({String name, double price})>(
  (ref, args) => ref
      .read(priceSearchOrchestratorProvider)
      .searchExternal(productName: args.name, currentPrice: args.price),
);
