-- Adiciona coluna avatar_url em profiles para armazenar URL do avatar no Supabase Storage.

alter table profiles
  add column if not exists avatar_url text;
