-- Adiciona coluna sort_order à tabela shared_items para suportar reordenação de itens em listas compartilhadas.
alter table shared_items
  add column if not exists sort_order int default 0;

-- Índice para melhorar performance de ordenação
create index if not exists shared_items_collection_sort_idx
  on shared_items (collection_id, sort_order);
