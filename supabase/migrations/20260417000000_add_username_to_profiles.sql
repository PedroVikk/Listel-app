-- Adiciona coluna username (@) em profiles para suportar sistema de amizades.
-- Formato esperado: 3-20 chars, começa com letra minúscula, [a-z0-9_].

alter table profiles
  add column if not exists username text;

-- Unicidade case-insensitive: índice único sobre lower(username).
create unique index if not exists profiles_username_unique_idx
  on profiles (lower(username))
  where username is not null;

-- Constraint de formato.
alter table profiles
  drop constraint if exists profiles_username_format;

alter table profiles
  add constraint profiles_username_format
  check (
    username is null
    or username ~ '^[a-z][a-z0-9_]{2,19}$'
  );
