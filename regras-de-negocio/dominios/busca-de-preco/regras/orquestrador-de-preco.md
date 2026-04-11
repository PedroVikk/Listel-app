---
dominio: Busca de Preço
regra-id: RN-PRECO-ORCH
tags: [orchestrator, price-source, fase1, fase2, mercadolivre, serpapi, covered-domains, parallel]
atualizado: 2026-04-10
instrucao-para-agentes: |
  Leia este arquivo SOMENTE se sua tarefa envolver adicionar nova PriceSource, alterar a lógica de orquestração ou debugar o fluxo de busca de preços.
  Pré-requisito: ter lido dominios/busca-de-preco.md.
---

# RN-PRECO-ORCH: Orquestrador de Busca de Preço

## Descrição

O `PriceSearchOrchestrator` coordena múltiplas fontes de preço em duas fases. Fase 1 executa fontes diretas em paralelo. Fase 2 delega ao `SerpApiSource` via Edge Function, ativada manualmente.

## Interfaces e modelos

```
PriceSource (interface abstrata)
  ├── coveredDomains: Set<String>   → domínios que esta fonte já cobre
  ├── search(name, price): Future<List<PriceAlternative>>
  └── (implementações: MercadoLivreSource, SerpApiSource)

PriceAlternative (modelo)
  ├── title: String
  ├── price: double
  ├── url: String
  ├── thumbnailUrl: String?
  ├── source: String         → nome da loja (exibido na UI)
  └── percentDiff: double    → % de diferença em relação ao preço do item (negativo = mais barato)
```

## Lógica de decisão — quando usar cada fase

| Fase | Trigger | Fontes | Automático? |
|---|---|---|---|
| Fase 1 | Abertura do sheet | MercadoLivreSource (+ futuras fontes diretas) | Sim |
| Fase 2 | Toque em "Buscar em mais lojas" | SerpApiSource → Edge Function price-search | Não |

## Fluxo de execução — Fase 1

1. `directPriceSearchProvider` watched no build de `_PriceSearchSheet`
2. `PriceSearchOrchestrator.searchDirect(name, price)` chamado
3. Todas as `PriceSource` registradas executadas em paralelo via `Future.wait`
4. Resultados de todas as fontes mesclados em uma lista plana
5. Filtro: apenas `percentDiff <= -5%` (≥5% mais barato)
6. Ordenação por `price` ascendente
7. `coveredDomains` calculado: union de todos os `source.coveredDomains`
8. Resultado retornado ao `_PriceSearchSheet`

## Fluxo de execução — Fase 2

1. Usuário toca "Buscar em mais lojas →"
2. Estado `_showExternal = true`; botão muda para loading
3. `externalPriceSearchProvider` ativado com `(name, price)` como key
4. `SerpApiSource.search(name, price)` chamado com `excludeDomains = coveredDomains da Fase 1`
5. `SerpApiSource` chama `supabase.functions.invoke('price-search', body: {query, excludeDomains})`
6. Edge Function verifica cache → se miss, chama SerpAPI → salva cache → retorna resultados
7. Merge: Fase 1 resultados + Fase 2 resultados, deduplicados por URL (Set de URLs vistas)
8. Reordenação por `price` ascendente
9. Botão "Buscar em mais lojas" some; disclaimer exibido

## Como adicionar nova PriceSource (Fase 1)

1. Criar classe que implementa `PriceSource`
2. Definir `coveredDomains` (Set dos domínios que a fonte cobre)
3. Implementar `search()` com filtro de `percentDiff <= -5%`
4. Registrar no `priceSearchOrchestratorProvider`:
   ```dart
   PriceSearchOrchestrator(sources: [
     MercadoLivreSource(),
     NovaFonteSource(),  // adicionar aqui
   ])
   ```
5. Os `coveredDomains` da nova fonte serão automaticamente excluídos da Fase 2

## Exceções conhecidas

- **SerpApiSource ausente**: Se `_serpApiSource == null`, `searchExternal()` retorna `[]` silenciosamente. `hasExternalSearch` retorna `false`.
- **Falha de rede em qualquer Fase 1 source**: `catch (_)` por fonte — falha de uma não cancela as outras
- **Key SerpAPI ausente**: Edge Function retorna erro → `SerpApiSource` captura silenciosamente → `[]`

## Exemplos concretos

### Exemplo 1: Busca bem-sucedida com merge
> Item "Headphone Sony WH-1000XM5", preço R$ 1.800.
> Fase 1: MercadoLivreSource retorna 3 resultados entre R$ 1.500 e R$ 1.700 (todos ≥5% mais baratos).
> Usuário toca "Buscar em mais lojas". Fase 2: SerpApiSource retorna 5 resultados do Google Shopping (excluindo mercadolivre.com.br). Merge: 8 resultados únicos, ordenados por preço. Disclaimer exibido.

### Exemplo 2: Fase 1 vazia, Fase 2 com resultados
> Item "Câmera DSLR Nikon", preço R$ 3.000.
> Fase 1: Nenhum resultado no Mercado Livre ≥5% mais barato. UI exibe "Nenhum resultado no Mercado Livre."
> Usuário toca "Buscar em mais lojas". Fase 2: 4 resultados do Google Shopping.
> Merge: 4 resultados. Texto muda para "Produtos encontrados nas lojas pesquisadas."

### Exemplo 3: Ambas fases vazias
> Nenhum resultado em nenhuma fonte. UI exibe "Nenhum resultado encontrado nas lojas pesquisadas." (texto dinâmico ativado após Fase 2).

## Referências

- Orquestrador: `lib/core/services/price_search/price_search_orchestrator.dart`
- Interface: `lib/core/services/price_search/price_source.dart`
- MercadoLivreSource: `lib/core/services/price_search/mercado_livre_source.dart`
- SerpApiSource: `lib/core/services/price_search/serp_api_source.dart`
- Providers: `lib/core/services/price_search/price_search_provider.dart`
- Edge Function: `supabase/functions/price-search/index.ts`
- Relacionada a: RN-PRECO-001 a RN-PRECO-010
