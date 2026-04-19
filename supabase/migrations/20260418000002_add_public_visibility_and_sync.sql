-- Phase 1: Public/Private Visibility + Sync Tracking
-- Adiciona suporte a listas públicas/privadas e rastreamento de sincronização para ISAR cache

-- 1. Adiciona coluna is_public à shared_collections
alter table shared_collections
  add column if not exists is_public boolean default false;

-- 2. Adiciona timestamp de sincronização
alter table shared_collections
  add column if not exists synced_at timestamp with time zone default now();

-- 3. Índice para queries de coleções públicas por owner
create index if not exists idx_shared_collections_public_owner
  on shared_collections (owner_id, is_public)
  where is_public = true;

-- 4. Índice para queries de coleções do usuário (privadas + públicas)
create index if not exists idx_shared_collections_owner
  on shared_collections (owner_id);

-- 5. Drop todas as políticas antigas (se existirem) e recreia com suporte a public
drop policy if exists "Users can view own collections" on shared_collections;
drop policy if exists "Users can create own collections" on shared_collections;
drop policy if exists "Users can update own collections" on shared_collections;
drop policy if exists "Users can delete own collections" on shared_collections;

-- 6. POLÍTICAS RLS PARA shared_collections

-- Política: usuários podem ler suas próprias coleções (privadas + públicas)
create policy "Users can read own collections"
  on shared_collections
  for select
  using (auth.uid() = owner_id);

-- Política: qualquer pessoa autenticada pode ler coleções públicas
create policy "Anyone authenticated can read public collections"
  on shared_collections
  for select
  using (is_public = true);

-- Política: usuários podem criar suas próprias coleções
create policy "Users can create own collections"
  on shared_collections
  for insert
  with check (auth.uid() = owner_id);

-- Política: usuários podem atualizar suas próprias coleções
create policy "Users can update own collections"
  on shared_collections
  for update
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- Política: usuários podem deletar suas próprias coleções
create policy "Users can delete own collections"
  on shared_collections
  for delete
  using (auth.uid() = owner_id);

-- 7. POLÍTICAS RLS PARA shared_items (herdam visibilidade da coleção)

-- Drop políticas antigas de shared_items
drop policy if exists "Users can view items in own collections" on shared_items;
drop policy if exists "Users can view items in shared collections" on shared_items;
drop policy if exists "Users can create items in own collections" on shared_items;
drop policy if exists "Users can update items in own collections" on shared_items;
drop policy if exists "Users can delete items in own collections" on shared_items;

-- Política: usuários podem ler itens em coleções que têm acesso (próprias ou públicas)
create policy "Users can read accessible collection items"
  on shared_items
  for select
  using (
    exists (
      select 1 from shared_collections
      where shared_collections.id = shared_items.collection_id
        and (
          auth.uid() = shared_collections.owner_id
          or shared_collections.is_public = true
        )
    )
  );

-- Política: usuários podem criar itens apenas em suas coleções
create policy "Users can create items in own collections"
  on shared_items
  for insert
  with check (
    exists (
      select 1 from shared_collections
      where shared_collections.id = shared_items.collection_id
        and auth.uid() = shared_collections.owner_id
    )
  );

-- Política: usuários podem editar itens apenas em suas coleções
create policy "Users can update items in own collections"
  on shared_items
  for update
  using (
    exists (
      select 1 from shared_collections
      where shared_collections.id = shared_items.collection_id
        and auth.uid() = shared_collections.owner_id
    )
  );

-- Política: usuários podem deletar itens apenas em suas coleções
create policy "Users can delete items in own collections"
  on shared_items
  for delete
  using (
    exists (
      select 1 from shared_collections
      where shared_collections.id = shared_items.collection_id
        and auth.uid() = shared_collections.owner_id
    )
  );
