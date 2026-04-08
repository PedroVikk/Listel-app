# Listel — Bug Fix Log
> Registro de todos os bugs corrigidos durante o desenvolvimento.
> Sempre que corrigir um bug, adicione uma entrada aqui.

---

## Como adicionar uma entrada

```
### [DATA] Título curto do bug
**Arquivo(s):** `caminho/do/arquivo.dart`
**Sintoma:** O que o usuário via / o que não funcionava.
**Causa raiz:** Por que acontecia.
**Correção:** O que foi mudado e por quê funciona agora.
```

---

## Entradas

---

### 2026-04-06 — Toggle "comprado" não funcionava (listagem e detalhe do item)

**Arquivo(s):** `lib/features/items/data/repositories/items_repository_impl.dart`

**Sintoma:** Clicar em "Marcar como comprado" / "Marcar como pendente" na listagem de itens e na tela de detalhe do item não tinha efeito visual — o status nunca mudava.

**Causa raiz:** O método `save()` chamava `SavedItemModel.fromDomain(item)`, que cria um novo objeto com `isarId = Isar.autoIncrement`. Ao chamar `put()` com `isarId` autoincrement, o Isar tenta **inserir** um novo registro em vez de atualizar o existente. Como o campo `id` (UUID) tem `@Index(unique: true)`, o Isar lançava `IsarError: Unique constraint violated` — erro silenciosamente engolido pelo `onPressed` fire-and-forget.

**Correção:** Antes de salvar, busca o registro existente pelo `id` (UUID) para recuperar seu `isarId` real e reutilizá-lo no modelo. Assim o `put()` faz um update real.

```dart
// items_repository_impl.dart — método save()
final existing = await _db.savedItemModels.where().idEqualTo(item.id).findFirst();
final model = SavedItemModel.fromDomain(item);
if (existing != null) model.isarId = existing.isarId;
await _db.writeTxn(() => _db.savedItemModels.put(model));
```

---

### 2026-04-06 — Overflow e erro RLS na página "Entrar em uma lista"

**Arquivo(s):**
- `lib/features/sharing/presentation/pages/join_collection_page.dart`
- `lib/features/sharing/data/repositories/supabase_sharing_repository_impl.dart`

**Sintoma 1:** Ao focar o campo de código de convite, o teclado estoura o layout com "BOTTOM OVERFLOWED BY 19 PIXELS".

**Causa raiz 1:** `Column` sem scroll dentro de `Padding` fixo — mesmo padrão do bug do share sheet.

**Correção 1:** Substituído `Padding` externo por `SingleChildScrollView(padding: ...)`.

**Sintoma 2:** Ao confirmar um código válido, exibe `PostgrestException: new row violates row-level security policy (USING expression) for table "collection_members", code: 42501`.

**Causa raiz 2:** `upsert` envia `INSERT ... ON CONFLICT DO UPDATE`. O `DO UPDATE` aciona a policy `USING` (SELECT) do RLS. Como o usuário ainda não é membro, o RLS não retorna a linha conflitante e bloqueia a operação.

**Correção 2:** Substituído `upsert` por `insert` simples. Se o usuário já for membro (chave duplicada, código `23505`), o erro é silenciado — comportamento idempotente sem acionar o `ON CONFLICT DO UPDATE` problemático.

---

### 2026-04-06 — Detalhe do item vazio em listas compartilhadas

**Arquivo(s):** `lib/features/items/presentation/pages/item_detail_page.dart`

**Sintoma:** Ao abrir uma lista compartilhada e clicar em um item, a tela de detalhe abria em branco (ou "Item não encontrado").

**Causa raiz:** O `_itemByIdProvider` sempre buscava o item via `itemsRepositoryProvider` (Isar local). Itens de listas compartilhadas só existem no Supabase (`shared_items`), então `getById` retornava `null` e a tela não exibia nada.

**Correção:** O provider agora tenta o repositório local primeiro; se não encontrar (`null`), faz fallback para `remoteItemsRepositoryProvider` (Supabase). O stream de atualizações também vem do repositório onde o item foi encontrado.

---

### 2026-04-06 — Bottom sheet "Salvar produto" estoura quando teclado abre

**Arquivo(s):** `lib/features/share_intent/presentation/pages/share_received_page.dart`

**Sintoma:** Ao focar o campo de preço (ou nome), o teclado abria e o bottom sheet exibia "BOTTOM OVERFLOWED BY 49 PIXELS" — conteúdo cortado com listras pretas/amarelas.

**Causa raiz:** O widget raiz era `Padding(viewInsets.bottom) → Column(mainAxisSize: min)`. O `Padding` empurra o `Column` para cima pelo tamanho do teclado, mas o `Column` não tem como rolar — os filhos ficam presos fora da área visível.

**Correção:** Substituído o `Padding` externo por `SingleChildScrollView(padding: viewInsets.bottom)`. O `isScrollControlled: true` já estava no `showModalBottomSheet`, então o sheet pode ocupar a tela toda e o `SingleChildScrollView` rola o conteúdo quando necessário.

---

### 2026-04-06 — Sessão anterior: bugs nas listas compartilhadas (Supabase)

**Arquivo(s):** `lib/features/sharing/data/repositories/supabase_sharing_repository_impl.dart`, `lib/core/router/app_router.dart`, `lib/features/sharing/presentation/pages/create_shared_collection_page.dart`, `lib/features/share_intent/presentation/pages/share_received_page.dart`

**Sintoma (múltiplos):**
- `getMembers` falhava com PGRST200 (FK inexistente no Supabase).
- Ao criar lista compartilhada, `context.go` eliminava a pilha de navegação.
- Listas compartilhadas não apareciam no seletor de pasta do share intent.
- `collection_detail_page` ficava vazia logo após criar uma lista compartilhada (race condition de RLS).

**Causa raiz / Correção (resumo):**
- `getMembers`: FK entre `collection_members` e `profiles` não existe → duas queries separadas em vez de join PostgREST.
- Navegação pós-criação: substituído `context.go` por `context.pushReplacement` para manter histórico.
- Share intent: `collectionsStreamProvider` só retornava locais → mesclado com `sharedCollectionsStreamProvider`.
- Race condition RLS: passa o objeto `Collection` via `extra:` na navegação para evitar depender da stream enquanto o INSERT assíncrono termina.

---

### 2026-04-07 — Troca de ícone do launcher não funcionava

**Arquivo(s):** `android/app/src/main/kotlin/com/wishnesita/wish_nesita/MainActivity.kt`

**Sintoma:** Ao selecionar uma variante de ícone nas configurações, o app fechava mas o ícone no launcher não mudava ao retornar.

**Causa raiz 1 — ordem não determinística no loop:** `setAppIcon()` usava `HashMap.forEach` para habilitar/desabilitar todos os aliases de uma vez. `HashMap` não garante ordem de iteração. Se o Android matava o processo no meio do loop e o alias ativo havia sido desabilitado antes de o novo ser habilitado, o launcher ficava sem nenhum alias ativo — o ícone desaparecia ou ficava travado no estado anterior.

**Correção 1:** Reestruturado para habilitar o novo alias **primeiro** em chamada separada, depois desabilitar os demais em loop. Assim mesmo se o app for morto no meio, sempre há ao menos um alias ativo.

**Causa raiz 2 — `getActiveIcon()` ignorava estado `DEFAULT`:** Antes da primeira troca, todos os aliases estão em `COMPONENT_ENABLED_STATE_DEFAULT` (valor do manifesto). O método comparava apenas com `COMPONENT_ENABLED_STATE_ENABLED`, então nunca encontrava nenhum e retornava `"default"` sem checar o manifesto — a UI mostrava sempre "Padrão" selecionado mesmo após a troca.

**Correção 2:** Adicionado fallback que consulta `ActivityInfo.enabled` para aliases em estado `DEFAULT`, identificando corretamente qual o manifesto declara como ativo.

---

### 2026-04-07 — Código de convite sempre retornava "inválido ou expirado"

**Arquivo(s):**
- `lib/features/sharing/data/repositories/supabase_sharing_repository_impl.dart`
- Supabase: nova função RPC `join_shared_collection`

**Sintoma:** Ao inserir um código de convite válido na tela "Entrar em uma lista", o app exibia sempre "Código de convite inválido ou expirado".

**Causa raiz:** A policy de SELECT do RLS em `shared_collections` exige que o usuário já seja membro da coleção. Um usuário tentando entrar pelo código ainda não é membro, então o SELECT direto (`eq('invite_code', ...).maybeSingle()`) era bloqueado e retornava `null`.

**Correção:** Substituído o SELECT direto por uma chamada RPC (`join_shared_collection`) com `SECURITY DEFINER`, que executa fora do contexto do RLS. A função no Supabase faz o SELECT por `invite_code` e o INSERT em `collection_members` (`ON CONFLICT DO NOTHING` para idempotência) numa única operação segura.
