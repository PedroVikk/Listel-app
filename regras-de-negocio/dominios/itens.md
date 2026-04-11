---
dominio: Itens
tags: [item, wishlist, saved-item, isar, supabase, dual-mode, status, comprado, pendente]
depende-de: [listas-compartilhadas]
afeta: [busca-de-preco, pesquisa-global]
atualizado: 2026-04-10
status: mapeado
instrucao-para-agentes: |
  Leia este arquivo quando sua tarefa envolver criar, editar, mover, excluir ou exibir itens.
  Para entender como o roteamento local/remoto funciona, leia regras/dual-mode-repository.md.
  Para busca de preço, leia dominios/busca-de-preco.md.
---

# Domínio: Itens

## Visão geral

Itens são os produtos ou desejos dentro de uma coleção. Podem ser criados manualmente (formulário) ou via compartilhamento de URL (scraping de metadados). Cada item tem nome, preço, foto, link, observações e status (pendente/comprado). O repositório de itens opera em dois modos: local (Isar) para coleções locais e remoto (Supabase) para coleções compartilhadas.

## Fluxo principal (criação manual)

1. Usuário abre uma coleção e toca "Adicionar item"
2. `CreateItemPage` exibe formulário: nome, preço, foto, link, observações
3. Usuário preenche campos e confirma
4. `ItemsNotifier.createManual()` aguarda `_repoAsync` para obter o repositório correto
5. Item é salvo no Isar (local) ou Supabase (compartilhado) conforme `isShared`
6. Lista da coleção atualiza em tempo real

## Fluxo alternativo (via compartilhamento/URL)

1. Usuário compartilha URL de produto para o app (intent Android/iOS)
2. App faz scraping da URL para extrair nome, preço e imagem
3. `CreateItemPage` pré-popula o formulário com os dados extraídos
4. Usuário confirma ou edita e salva

## Regras de negócio

### RN-ITEM-001: Nome é obrigatório
- **Descrição**: Todo item deve ter um nome não vazio
- **Condição**: Ao salvar (criar ou editar)
- **Ação**: Bloquear salvamento
- **Exceções**: Nenhuma
- **Exemplo**: Campo nome vazio → botão salvar desabilitado

### RN-ITEM-002: Preço é opcional
- **Descrição**: O campo `price` é nullable — item pode ser salvo sem preço
- **Condição**: Sempre
- **Ação**: Se `price == null`, botão "Buscar mais barato" não é exibido na tela de detalhe
- **Exceções**: Nenhuma
- **Exemplo**: Item "Livro X" sem preço → sem botão de busca de preço

### RN-ITEM-003: Roteamento dual-mode (local vs remoto)
- **Descrição**: Toda operação de item (criar, ler, atualizar, deletar) deve usar o repositório correto baseado em `isShared` da coleção
- **Condição**: Antes de qualquer operação no `ItemsNotifier`
- **Ação**: `_repoAsync` aguarda `_collectionIsSharedProvider` (FutureProvider) resolver → usa `ItemsRepositoryImpl` (Isar) se `false`, `RemoteItemsRepositoryImpl` (Supabase) se `true`
- **Exceções**: ⚠️ Durante `AsyncLoading`, operações aguardam — nunca vão para Isar como fallback
- **Exemplo**: Abrir coleção compartilhada → todos os creates/reads/deletes vão para Supabase

### RN-ITEM-004: Toggle de status
- **Descrição**: O usuário pode alternar o status do item entre `pendente` e `comprado`
- **Condição**: Em qualquer item, em qualquer coleção
- **Ação**: `ItemsNotifier.toggleStatus()` inverte o status e persiste no repositório correto
- **Exceções**: Nenhuma
- **Exemplo**: Tocar no checkbox de "Headphone Sony" → status muda de `pendente` para `comprado`

### RN-ITEM-005: Mover item entre coleções
- **Descrição**: Um item pode ser movido de uma coleção para outra
- **Condição**: Coleção de destino deve existir; ambas devem ser do mesmo tipo (local→local ou remoto→remoto)
- **Ação**: `ItemsNotifier.moveToCollection()` atualiza `collectionId` e persiste
- **Exceções**: ⚠️ A VALIDAR — comportamento ao mover entre coleção local e compartilhada não está documentado
- **Exemplo**: Mover "Tênis Nike" de "Roupas" para "Esportes"

### RN-ITEM-006: Foto do item é local
- **Descrição**: A foto do item (`imageUrl`) é um path local no dispositivo, não uma URL remota
- **Condição**: Ao exibir foto de item
- **Ação**: Usar `Image.file()` com o path; em listas compartilhadas, cada membro tem sua própria cópia local da foto
- **Exceções**: Itens criados via scraping de URL podem ter `imageUrl` como URL http(s) — tratar com `Image.network()`
- **Exemplo**: Item criado manualmente com foto da galeria → `imageUrl = /data/user/0/.../abc.jpg`

### RN-ITEM-007: Link (URL) do item
- **Descrição**: O campo `url` permite salvar o link do produto junto ao item
- **Condição**: Opcional; exibido na tela de detalhe do item
- **Ação**: Ao tocar no link, lançar `url_launcher` em modo externo
- **Exceções**: Nenhuma
- **Exemplo**: Item com `url = "https://amazon.com/produto"` → botão "Abrir link" na tela de detalhe

### RN-ITEM-008: Exclusão de item
- **Descrição**: Excluir item remove do repositório correto (Isar ou Supabase)
- **Condição**: Usuário confirma exclusão
- **Ação**: `ItemsNotifier.delete()` aguarda repo correto e remove
- **Exceções**: Foto local do item não é deletada automaticamente — ⚠️ A VALIDAR
- **Exemplo**: Excluir "Cafeteira" da coleção compartilhada → removido do Supabase para todos os membros

## Casos especiais e exceções globais

- `_collectionIsSharedProvider` era síncrono e causava race condition (bug corrigido em 2026-04-08): durante `AsyncLoading`, itens iam para Isar mesmo sendo de coleção compartilhada. Agora é `FutureProvider.family` que aguarda o stream.

## Limites e parâmetros

| Parâmetro | Valor | Observação |
|---|---|---|
| `url` (link) | máx 500 chars | Validado no TextField |
| `price` | double nullable | Sem validação de mínimo/máximo documentada |
| `notes` | string | Sem limite documentado |

## Regras detalhadas (arquivos separados)

- [`regras/dual-mode-repository.md`] — Quando acessar: ao implementar qualquer operação que precise decidir entre Isar e Supabase

## Perguntas em aberto

- [ ] Qual o comportamento ao mover item de coleção local para compartilhada (e vice-versa)?
- [ ] A foto local do item é deletada ao excluir o item?
- [ ] Existe limite de itens por coleção?
