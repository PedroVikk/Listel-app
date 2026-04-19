-- Adiciona suporte a gerenciamento de amigos no Listel
-- Tabelas: friends, friend_requests
-- RLS policies para privacidade de dados

-- 1. Tabela de amigos (bidirectional friendship)
create table if not exists friends (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  friend_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamp with time zone default now(),

  -- Garante que user_id != friend_id e evita duplicatas
  unique(user_id, friend_id),
  constraint no_self_friend check (user_id != friend_id)
);

-- 2. Tabela de solicitações de amizade
create table if not exists friend_requests (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid not null references auth.users(id) on delete cascade,
  to_user_id uuid not null references auth.users(id) on delete cascade,
  status text default 'pending' check (status in ('pending', 'accepted', 'rejected')),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),

  -- Evita múltiplos pedidos entre os mesmos usuários
  unique(from_user_id, to_user_id),
  constraint no_self_request check (from_user_id != to_user_id)
);

-- 3. Índices para performance
create index if not exists idx_friends_user_id on friends(user_id);
create index if not exists idx_friends_friend_id on friends(friend_id);
create index if not exists idx_friend_requests_from_user on friend_requests(from_user_id);
create index if not exists idx_friend_requests_to_user on friend_requests(to_user_id);
create index if not exists idx_friend_requests_status on friend_requests(status) where status = 'pending';

-- 4. Habilitar RLS
alter table friends enable row level security;
alter table friend_requests enable row level security;

-- 5. RLS Policies para friends

-- Usuários podem ler amigos deles mesmos
create policy "Users can view their own friends"
  on friends
  for select
  using (auth.uid() = user_id OR auth.uid() = friend_id);

-- Usuários podem criar amizades (ambos os lados registram)
create policy "Users can create friendships"
  on friends
  for insert
  with check (auth.uid() = user_id OR auth.uid() = friend_id);

-- Usuários podem deletar amizades deles mesmos
create policy "Users can delete their friendships"
  on friends
  for delete
  using (auth.uid() = user_id OR auth.uid() = friend_id);

-- 6. RLS Policies para friend_requests

-- Usuários podem ver solicitações enviadas para eles ou que eles enviaram
create policy "Users can view their friend requests"
  on friend_requests
  for select
  using (auth.uid() = from_user_id OR auth.uid() = to_user_id);

-- Usuários podem criar solicitações
create policy "Users can create friend requests"
  on friend_requests
  for insert
  with check (auth.uid() = from_user_id);

-- Usuários podem aceitar/rejeitar solicitações para eles
create policy "Users can update requests to them"
  on friend_requests
  for update
  using (auth.uid() = to_user_id)
  with check (auth.uid() = to_user_id);

-- Usuários podem deletar solicitações deles
create policy "Users can delete their requests"
  on friend_requests
  for delete
  using (auth.uid() = from_user_id OR auth.uid() = to_user_id);
