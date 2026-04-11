---
dominio: Pesquisa Global
tags: [search, busca, pesquisa, items, ilike, debounce, search-page]
depende-de: [itens]
afeta: []
atualizado: 2026-04-10
status: mapeado
instrucao-para-agentes: |
  Leia este arquivo quando sua tarefa envolver a funcionalidade de busca de itens por nome.
---

# Domínio: Pesquisa Global

## Visão geral

A pesquisa global permite ao usuário buscar itens por nome em todas as coleções (locais e compartilhadas). A busca é insensível a maiúsculas/minúsculas, com debounce de 500ms para evitar chamadas excessivas. Cada resultado exibe o nome do item e a coleção à qual pertence.

## Fluxo principal

1. Usuário toca ícone de busca (`Icons.search`) no AppBar da `HomePage`
2. `SearchPage` abre com `TextField` em autofocus no AppBar
3. Usuário digita query
4. Após 500ms de inatividade (debounce), `searchResultsProvider` é atualizado
5. Lista exibe resultados: thumbnail + nome do item + nome da coleção
6. Usuário toca resultado → navega para detalhe do item

## Regras de negócio

### RN-SEARCH-001: Debounce de 500ms
- **Descrição**: A busca só é executada após 500ms sem digitação, para evitar chamadas a cada tecla
- **Condição**: Ao digitar no campo de busca da `SearchPage`
- **Ação**: Timer de 500ms; ao expirar, atualiza `searchQueryProvider` → dispara `searchResultsProvider`
- **Exceções**: Nenhuma
- **Exemplo**: Usuário digita "head" rapidamente → busca não é feita; para de digitar → 500ms → busca por "head"

### RN-SEARCH-002: Busca case-insensitive
- **Descrição**: A busca ignora diferença entre maiúsculas e minúsculas
- **Condição**: Sempre
- **Ação**: Isar usa `nameContains` case-insensitive; Supabase usa `ilike`
- **Exceções**: Nenhuma
- **Exemplo**: Buscar "HEAD" retorna "Headphone Sony"

### RN-SEARCH-003: Busca em todas as coleções
- **Descrição**: A busca inclui itens de coleções locais (Isar) e compartilhadas (Supabase)
- **Condição**: Sempre que query não está vazia
- **Ação**: `searchByName()` chamado em ambos os repositórios; resultados mesclados
- **Exceções**: ⚠️ A VALIDAR — comportamento exato da mesclagem entre repos local e remoto

### RN-SEARCH-004: Query vazia não executa busca
- **Descrição**: Se o campo de busca estiver vazio, nenhuma chamada ao repositório é feita e a lista de resultados fica vazia
- **Condição**: `searchQueryProvider` com string vazia
- **Ação**: `searchResultsProvider` retorna `[]` sem consultar o banco
- **Exceções**: Nenhuma
- **Exemplo**: Usuário abre `SearchPage` → lista vazia; digita e apaga tudo → lista vazia novamente

### RN-SEARCH-005: Resultado exibe nome da coleção
- **Descrição**: Cada item no resultado da busca deve exibir a qual coleção pertence
- **Condição**: Ao renderizar resultados
- **Ação**: UI exibe `item.name` + nome da coleção correspondente ao `item.collectionId`
- **Exceções**: Nenhuma
- **Exemplo**: Busca por "tênis" → resultado "Tênis Nike — coleção Esportes"

## Casos especiais e exceções globais

- A `SearchPage` usa `autofocus: true` no TextField — teclado abre automaticamente ao entrar na tela

## Limites e parâmetros

| Parâmetro | Valor | Observação |
|---|---|---|
| Debounce | 500ms | Via `Timer` no estado da `SearchPage` |
| Método Isar | `nameContains` | Case-insensitive nativo |
| Método Supabase | `ilike` | Case-insensitive no PostgreSQL |

## Perguntas em aberto

- [ ] A busca é feita em outros campos além do nome (ex: observações, link)?
- [ ] Existe paginação nos resultados ou retorna tudo?
- [ ] Resultado ao tocar navega para detalhe do item ou para a coleção?
