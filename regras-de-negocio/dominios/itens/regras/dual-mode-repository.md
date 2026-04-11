---
dominio: Itens
regra-id: RN-ITEM-003
tags: [dual-mode, isar, supabase, isShared, repositorio, race-condition]
atualizado: 2026-04-10
instrucao-para-agentes: |
  Leia este arquivo SOMENTE se sua tarefa envolver operações de item que precisam decidir entre Isar (local) e Supabase (remoto).
  Pré-requisito: ter lido dominios/itens.md.
---

# RN-ITEM-003: Dual-Mode Repository

## Descrição

Toda operação de item (criar, ler, atualizar, deletar) deve ser roteada para o repositório correto — Isar (local) para coleções locais, Supabase (remoto) para coleções compartilhadas — com base no campo `isShared` da coleção.

## Pré-condições

- A coleção já deve existir (local ou remota)
- O stream de coleções compartilhadas (`sharedCollectionsStreamProvider`) deve ter carregado

## Lógica de decisão

| `isShared` | Repositório usado | Onde os dados ficam |
|---|---|---|
| `false` | `ItemsRepositoryImpl` | Isar (local, no dispositivo) |
| `true` | `RemoteItemsRepositoryImpl` | Supabase (remoto, sincronizado) |
| `AsyncLoading` | Nenhum — aguarda | Operação bloqueada até resolver |

## Fluxo de execução

1. `ItemsNotifier` é criado com `_repoAsync: Future<ItemsRepository>`
2. Qualquer método (`createManual`, `toggleStatus`, `delete`, etc.) inicia com `final repo = await _repoAsync`
3. `_repoAsync` é resolvido pelo `_collectionIsSharedProvider` (FutureProvider.family)
4. `_collectionIsSharedProvider` faz `await ref.watch(sharedCollectionsStreamProvider.future)` — aguarda o stream carregar
5. Verifica se `collectionId` está na lista de coleções compartilhadas
6. Retorna `true` (Supabase) ou `false` (Isar)
7. Provider correto é instanciado e a operação prossegue

## Exceções conhecidas

- **Race condition (corrigida 2026-04-08)**: `_collectionIsSharedProvider` era síncrono — durante `AsyncLoading`, `valueOrNull == null` → `isShared = false` → todos os writes iam para Isar mesmo sendo coleção compartilhada. Fix: convertido para `FutureProvider.family`.
- **JWT expirado em Realtime**: Canais Realtime com JWT antigo lançam `RealtimeSubscribeException`. Fix: retry automático com `auth.refreshSession()` após 5s (em `remote_items_repository_impl.dart`).

## Exemplos concretos

### Exemplo 1: Criar item em coleção local
> Usuário na coleção "Eletrônicos" (local). `isShared = false`. `createManual()` aguarda `_repoAsync` → retorna `ItemsRepositoryImpl` → item salvo no Isar local.

### Exemplo 2: Criar item em coleção compartilhada
> Usuário na coleção "Lista de Casamento" (compartilhada). `isShared = true`. `createManual()` aguarda `_repoAsync` → retorna `RemoteItemsRepositoryImpl` → item salvo no Supabase → Realtime notifica outros membros.

### Exemplo 3: App recém-aberto (AsyncLoading)
> Stream de coleções compartilhadas ainda carregando. `ItemsNotifier.createManual()` chamado. `_repoAsync` está pendente. Operação aguarda (não vai para Isar). Stream resolve → `isShared` determinado → operação continua corretamente.

## Referências

- Implementação: `lib/features/items/presentation/providers/items_provider.dart`
- Repositório local: `lib/features/items/data/repositories/items_repository_impl.dart`
- Repositório remoto: `lib/features/items/data/repositories/remote_items_repository_impl.dart`
- Relacionada a: RN-COMP-001 (Listas Compartilhadas — stream de coleções)
