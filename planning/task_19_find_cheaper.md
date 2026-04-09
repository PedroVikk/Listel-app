# Task 19 — Buscar Preço Mais Barato (Orquestrador + Fontes Diretas)

## Objetivo

Para itens com nome e preço salvos, buscar alternativas mais baratas usando
um **orquestrador extensível** que roteia cada loja para o caminho certo:
API direta (grátis, sem limite) ou SerpAPI (pago/limitado, Task 20).

Esta task cobre a **infraestrutura base** e as **fontes que têm API direta**.
A Task 20 adiciona o SerpAPI como fonte de fallback para as demais lojas.

---

## Classificação de fontes

| Fonte | Abordagem | Custo | Limite | Implementada em |
|---|---|---|---|---|
| Mercado Livre | API pública direta | Grátis | Alto | ✅ Task 19 |
| Amazon, Shopee, etc. | SerpAPI (Google Shopping) | Free tier 100/mês | 100 chamadas | Task 20 |

A separação é intencional: **nunca usar SerpAPI para lojas que têm API direta**.

---

## Arquitetura — abstração `PriceSource`

### Interface base

**Arquivo:** `lib/core/services/price_search/price_source.dart`

```dart
abstract class PriceSource {
  /// Identificadores de domínio que esta fonte cobre diretamente.
  /// O orquestrador usa isso para saber que NÃO precisa do SerpAPI para esses domínios.
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
  final double price;        // preço encontrado
  final String url;
  final String? thumbnailUrl;
  final String source;       // nome da loja/fonte
  final String? condition;   // "new" | "used" | null

  double percentDiff(double originalPrice) =>
      ((price - originalPrice) / originalPrice) * 100;
}
```

### Fonte 1 — Mercado Livre

**Arquivo:** `lib/core/services/price_search/mercado_livre_source.dart`

```dart
class MercadoLivreSource implements PriceSource {
  @override
  Set<String> get coveredDomains => {
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
      final uri = Uri.parse('https://api.mercadolibre.com/sites/MLB/search')
          .replace(queryParameters: {
        'q': _normalize(productName),
        'limit': '10',
        'sort': 'price_asc',
      });
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['results'] as List)
          .where((r) => r['price'] != null)
          .map((r) => PriceAlternative(
                title: r['title'],
                price: (r['price'] as num).toDouble(),
                url: r['permalink'],
                thumbnailUrl: r['thumbnail'],
                source: sourceName,
                condition: r['condition'],
              ))
          .where((a) => a.price < currentPrice * 0.95)
          .take(5)
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _normalize(String name) =>
      name.replaceAll(RegExp(r'[^\w\s]'), '').trim().substring(0, name.length.clamp(0, 80));

  static const _timeout = Duration(seconds: 8);
  static const _headers = {'User-Agent': 'WishNesita/1.0'};
}
```

### Orquestrador

**Arquivo:** `lib/core/services/price_search/price_search_orchestrator.dart`

```dart
class PriceSearchOrchestrator {
  final List<PriceSource> _directSources;

  PriceSearchOrchestrator(this._directSources);

  /// Domínios cobertos por fontes diretas — o SerpAPI NÃO precisa buscá-los.
  Set<String> get coveredDomains =>
      _directSources.expand((s) => s.coveredDomains).toSet();

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
    return results
        .expand((list) => list)
        .toList()
      ..sort((a, b) => a.price.compareTo(b.price));
  }
}
```

### Provider

**Arquivo:** `lib/features/items/presentation/providers/price_search_provider.dart`

```dart
final priceSearchOrchestratorProvider = Provider((ref) {
  return PriceSearchOrchestrator([
    MercadoLivreSource(),
    // Adicionar novas fontes diretas aqui quando surgirem
  ]);
});

// Provider da Fase 1 (fontes diretas, sem SerpAPI)
final directPriceSearchProvider = FutureProvider.autoDispose
    .family<List<PriceAlternative>, ({String name, double price})>(
  (ref, args) => ref
      .read(priceSearchOrchestratorProvider)
      .searchDirect(productName: args.name, currentPrice: args.price),
);
```

---

## UX — fluxo de duas fases (Task 19 = Fase 1)

```
[🔍 Buscar mais barato]
          │
          ▼
   Loading (Fase 1)
   Buscando no Mercado Livre...
          │
          ▼
┌──────────────────────────────────────────────────┐
│  Alternativas mais baratas                        │
│  3 resultados · Mercado Livre                     │
├──────────────────────────────────────────────────┤
│  [img] Tênis Nike Air Max 270    R$ 198  (-32%)  │
│        Mercado Livre                   ↗ Abrir   │
│  [img] Nike Air Max Masculino    R$ 239  (-17%)  │
│        Mercado Livre                   ↗ Abrir   │
├──────────────────────────────────────────────────┤
│  [Buscar em mais lojas →]  ← dispara Task 20     │
│                                                  │
│  ⚠️ Podem ser produtos similares                  │
└──────────────────────────────────────────────────┘
```

O botão "Buscar em mais lojas" é o gatilho da Fase 2 (Task 20 / SerpAPI).
Ele aparece sempre — mesmo se Fase 1 encontrou resultados — pois o usuário
pode querer comparar com Amazon, Americanas etc.

Se Fase 1 não encontrou nada, o botão aparece com texto mais proeminente:
"Nenhum resultado no ML. Buscar em Amazon, Americanas e outras →"

---

## Arquivos a criar

| Arquivo | Ação |
|---|---|
| `lib/core/services/price_search/price_source.dart` | **Criar** — interface + `PriceAlternative` |
| `lib/core/services/price_search/mercado_livre_source.dart` | **Criar** — fonte ML |
| `lib/core/services/price_search/price_search_orchestrator.dart` | **Criar** — orquestrador |
| `lib/features/items/presentation/providers/price_search_provider.dart` | **Criar** — providers |
| `lib/features/items/presentation/pages/item_detail_page.dart` | Botão + bottom sheet Fase 1 |
| `pubspec.yaml` | Adicionar `url_launcher` se ausente |

---

## Integração com Task 18 (Verificador de Preços)

Quando Task 18 detecta que o preço subiu, o bottom sheet pode oferecer:
```
[Ignorar]   [Atualizar preço]   [Buscar mais barato →]
```

---

## Critérios de aceitação

- [ ] Botão "Buscar mais barato" aparece quando item tem nome + preço
- [ ] Fase 1 busca no ML diretamente (sem Edge Function, sem SerpAPI)
- [ ] Apenas resultados ≥ 5% mais baratos são exibidos
- [ ] Percentual de desconto visível por resultado
- [ ] "Abrir" abre URL no browser/app ML via `url_launcher`
- [ ] Botão "Buscar em mais lojas" sempre visível (gateway para Task 20)
- [ ] Erro de rede ou ML fora do ar tratados com mensagem amigável
- [ ] `PriceSource` é extensível — nova fonte = nova classe, sem alterar orquestrador
