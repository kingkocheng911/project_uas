do $$
declare
  v_user_id uuid := '65bc85c5-bf8b-41cd-a81b-d247efae4e91';
  v_branch_id uuid;
begin
  select id
  into v_branch_id
  from public.branches
  where code = 'KDMP-SLO-01'
  limit 1;

  if v_branch_id is null then
    raise exception 'Branch KDMP-SLO-01 not found';
  end if;

  insert into public.profiles (
    id,
    full_name,
    phone,
    avatar_url,
    role,
    role_type,
    default_branch_id,
    is_active
  )
  values (
    v_user_id,
    'Arya',
    '0833732651',
    '__initials__',
    'admin',
    'admin',
    v_branch_id,
    true
  )
  on conflict (id) do update
  set
    full_name = excluded.full_name,
    phone = excluded.phone,
    avatar_url = excluded.avatar_url,
    role = 'admin',
    role_type = 'admin',
    default_branch_id = excluded.default_branch_id,
    is_active = true;

  insert into public.notification_settings (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  insert into public.branch_admins (
    branch_id,
    user_id,
    admin_role,
    is_primary,
    is_active
  )
  values (
    v_branch_id,
    v_user_id,
    'branch_admin',
    true,
    true
  )
  on conflict do nothing;
end $$;
