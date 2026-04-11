create table app_versions (
  id           serial primary key,
  version      text    not null,
  version_code int     not null,
  download_url text    not null,
  release_notes text,
  force_update  boolean default false,
  created_at   timestamptz default now()
);

-- Acesso público de leitura (app não autenticado precisa checar versão)
alter table app_versions enable row level security;

create policy "public read app_versions"
  on app_versions for select
  using (true);
