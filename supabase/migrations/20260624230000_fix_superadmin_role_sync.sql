create or replace function public.is_superadmin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and (
        lower(coalesce(role, '')) in ('superadmin', 'super_admin')
        or lower(coalesce(role_type, '')) in ('superadmin', 'super_admin')
      )
  );
$$;

update public.profiles
set
  role = case
    when lower(coalesce(role_type, '')) in ('superadmin', 'super_admin') then 'superadmin'
    when lower(coalesce(role_type, '')) = 'admin' then 'admin'
    else role
  end,
  role_type = case
    when lower(coalesce(role_type, '')) in ('superadmin', 'super_admin') then 'super_admin'
    when lower(coalesce(role_type, '')) = 'admin' then 'admin'
    when lower(coalesce(role_type, '')) = 'customer' then 'customer'
    when lower(coalesce(role, '')) = 'superadmin' then 'super_admin'
    when lower(coalesce(role, '')) = 'admin' then 'admin'
    else coalesce(nullif(role_type, ''), 'customer')
  end
where
  lower(coalesce(role_type, '')) in ('superadmin', 'super_admin', 'admin', 'customer')
  or lower(coalesce(role, '')) in ('superadmin', 'admin');
