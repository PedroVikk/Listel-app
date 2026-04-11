
# Tarefa 27 — Arrastar para reordenar itens

**Status:** ❌ Não implementado  
**Prioridade:** Média  

---

## Problema

Não há ordem explícita de itens dentro de uma coleção. O usuário não consegue priorizar quais itens são mais importantes sem editar nomes com prefixos como "1.", "2.".

---

## O que precisa ser feito

### 1. Adicionar campo `sortOrder` na entidade e modelos
**Arquivo:** `lib/features/items/domain/entities/saved_item.dart`
```dart
final int sortOrder; // default: 0
```

**Arquivo:** `lib/features/items/data/models/saved_item_model.dart`
```dart
int sortOrder = 0;
```
- **Após alterar o modelo Isar, rodar:** `dart run build_runner build --delete-conflicting-outputs`

**Supabase:** Adicionar coluna `sort_order INTEGER DEFAULT 0` na tabela de itens remotos.

### 2. Atualizar repositórios para respeitar a ordem
**Arquivo:** `lib/features/items/data/repositories/items_repository_impl.dart`
- Ordenar query Isar por `sortOrder` ascending

**Arquivo:** `lib/features/items/data/repositories/remote_items_repository_impl.dart`
- Adicionar `.order('sort_order')` na query Supabase

### 3. Método `reorder` nos repositórios
**Interface:** `lib/features/items/domain/repositories/items_repository.dart`
```dart
Future<void> reorder(List<String> orderedIds);
```
- Implementar em ambos os repos: atualiza `sortOrder` de cada item com base no índice na lista

### 4. UI com `ReorderableListView`
**Arquivo:** `lib/features/items/presentation/pages/items_page.dart`
- Substituir `ListView` por `ReorderableListView`
- No callback `onReorder`: chamar `ItemsNotifier.reorder(newOrderedIds)`
- Modo de reordenação ativo apenas quando lista não está filtrada/ordenada por outro critério

---

## Arquivos envolvidos

| Arquivo | Ação |
|---|---|
| `lib/features/items/domain/entities/saved_item.dart` | Adicionar `sortOrder` |
| `lib/features/items/data/models/saved_item_model.dart` | Adicionar campo Isar |
| `lib/features/items/domain/repositories/items_repository.dart` | Método `reorder` |
| `lib/features/items/data/repositories/items_repository_impl.dart` | Implementar `reorder` (Isar) |
| `lib/features/items/data/repositories/remote_items_repository_impl.dart` | Implementar `reorder` (Supabase) |
| `lib/features/items/presentation/providers/items_provider.dart` | Método no notifier |
| `lib/features/items/presentation/pages/items_page.dart` | `ReorderableListView` |
| Supabase SQL | Coluna `sort_order` na tabela de itens |

---

## Observações

- Novos itens criados recebem `sortOrder = currentMaxOrder + 1`
- Em listas compartilhadas, a reordenação é pessoal (cada membro tem sua ordem) ou global (todos veem a mesma ordem) — definir comportamento antes de implementar
- `build_runner` obrigatório após mudar o modelo Isar
