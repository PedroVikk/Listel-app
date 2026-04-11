# Tarefa 28 — Sair e remover membros de lista compartilhada

**Status:** ❌ Não implementado  
**Prioridade:** Média  

---

## Problema

Perguntas em aberto no domínio de listas compartilhadas:
- É possível sair de uma lista compartilhada?
- O dono pode remover membros?
- O que acontece com a lista se o dono sair?

Sem isso, listas compartilhadas acumulam membros indefinidamente e não há como corrigir convites enviados para pessoas erradas.

---

## Decisões de negócio (definir antes de implementar)

- [ ] Membro comum pode sair da lista a qualquer momento?
- [ ] Dono pode remover qualquer membro?
- [ ] Se o dono sair: a lista é deletada ou transferida para outro membro?
- [ ] Ao sair, os itens adicionados pelo membro são mantidos ou deletados?

---

## O que precisa ser feito

### 1. RPC Supabase: `leave_shared_collection`
- Deleta o registro em `collection_members` para o `user_id` + `collection_id` informados
- Usar `SECURITY DEFINER` para garantir que o próprio usuário pode deletar seu registro (RLS pode bloquear DELETE)
- Se o usuário for o dono e não houver outros membros: deletar a `shared_collection` inteira

### 2. RPC Supabase: `remove_member` (apenas dono)
- Valida que o `caller_id` é o dono da coleção (`created_by`)
- Deleta o registro em `collection_members` para o `target_user_id`

### 3. Método no repositório
**Arquivo:** `lib/features/sharing/domain/repositories/sharing_repository.dart`
```dart
Future<void> leaveSharedCollection(String collectionId);
Future<void> removeMember(String collectionId, String userId);
```

**Arquivo:** `lib/features/sharing/data/repositories/supabase_sharing_repository_impl.dart`
- Implementar chamando as RPCs acima

### 4. Método no notifier
**Arquivo:** `lib/features/sharing/presentation/providers/sharing_provider.dart`
- `SharingNotifier.leave(String collectionId)` — chama `leaveSharedCollection`, invalida `sharedCollectionsStreamProvider`
- `SharingNotifier.removeMember(String collectionId, String userId)` — apenas para dono

### 5. UI
**Tela de membros da lista compartilhada:**
- Botão "Sair da lista" visível para todos os membros (exceto dono — ou com confirmação especial)
- Dono vê botão "Remover" ao lado de cada membro (exceto si mesmo)
- Dialog de confirmação antes de qualquer ação destrutiva

---

## Arquivos envolvidos

| Arquivo | Ação |
|---|---|
| Supabase SQL | RPCs `leave_shared_collection` e `remove_member` |
| `lib/features/sharing/domain/repositories/sharing_repository.dart` | Novos métodos |
| `lib/features/sharing/data/repositories/supabase_sharing_repository_impl.dart` | Implementação das RPCs |
| `lib/features/sharing/presentation/providers/sharing_provider.dart` | Métodos no notifier |
| `lib/features/sharing/presentation/pages/members_page.dart` | UI de sair/remover |

---

## Observações

- Invalidar `sharedCollectionsStreamProvider` após sair para remover a lista da home imediatamente
- Caso o dono saia e haja outros membros: considerar transferir ownership para o membro mais antigo
- RLS deve impedir que um membro comum delete registros de outros membros — usar SECURITY DEFINER nas RPCs
