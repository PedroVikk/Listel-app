-- RPC para buscar sugestões de amigos
-- Retorna usuários que ainda não são amigos, ordenados por amigos em comum

create or replace function get_friend_suggestions(
  user_id uuid,
  limit_count int default 6,
  offset_count int default 0
)
returns table(
  profile jsonb,
  mutual_friends_count bigint,
  is_in_contacts bool
)
language sql
as $$
  select
    to_jsonb(p) as profile,
    (
      select count(*)
      from friends f1
      where f1.user_id = user_id
        and f1.friend_id in (
          select f2.friend_id
          from friends f2
          where f2.user_id = profiles.id and f2.friend_id != user_id
        )
    ) as mutual_friends_count,
    false as is_in_contacts
  from profiles p
  where p.id != user_id
    and p.id not in (
      select friend_id from friends where user_id = get_friend_suggestions.user_id
    )
    and p.id not in (
      select to_user_id from friend_requests where from_user_id = get_friend_suggestions.user_id
    )
  order by
    mutual_friends_count desc,
    p.created_at desc
  limit limit_count offset offset_count;
$$ strict security definer;

-- Grant acesso a usuários autenticados
grant execute on function get_friend_suggestions(uuid, int, int) to authenticated;
