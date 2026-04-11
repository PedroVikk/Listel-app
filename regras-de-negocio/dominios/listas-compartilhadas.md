---
dominio: Listas Compartilhadas
tags: [sharing, supabase, realtime, invite-code, deep-link, rls, jwt, membros, colaborativo]
depende-de: [autenticacao, colecoes]
afeta: [itens]
atualizado: 2026-04-10
status: mapeado
instrucao-para-agentes: |
  Leia este arquivo quando sua tarefa envolver criação/entrada em listas compartilhadas, convites, membros, sincronização Realtime ou RLS.
  Para a lógica de roteamento de itens local vs remoto, leia dominios/itens/regras/dual-mode-repository.md.
  Para regras detalhadas de RLS e Realtime, acesse as pastas regras/ deste domínio.
---

# Domínio: Listas Compartilhadas

## Visão geral

Listas compartilhadas permitem que dois ou mais usuários colaborem em tempo real em uma wishlist. São armazenadas no Supabase (PostgreSQL + Realtime). O acesso é controlado por RLS. Usuários entram via código de convite (8 chars) ou deep link. Cada membro vê e edita os mesmos itens em tempo real.

## Fluxo principal (criar lista compartilhada)

1. Usuário autenticado acessa `CreateSharedCollectionPage`
2. Preenche nome e opcionalmente foto de capa (crop quadrado)
3. `SharingNotifier.createSharedCollection()` cria registro em `shared_collections` no Supabase
4. Um `invite_code` de 8 chars é gerado e armazenado
5. App salva registro no Isar local com `isShared: true` e `id = remoteId` (para lookup de foto)
6. Coleção aparece na seção de listas compartilhadas da `HomePage`

## Fluxo alternativo (entrar em lista via convite)

1. Usuário recebe código de 8 chars ou deep link `wishnesita://invite?code=XXXXXXXX`
2. App abre tela de entrada por código
3. `SharingNotifier.joinByInviteCode()` chama RPC `join_shared_collection` no Supabase
4. RPC executa com `SECURITY DEFINER` (contorna RLS): faz SELECT em `shared_collections` + INSERT em `collection_members`
5. Após join bem-sucedido, `ref.invalidate(sharedCollectionsStreamProvider)` força re-fetch
6. Lista aparece para o novo membro sem reiniciar o app

## Regras de negócio

### RN-COMP-001: Usuário deve estar autenticado
- **Descrição**: Criar ou entrar em lista compartilhada exige usuário logado no Supabase
- **Condição**: Ao acessar qualquer funcionalidade de compartilhamento
- **Ação**: Redirecionar para tela de login se não autenticado
- **Exceções**: Nenhuma
- **Exemplo**: Usuário não logado toca "Nova lista compartilhada" → redirecionado para login

### RN-COMP-002: Invite code é único e imutável
- **Descrição**: Cada lista compartilhada tem um `invite_code` de 8 chars gerado na criação; nunca é alterado
- **Condição**: Ao criar lista compartilhada
- **Ação**: Gerar código único; armazenar em `shared_collections.invite_code`
- **Exceções**: Nenhuma
- **Exemplo**: Lista criada com código `AB12CD34` — sempre será `AB12CD34`

### RN-COMP-003: Join via RPC SECURITY DEFINER
- **Descrição**: A entrada por código de convite usa RPC `join_shared_collection` com SECURITY DEFINER para contornar RLS — novo membro ainda não tem acesso direto à tabela
- **Condição**: Ao chamar `joinByInviteCode()`
- **Ação**: `supabase.rpc('join_shared_collection', params: {'code': inviteCode})` — SELECT + INSERT em `collection_members` com `ON CONFLICT DO NOTHING`
- **Exceções**: Código inválido → RPC retorna erro; app exibe mensagem ao usuário
- **Exemplo**: Usuário digita código → RPC valida e insere membro → lista aparece sem reiniciar

### RN-COMP-004: Invalidar stream após join
- **Descrição**: Após join bem-sucedido, o stream de coleções compartilhadas deve ser invalidado para forçar re-fetch com RLS atualizado
- **Condição**: Imediatamente após `joinByInviteCode()` retornar sem erro
- **Ação**: `ref.invalidate(sharedCollectionsStreamProvider)`
- **Exceções**: Nenhuma
- **Exemplo**: Sem invalidate, a lista não aparecia para o novo membro sem reiniciar o app (bug corrigido 2026-04-08)

### RN-COMP-005: Stream de membros em tempo real
- **Descrição**: A lista de membros de uma coleção compartilhada é um stream Realtime — atualiza automaticamente quando alguém entra ou sai
- **Condição**: Sempre que `membersProvider` está ativo
- **Ação**: `membersProvider` é `StreamProvider` usando `watchMembers()` → `.stream()` em `collection_members` + `.asyncMap()` para buscar profiles
- **Exceções**: Nenhuma
- **Exemplo**: Dono está na tela de membros → outro usuário entra pelo código → nome aparece automaticamente

### RN-COMP-006: Foto de capa persiste localmente
- **Descrição**: A foto de capa de uma lista compartilhada é armazenada localmente, não no Supabase Storage
- **Condição**: Ao exibir coleção compartilhada com foto
- **Ação**: `sharedCollectionsStreamProvider` usa `.asyncMap()` para fazer lookup no Isar por `collection.id` (= remoteId) e sobrepor `coverImagePath` antes de emitir
- **Exceções**: Outros membros não veem a foto de capa — cada um configura a sua
- **Exemplo**: Usuário A define foto para "Lista de Casamento" → apenas Usuário A vê a foto; Usuário B vê sem foto

### RN-COMP-007: Coleções compartilhadas filtradas da lista local
- **Descrição**: Coleções com `isShared == true` no Isar não aparecem na seção de coleções locais
- **Condição**: `CollectionsRepositoryImpl.watchAll()` e `getAll()`
- **Ação**: Filtro `isShared == false` na query Isar
- **Exceções**: Nenhuma
- **Exemplo**: Usuário tem 2 locais + 1 compartilhada → seção local mostra 2; seção compartilhada mostra 1

### RN-COMP-008: Retry automático em JWT expirado
- **Descrição**: Canais Realtime com JWT expirado (~1h) lançam `RealtimeSubscribeException(channelError, InvalidJWTToken)`. O app deve fazer retry automático.
- **Condição**: `RealtimeSubscribeException` interceptada no `onError` do `StreamController`
- **Ação**: Aguardar 5s → `auth.refreshSession()` → recriar subscription silenciosamente
- **Exceções**: Outros erros (RLS, etc.) são propagados normalmente para a UI
- **Exemplo**: App aberto por 90min → JWT expira → stream de itens compartilhados dá erro → retry automático → stream volta sem o usuário perceber

### RN-COMP-009: RLS controla visibilidade de dados
- **Descrição**: Políticas RLS no Supabase garantem que usuário só vê e modifica dados de coleções das quais é membro
- **Condição**: Todas as queries em `shared_collections`, `collection_members`, e tabela de itens remotos
- **Ação**: Supabase aplica RLS automaticamente; app não precisa filtrar manualmente
- **Exceções**: RPC `join_shared_collection` usa SECURITY DEFINER para contornar RLS apenas no momento do join
- **Exemplo**: Usuário A não consegue ver itens da lista de Usuário B se não for membro

### RN-COMP-010: Deep link abre tela de convite
- **Descrição**: Deep links no formato `wishnesita://invite?code=XXXXXXXX` devem abrir o app na tela de entrada por código, pré-preenchida com o código
- **Condição**: App instalado, deep link recebido via `app_links`
- **Ação**: `app_links` intercepta → navega para rota de join → campo de código pré-preenchido
- **Exceções**: App fechado → abre e navega; app em segundo plano → navega sem reiniciar
- **Exemplo**: Usuário A compartilha link → Usuário B toca → app abre na tela de join com código `AB12CD34`

## Casos especiais e exceções globais

- **Bug histórico (corrigido 2026-04-08)**: `sharedCollectionsStreamProvider` usa `.stream()` em `shared_collections`; a entrada de um novo membro modifica apenas `collection_members`, então o stream não recebia evento. Fix: invalidate após join.
- **Bug histórico (corrigido 2026-04-08)**: `membersProvider` era `FutureProvider` (busca única) → dono não via membros que entravam. Fix: convertido para `StreamProvider`.

## Limites e parâmetros

| Parâmetro | Valor | Observação |
|---|---|---|
| Invite code | 8 chars alfanuméricos | Imutável após criação |
| Deep link scheme | `wishnesita://` | Configurado no app e no AndroidManifest |
| JWT expiration | ~1h | Retry automático após 5s |
| Retry delay (JWT) | 5 segundos | Antes de `auth.refreshSession()` |

## Regras detalhadas (arquivos separados)

- [`regras/rls-politicas.md`] — Quando acessar: ao criar novas tabelas Supabase ou alterar políticas de acesso
- [`regras/realtime-streams.md`] — Quando acessar: ao implementar ou debugar streams Realtime

## Perguntas em aberto

- [ ] É possível sair de uma lista compartilhada? Qual o comportamento?
- [ ] O dono pode remover membros?
- [ ] O que acontece com a lista compartilhada se o dono deletar a conta?
- [ ] Existe limite de membros por lista compartilhada?
