---
dominio: Busca de Preço
tags: [price-search, mercadolivre, serpapi, google-shopping, edge-function, cache, orchestrator]
depende-de: [itens]
afeta: []
atualizado: 2026-04-10
status: mapeado
instrucao-para-agentes: |
  Leia este arquivo quando sua tarefa envolver comparação de preços, busca em lojas, SerpAPI ou Edge Function price-search.
  Para a lógica de orquestração detalhada, acesse regras/orquestrador-de-preco.md.
---

# Domínio: Busca de Preço

## Visão geral

Quando o usuário visualiza um item com nome e preço definidos, pode solicitar uma busca de alternativas mais baratas. A busca opera em duas fases: Fase 1 (fontes diretas, sem chave) e Fase 2 (SerpAPI via Edge Function Supabase, ativada manualmente). Apenas resultados ≥5% mais baratos são exibidos.

## Fluxo principal

1. Usuário abre `ItemDetailPage` — item tem `name` e `price` não nulos
2. Botão "Buscar mais barato" é exibido
3. Usuário toca o botão → `_PriceSearchSheet` (DraggableScrollableSheet) abre
4. Fase 1 inicia automaticamente: `directPriceSearchProvider` consulta todas as `PriceSource` diretas em paralelo
5. Resultados da Fase 1 exibidos ordenados por preço (≥5% mais barato)
6. Usuário pode tocar "Buscar em mais lojas →" para ativar Fase 2
7. Fase 2: `externalPriceSearchProvider` chama `SerpApiSource` → Edge Function `price-search`
8. Resultados da Fase 2 mesclados com Fase 1, deduplicados por URL e reordenados por preço
9. Disclaimer "Podem ser produtos similares" exibido após Fase 2 concluída

## Regras de negócio

### RN-PRECO-001: Botão de busca visível somente com nome e preço
- **Descrição**: O botão "Buscar mais barato" só aparece quando `item.price != null && item.name.isNotEmpty`
- **Condição**: Em `ItemDetailPage`
- **Ação**: Condicional na UI — sem preço ou sem nome, botão não é renderizado
- **Exceções**: Nenhuma
- **Exemplo**: Item "Headphone" sem preço → sem botão; item "Headphone" com preço R$300 → botão visível

### RN-PRECO-002: Filtro de desconto mínimo 5%
- **Descrição**: Somente resultados com preço ≥5% mais barato que o preço do item são retornados
- **Condição**: Em todas as fontes (Fase 1 e Fase 2)
- **Ação**: `MercadoLivreSource` filtra na busca; Edge Function filtra antes de retornar
- **Exceções**: Nenhuma
- **Exemplo**: Item custa R$300; resultado a R$285 (5%) é incluído; resultado a R$295 (1,7%) é excluído

### RN-PRECO-003: Fase 1 executa automaticamente ao abrir o sheet
- **Descrição**: A busca no Mercado Livre (e outras fontes diretas) inicia assim que o sheet de preços é aberto, sem interação do usuário
- **Condição**: Sempre que `_PriceSearchSheet` é exibido
- **Ação**: `directPriceSearchProvider` é watched no build — dispara automaticamente
- **Exceções**: Nenhuma

### RN-PRECO-004: Fase 2 ativada manualmente
- **Descrição**: A busca via SerpAPI só é executada quando o usuário toca "Buscar em mais lojas →"
- **Condição**: Fase 1 já concluída (ou em curso)
- **Ação**: Estado `_showExternal` muda para `true`; `externalPriceSearchProvider` é ativado; botão muda para loading e depois some
- **Exceções**: Se `SerpApiSource` não estiver configurado (key ausente), retorna lista vazia silenciosamente
- **Exemplo**: Usuário toca "Buscar em mais lojas" → botão vira loading → resultados do Google Shopping aparecem mesclados

### RN-PRECO-005: Deduplicação por URL
- **Descrição**: Ao mesclar Fase 1 + Fase 2, resultados com a mesma URL são deduplicados (Fase 1 tem prioridade)
- **Condição**: Após Fase 2 concluída
- **Ação**: Merge com Set de URLs vistas; reordenação por preço
- **Exceções**: Nenhuma

### RN-PRECO-006: Cache de 6h para Fase 2
- **Descrição**: Resultados da Edge Function são cacheados por 6h na tabela `price_search_cache` (PK: query text)
- **Condição**: Toda chamada à Edge Function `price-search`
- **Ação**: Edge Function verifica cache antes de chamar SerpAPI; se cache válido, retorna cached; filtro de preço reaplicado na leitura
- **Exceções**: Cache miss ou expirado → nova chamada ao SerpAPI
- **Exemplo**: Query "Headphone Sony" pesquisada às 10h → cache até 16h → segunda pesquisa às 14h usa cache

### RN-PRECO-007: Máximo de 8 resultados na Fase 2
- **Descrição**: A Edge Function retorna no máximo 8 resultados após filtragem
- **Condição**: Sempre
- **Ação**: Ordenados por preço, limitados a 8
- **Exceções**: Nenhuma

### RN-PRECO-008: coveredDomains evita duplicatas entre fases
- **Descrição**: A Fase 2 recebe o set `coveredDomains` da Fase 1 e exclui esses domínios do Google Shopping
- **Condição**: Ao instanciar `SerpApiSource`
- **Ação**: `excludeDomains` passado para a Edge Function via `supabase.functions.invoke`
- **Exceções**: `SerpApiSource.coveredDomains` retorna `{}` — ela própria não cobre domínios específicos
- **Exemplo**: Mercado Livre já cobre `mercadolivre.com.br` → Fase 2 exclui esse domínio do Google Shopping

### RN-PRECO-009: Falha de rede na Fase 2 é silenciosa
- **Descrição**: Erros de rede ou chave ausente na `SerpApiSource` nunca quebram a Fase 1 nem a UI
- **Condição**: Qualquer exceção em `SerpApiSource`
- **Ação**: `catch (_)` → retorna `[]`
- **Exceções**: Nenhuma
- **Exemplo**: SerpAPI fora do ar → "Buscar em mais lojas" não exibe erro; só não retorna resultados

### RN-PRECO-010: Disclaimer após Fase 2
- **Descrição**: O texto "Podem ser produtos similares" só é exibido após a Fase 2 ser concluída
- **Condição**: `_showExternal == true && Fase 2 carregada`
- **Ação**: Exibir disclaimer abaixo dos resultados
- **Exceções**: Fase 2 retorna vazio → disclaimer ainda exibido (resultados são similares por natureza)

## Casos especiais e exceções globais

- Texto do estado vazio muda dinamicamente: "Nenhum resultado no Mercado Livre." → "Nenhum resultado encontrado nas lojas pesquisadas." quando Fase 2 também está vazia
- `http://` em thumbnails do Mercado Livre → substituído por `https://` para evitar bloqueio Android

## Limites e parâmetros

| Parâmetro | Valor | Observação |
|---|---|---|
| Desconto mínimo | 5% | Aplicado em todas as fontes |
| Máx resultados Fase 2 | 8 | Após filtro, ordenados por preço |
| Cache Fase 2 | 6 horas | Tabela `price_search_cache`, PK: query text |
| Engine SerpAPI | Google Shopping BR | `gl=br`, `hl=pt` |

## Regras detalhadas (arquivos separados)

- [`regras/orquestrador-de-preco.md`] — Quando acessar: ao implementar nova `PriceSource` ou alterar a lógica de orquestração

## Perguntas em aberto

- [ ] Qual o comportamento quando `SERPAPI_KEY` não está configurada no Supabase?
- [ ] Existe throttling ou limite de chamadas à Edge Function por usuário?
