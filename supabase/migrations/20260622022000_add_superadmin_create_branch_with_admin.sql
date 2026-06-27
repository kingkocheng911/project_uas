create or replace function public.superadmin_create_branch_with_admin(
  p_code text,
  p_name text,
  p_phone text default null,
  p_email text default null,
  p_address text default null,
  p_province text default null,
  p_city text default null,
  p_district text default null,
  p_postal_code text default null,
  p_is_active boolean default true,
  p_admin_full_name text default null,
  p_admin_email text default null,
  p_admin_password text default null,
  p_admin_phone text default null
)
returns table (
  branch_id uuid,
  branch_code text,
  branch_name text,
  admin_user_id uuid,
  admin_email text
)
language plpgsql
security definer
set search_path = public, auth, extensions
as $$
declare
  v_now timestamptz := now();
  v_branch_id uuid;
  v_admin_user_id uuid;
  v_admin_branch_assignment_id uuid;
  v_admin_email text;
begin
  if not public.is_superadmin() then
    raise exception 'Akses ditolak. Hanya superadmin yang dapat membuat cabang.';
  end if;

  if nullif(trim(coalesce(p_code, '')), '') is null then
    raise exception 'Kode cabang wajib diisi.';
  end if;

  if nullif(trim(coalesce(p_name, '')), '') is null then
    raise exception 'Nama cabang wajib diisi.';
  end if;

  if nullif(trim(coalesce(p_address, '')), '') is null then
    raise exception 'Alamat cabang wajib diisi.';
  end if;

  insert into public.branches (
    code,
    name,
    phone,
    email,
    address,
    province,
    city,
    district,
    postal_code,
    is_active,
    opened_at,
    updated_at
  )
  values (
    trim(p_code),
    trim(p_name),
    nullif(trim(coalesce(p_phone, '')), ''),
    nullif(lower(trim(coalesce(p_email, ''))), ''),
    trim(p_address),
    nullif(trim(coalesce(p_province, '')), ''),
    nullif(trim(coalesce(p_city, '')), ''),
    nullif(trim(coalesce(p_district, '')), ''),
    nullif(trim(coalesce(p_postal_code, '')), ''),
    coalesce(p_is_active, true),
    v_now,
    v_now
  )
  returning id into v_branch_id;

  if nullif(trim(coalesce(p_admin_email, '')), '') is not null and
     nullif(trim(coalesce(p_admin_password, '')), '') is not null then
    select user_id, branch_admin_id, email
    into v_admin_user_id, v_admin_branch_assignment_id, v_admin_email
    from public.superadmin_upsert_branch_admin_credentials(
      v_branch_id,
      trim(p_admin_email),
      trim(p_admin_password),
      p_admin_full_name,
      p_admin_phone,
      'branch_admin',
      true
    )
    limit 1;
  end if;

  return query
  select
    v_branch_id,
    trim(p_code),
    trim(p_name),
    v_admin_user_id,
    coalesce(v_admin_email, nullif(lower(trim(coalesce(p_admin_email, ''))), ''));
end;
$$;
<<<<<<< HEAD

=======
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
grant execute on function public.superadmin_create_branch_with_admin(
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  text,
  boolean,
  text,
  text,
  text,
  text
) to authenticated;
