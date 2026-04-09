# Task 20 — Busca de Preço em Múltiplas Lojas (SerpAPI como Fallback)

## Objetivo

Adicionar ao orquestrador da Task 19 uma **Fase 2** via SerpAPI que cobre
Amazon, Americanas, Magazine Luiza, Shopee e outras lojas que não têm API direta.

O SerpAPI é acionado **somente pelo usuário** (botão explícito) e **nunca retorna
resultados de lojas já cobertas pela Fase 1** — eliminando chamadas duplicadas.

---

## Princípio central: zero desperdício de chamadas SerpAPI

```
Fase 1 (Task 19) — SEMPRE, grátis
  └── ML API direta → resultados ML

Fase 2 (Task 20) — SÓ quando usuário pede
  └── SerpAPI → resultados filtrados (sem ML, sem outras fontes diretas)
              → após cache local de 6h
```

A Edge Function recebe a lista de domínios já cobertos e **exclui** esses resultados
do retorno do SerpAPI. Assim cada chamada SerpAPI traz apenas lojas novas.

---

## Por que as demais lojas precisam do SerpAPI

| Loja | API pública | HTML scrapeável sem JS |
|---|---|---|
| Amazon.com.br | ⚠️ afiliados | ❌ Cloudflare |
| Shopee | ❌ | ❌ JS obrigatório |
| Shein | ❌ | ❌ JS obrigatório |
| Americanas | ❌ | ❌ JS obrigatório |
| Magazine Luiza | ❌ | ❌ JS obrigatório |
| Casas Bahia | ❌ | ❌ JS obrigatório |
| Netshoes | ❌ | ❌ JS obrigatório |
| Kabum | ❌ | ❌ JS obrigatório |

O Google Shopping indexa e estrutura o conteúdo dessas lojas. O SerpAPI
fornece acesso a esses dados via API REST — sem violar ToS e sem JS rendering.

---

## Custo e limites do SerpAPI

| Plano | Chamadas/mês | Custo |
|---|---|---|
| **Free** | 100 | $0 |
| Hobby | 1.000 | ~$50 |

Para uso pessoal (Pedro + Inês), **100/mês é suficiente** com cache bem feito.
Estimativa real: ~1–2 chamadas/dia de uso intenso; cache de 6h reduz em ~70%.

---

## Arquitetura — extensão do orquestrador da Task 19

### 1. `SerpApiSource` — nova fonte que implementa `PriceSource`

**Arquivo:** `lib/core/services/price_search/serp_api_source.dart`

```dart
class SerpApiSource implements PriceSource {
  final SupabaseClient _supabase;
  final Set<String> _excludeDomains;  // domínios já cobertos por fontes diretas

  SerpApiSource(this._supabase, {required Set<String> excludeDomains})
      : _excludeDomains = excludeDomains;

  @override
  Set<String> get coveredDomains => {};  // não declara domínios — cobre "o resto"

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
          'excludeDomains': _excludeDomains.toList(),  // Edge Function filtra esses
        },
      );
      return (response.data as List)
          .map((e) => PriceAlternative.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
```

### 2. Orquestrador — Fase 2 adicionada

**Arquivo:** `lib/core/services/price_search/price_search_orchestrator.dart`
*(extensão do criado na Task 19)*

```dart
class PriceSearchOrchestrator {
  final List<PriceSource> _directSources;
  final SerpApiSource? _serpApiSource;

  // ...Fase 1 da Task 19 mantida intacta...

  /// Fase 2: SerpAPI — só para lojas NÃO cobertas por fontes diretas.
  Future<List<PriceAlternative>> searchExternal({
    required String productName,
    required double currentPrice,
  }) async {
    if (_serpApiSource == null) return [];
    return _serpApiSource!.search(
      productName: productName,
      currentPrice: currentPrice,
    );
  }
}
```

### 3. Supabase Edge Function — filtra domínios já cobertos

**Arquivo:** `supabase/functions/price-search/index.ts`

```typescript
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

serve(async (req) => {
  const { query, currentPrice, excludeDomains = [] } = await req.json();
  const normalizedQuery = query.trim().toLowerCase().substring(0, 80);

  // 1. Verifica cache (6h)
  const { data: cached } = await supabase
    .from("price_search_cache")
    .select("results, cached_at")
    .eq("query", normalizedQuery)
    .gt("cached_at", new Date(Date.now() - 6 * 3600 * 1000).toISOString())
    .maybeSingle();

  if (cached) {
    // Cache hit — filtra domínios excluídos e retorna
    const filtered = filterResults(cached.results, currentPrice, excludeDomains);
    return json(filtered);
  }

  // 2. Chama SerpAPI
  const params = new URLSearchParams({
    engine: "google_shopping",
    q: normalizedQuery,
    gl: "br",
    hl: "pt",
    google_domain: "google.com.br",
    api_key: Deno.env.get("SERPAPI_KEY")!,
  });

  const res = await fetch(`https://serpapi.com/search?${params}`);
  const data = await res.json();

  const rawResults = (data.shopping_results ?? []).map((r: any) => ({
    title: r.title,
    price: parseFloat(r.price?.replace(/[^\d,]/g, "").replace(",", ".") ?? "0"),
    store: r.source,
    link: r.link,
    thumbnail: r.thumbnail,
    domain: extractDomain(r.link ?? ""),
  }));

  // 3. Salva no cache (resultados brutos, sem filtrar por preço — filtro é na consulta)
  await supabase.from("price_search_cache").upsert({
    query: normalizedQuery,
    results: rawResults,
    cached_at: new Date().toISOString(),
  });

  // 4. Filtra: exclui domínios das fontes diretas + aplica threshold de preço
  return json(filterResults(rawResults, currentPrice, excludeDomains));
});

function filterResults(results: any[], currentPrice: number, excludeDomains: string[]) {
  return results
    .filter((r) => !excludeDomains.some((d) => r.domain?.includes(d)))  // remove ML etc.
    .filter((r) => r.price > 0 && r.price < currentPrice * 0.95)        // mínimo 5% mais barato
    .sort((a, b) => a.price - b.price)
    .slice(0, 8);
}

function extractDomain(url: string): string {
  try { return new URL(url).hostname; } catch { return ""; }
}

function json(data: unknown) {
  return new Response(JSON.stringify(data), {
    headers: { "Content-Type": "application/json" },
  });
}
```

**Por que o cache salva resultados brutos?**
O preço do item pode mudar entre uma consulta e outra, mas a query do produto
é a mesma. Salvar bruto permite reaplicar o filtro de preço correto na releitura.

---

## Provider da Fase 2

**Arquivo:** `lib/features/items/presentation/providers/price_search_provider.dart`
*(extensão do criado na Task 19)*

```dart
// Provider da Fase 2 — SerpAPI (acionado manualmente)
final externalPriceSearchProvider = FutureProvider.autoDispose
    .family<List<PriceAlternative>, ({String name, double price})>(
  (ref, args) {
    final orchestrator = ref.read(priceSearchOrchestratorProvider);
    return orchestrator.searchExternal(
      productName: args.name,
      currentPrice: args.price,
    );
  },
);
```

---

## UX — bottom sheet com duas fases

```
Toque inicial em "Buscar mais barato"
          │
          ▼ Fase 1 carrega (instantâneo, ML direto)
┌──────────────────────────────────────────────────┐
│  Alternativas mais baratas                        │
│  2 resultados · Mercado Livre                     │
├──────────────────────────────────────────────────┤
│  [img] Tênis Nike Air Max 270    R$ 198  (-32%)  │
│        Mercado Livre                   ↗ Abrir   │
│  [img] Nike Air Masculino        R$ 239  (-17%)  │
│        Mercado Livre                   ↗ Abrir   │
├──────────────────────────────────────────────────┤
│                                                  │
│  [Buscar em Amazon, Americanas e mais →]         │
│                                                  │
└──────────────────────────────────────────────────┘

          │ Usuário toca no botão
          ▼ Fase 2 carrega (SerpAPI, ~1-2s)
┌──────────────────────────────────────────────────┐
│  Alternativas mais baratas                        │
│  6 resultados · 4 lojas                          │
├──────────────────────────────────────────────────┤
│  [img] Tênis Nike Air Max 270    R$ 178  (-38%)  │
│        Netshoes                        ↗ Abrir   │
│  [img] Nike Air Max Masculino    R$ 198  (-32%)  │
│        Mercado Livre                   ↗ Abrir   │  ← resultado ML mantido
│  [img] Nike Running Air          R$ 219  (-24%)  │
│        Amazon.com.br                   ↗ Abrir   │
│  [img] Nike Air Max Feminino     R$ 229  (-21%)  │
│        Americanas                      ↗ Abrir   │
│  [img] Tênis Nike Original       R$ 239  (-17%)  │
│        Mercado Livre                   ↗ Abrir   │
│  [img] Nike Air 270              R$ 255  (-12%)  │
│        Magazine Luiza                  ↗ Abrir   │
├──────────────────────────────────────────────────┤
│  ⚠️ Podem ser produtos similares, não o item exato│
└──────────────────────────────────────────────────┘
```

**Regras de merge (Fase 1 + Fase 2):**
- Resultados ML da Fase 1 permanecem visíveis após Fase 2
- SerpAPI pode trazer ML também — deduplicar por URL antes de exibir
- Ordenação final: preço crescente independente da fonte

---

## Banco de dados Supabase — tabela de cache

```sql
create table price_search_cache (
  query        text primary key,
  results      jsonb not null,
  cached_at    timestamptz not null default now()
);

-- Limpeza automática de entradas antigas (opcional, via pg_cron)
-- delete from price_search_cache where cached_at < now() - interval '24 hours';
```

---

## Quando o SerpAPI não é chamado (economia de chamadas)

| Situação | Comportamento |
|---|---|
| Fase 1 encontrou resultado ≥ 40% mais barato | SerpAPI disponível mas não exibido em destaque |
| Mesma query buscada nas últimas 6h | Cache → SerpAPI **não é chamado** |
| Usuário não toca em "Buscar em mais lojas" | SerpAPI **jamais é chamado** |
| App offline | Fase 2 retorna erro silencioso; resultados da Fase 1 permanecem |
| `SERPAPI_KEY` não configurada | Fase 2 desabilitada; botão oculto |

---

## Pré-requisitos

| Item | Ação |
|---|---|
| Conta SerpAPI (free) | Criar em serpapi.com |
| `SERPAPI_KEY` no Supabase | Dashboard → Edge Functions → Secrets |
| Supabase CLI | `supabase --version` para verificar |
| Task 19 implementada | Orquestrador e fontes diretas devem existir |

---

## Arquivos a criar/modificar

| Arquivo | Ação |
|---|---|
| `lib/core/services/price_search/serp_api_source.dart` | **Criar** — fonte SerpAPI |
| `lib/core/services/price_search/price_search_orchestrator.dart` | Adicionar `searchExternal` + `SerpApiSource` |
| `lib/features/items/presentation/providers/price_search_provider.dart` | Adicionar `externalPriceSearchProvider` |
| `lib/features/items/presentation/pages/item_detail_page.dart` | Adicionar Fase 2 no bottom sheet |
| `supabase/functions/price-search/index.ts` | **Criar** — Edge Function com cache + filtro de domínios |
| Supabase Dashboard | Criar tabela `price_search_cache` + secret `SERPAPI_KEY` |

---

## Critérios de aceitação

- [ ] Botão "Buscar em Amazon, Americanas e mais" aparece após Fase 1
- [ ] SerpAPI só é chamado quando usuário toca nesse botão
- [ ] Resultados ML da Fase 2 são deduplicados com os da Fase 1
- [ ] Domínios cobertos por fontes diretas não aparecem nos resultados SerpAPI
- [ ] Cache de 6h evita chamadas repetidas para a mesma query
- [ ] Badge com nome da loja visível em cada resultado
- [ ] Falha de rede ou SerpAPI indisponível não quebra a Fase 1
- [ ] API key nunca exposta no código do app Flutter (apenas na Edge Function)
- [ ] Botão "Buscar em mais lojas" oculto quando `SERPAPI_KEY` não configurada
