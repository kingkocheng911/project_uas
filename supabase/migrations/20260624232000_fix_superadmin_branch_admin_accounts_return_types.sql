create or replace function public.superadmin_list_branch_admin_accounts()
returns table (
  branch_admin_id uuid,
  branch_id uuid,
  branch_name text,
  branch_code text,
  user_id uuid,
  full_name text,
  phone text,
  email text,
  admin_role text,
  is_primary boolean,
  is_active boolean
)
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.is_superadmin() then
    raise exception 'Akses ditolak. Hanya superadmin yang dapat melihat akun admin cabang.';
  end if;

  return query
  select
    ba.id,
    ba.branch_id,
    b.name::text,
    b.code::text,
    ba.user_id,
    coalesce(p.full_name, split_part(coalesce(au.email::text, ''), '@', 1))::text,
    p.phone::text,
    coalesce(au.email::text, '')::text,
    ba.admin_role::text,
    ba.is_primary,
    ba.is_active
  from public.branch_admins ba
  join public.branches b on b.id = ba.branch_id
  left join public.profiles p on p.id = ba.user_id
  left join auth.users au on au.id = ba.user_id
  where ba.is_active = true
  order by b.name, ba.is_primary desc, ba.assigned_at desc nulls last;
end;
$$;

grant execute on function public.superadmin_list_branch_admin_accounts()
to authenticated;
