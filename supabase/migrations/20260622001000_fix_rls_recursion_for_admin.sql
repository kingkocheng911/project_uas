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
      and role in ('superadmin', 'super_admin')
  );
$$;
create or replace function public.is_branch_admin(target_branch_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_superadmin()
    or exists (
      select 1
      from public.branch_admins
      where user_id = auth.uid()
        and branch_id = target_branch_id
        and is_active = true
    );
$$;
