# Glossário — Listel

## Entidades principais

- **Coleção** (`Collection`): Agrupador lógico de itens. Possui nome, emoji (legado), foto de capa (`coverImagePath`), e flag `isShared`. Armazenada no Isar (local) ou Supabase (compartilhada).

- **Item** (`SavedItem`): Produto ou desejo dentro de uma coleção. Campos: `id`, `name`, `price` (nullable), `imageUrl` (foto local), `url` (link externo), `notes`, `status`, `collectionId`.

- **Status**: Enum de dois valores — `pendente` (não adquirido) e `comprado` (adquirido). Alterado via toggle.

- **PriceAlternative**: Resultado de busca de preço. Contém `title`, `price`, `url`, `thumbnailUrl`, `source` (nome da loja), `percentDiff` (diferença percentual em relação ao preço do item).

## Padrões arquiteturais

- **Dual-mode repository**: Padrão central onde a interface `ItemsRepository` é implementada por `ItemsRepositoryImpl` (Isar local) e `RemoteItemsRepositoryImpl` (Supabase). O provider `_collectionIsSharedProvider` decide qual usar.

- **Feature-first**: Código organizado por feature em `lib/features/` — `collections/`, `items/`, `sharing/`, etc.

- **isShared**: Campo booleano na entidade `Collection` e no Isar. Quando `true`, operações de leitura/escrita de itens vão para o Supabase.

## Autenticação e compartilhamento

- **Invite code**: String de 8 caracteres gerada ao criar uma lista compartilhada. Armazenada em `shared_collections.invite_code`. Usada para outros usuários entrarem via deep link ou digitação manual.

- **Deep link**: URL no formato `wishnesita://invite?code=XXXXXXXX` que abre o app diretamente na tela de entrada por código de convite.

- **RLS (Row Level Security)**: Políticas do PostgreSQL no Supabase que controlam visibilidade de dados. Ex: usuário só vê itens de coleções das quais é membro.

- **SECURITY DEFINER**: Função PL/pgSQL que roda com permissões do owner, contornando RLS. Usada na RPC `join_shared_collection`.

- **JWT**: Token de autenticação do Supabase. Expira em ~1h. Canais Realtime com JWT expirado lançam `RealtimeSubscribeException(channelError, InvalidJWTToken)`.

## Busca de preço

- **PriceSource**: Interface abstrata implementada por cada fonte de preços (Mercado Livre, SerpAPI).

- **PriceSearchOrchestrator**: Executa todas as fontes `PriceSource` em paralelo (Fase 1) e delega à `SerpApiSource` sob demanda (Fase 2).

- **coveredDomains**: Set de domínios já cobertos pela Fase 1. Passado para a Fase 2 para evitar duplicatas.

- **Fase 1**: Busca direta nas APIs públicas (Mercado Livre, sem chave de API).

- **Fase 2**: Busca via Edge Function Supabase que consulta SerpAPI (Google Shopping BR). Ativada manualmente pelo usuário ("Buscar em mais lojas").

- **price_search_cache**: Tabela Supabase com cache de 6h dos resultados da Fase 2. PK: query text.

## Persistência

- **Isar**: Banco local NoSQL usado para coleções e itens locais. Migração automática de schema.

- **Supabase**: Backend-as-a-Service usado para auth, banco remoto PostgreSQL, Realtime e Edge Functions.

- **Documents/collection_covers/**: Diretório local onde fotos de capa de coleções são salvas após crop.
