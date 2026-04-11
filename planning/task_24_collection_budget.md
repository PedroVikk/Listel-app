# Tarefa 24 — Total do orçamento por coleção

**Status:** ❌ Não implementado  
**Prioridade:** Alta  

---

## Problema

O usuário não tem como saber o valor total dos itens de uma coleção sem somar manualmente. Isso limita o uso do app para planejamento de compras.

---

## O que precisa ser feito

### 1. Computed value no provider de itens
**Arquivo:** `lib/features/items/presentation/providers/items_provider.dart`
- Adicionar `collectionBudgetProvider` — `Provider.family<CollectionBudget, String>` keyed por `collectionId`
- `CollectionBudget` contém:
  - `totalPending` — soma dos preços de itens com `status == pending`
  - `totalPurchased` — soma dos preços de itens com `status == purchased`
  - `totalAll` — soma de todos os itens
  - `itemsWithoutPrice` — count de itens sem preço definido

### 2. Modelo `CollectionBudget`
**Arquivo:** `lib/features/items/domain/entities/collection_budget.dart`
```dart
class CollectionBudget {
  final double totalPending;
  final double totalPurchased;
  final double totalAll;
  final int itemsWithoutPrice;
}
```

### 3. UI na tela de detalhes da coleção
**Arquivo:** `lib/features/items/presentation/pages/items_page.dart` (ou similar)
- Exibir card de resumo no topo da lista de itens:
  - "Total pendente: R$ 1.250,00"
  - "Já comprado: R$ 380,00"
  - Se houver itens sem preço: "3 itens sem preço definido"
- Card colapsável para não poluir a UI

---

## Arquivos envolvidos

| Arquivo | Ação |
|---|---|
| `lib/features/items/domain/entities/collection_budget.dart` | Nova entidade |
| `lib/features/items/presentation/providers/items_provider.dart` | Novo provider `collectionBudgetProvider` |
| `lib/features/items/presentation/pages/items_page.dart` | UI do card de orçamento |

---

## Observações

- Itens com `price == null` devem ser ignorados no cálculo mas contados separadamente
- Funciona para coleções locais e compartilhadas (mesmo provider, já usa dual-mode)
- Formatar valores com `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')`
