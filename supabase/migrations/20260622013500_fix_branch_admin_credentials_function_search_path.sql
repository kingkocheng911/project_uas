create or replace function public._system_upsert_branch_admin_account(
  p_branch_id uuid,
  p_email text,
  p_password text,
  p_full_name text default null,
  p_phone text default null,
  p_admin_role text default 'branch_admin',
  p_is_primary boolean default true
)
returns table (
  user_id uuid,
  branch_admin_id uuid,
  email text,
  full_name text
)
language plpgsql
security definer
set search_path = public, auth, extensions
as $function$
declare
  v_now timestamptz := now();
  v_branch_name text;
  v_normalized_email text := lower(trim(coalesce(p_email, '')));
  v_normalized_password text := trim(coalesce(p_password, ''));
  v_full_name text;
  v_phone text := nullif(trim(coalesce(p_phone, '')), '');
  v_user_id uuid;
  v_existing_user_id uuid;
  v_assignment_id uuid;
begin
  if p_branch_id is null then
    raise exception 'Branch wajib dipilih.';
  end if;

  select b.name
  into v_branch_name
  from public.branches b
  where b.id = p_branch_id;

  if v_branch_name is null then
    raise exception 'Cabang tidak ditemukan.';
  end if;

  if v_normalized_email = '' then
    raise exception 'Email admin cabang wajib diisi.';
  end if;

  if v_normalized_password = '' then
    raise exception 'Password admin cabang wajib diisi.';
  end if;

  if length(v_normalized_password) < 6 then
    raise exception 'Password minimal 6 karakter.';
  end if;

  v_full_name := coalesce(
    nullif(trim(coalesce(p_full_name, '')), ''),
    'Admin ' || v_branch_name
  );

  select u.id
  into v_existing_user_id
  from auth.users u
  where lower(coalesce(u.email, '')) = v_normalized_email
    and u.deleted_at is null
  limit 1;

  if v_existing_user_id is not null then
    if exists (
      select 1
      from public.branch_admins ba
      where ba.user_id = v_existing_user_id
        and ba.branch_id <> p_branch_id
        and ba.is_active = true
    ) then
      raise exception 'Email ini sudah dipakai oleh admin cabang aktif lain.';
    end if;

    v_user_id := v_existing_user_id;
  else
    v_user_id := gen_random_uuid();

    insert into auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      invited_at,
      confirmation_token,
      confirmation_sent_at,
      recovery_token,
      recovery_sent_at,
      email_change_token_new,
      email_change,
      email_change_sent_at,
      last_sign_in_at,
      raw_app_meta_data,
      raw_user_meta_data,
      is_super_admin,
      created_at,
      updated_at,
      phone,
      phone_confirmed_at,
      email_change_token_current,
      email_change_confirm_status,
      reauthentication_token,
      is_sso_user,
      is_anonymous
    )
    values (
      '00000000-0000-0000-0000-000000000000',
      v_user_id,
      'authenticated',
      'authenticated',
      v_normalized_email,
      crypt(v_normalized_password, gen_salt('bf')),
      v_now,
      null,
      '',
      null,
      '',
      null,
      '',
      '',
      null,
      null,
      jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
      jsonb_build_object(
        'avatar_url', '__initials__',
        'email', v_normalized_email,
        'email_verified', true,
        'full_name', v_full_name,
        'phone', v_phone,
        'phone_verified', false,
        'role', 'admin',
        'role_type', 'admin',
        'sub', v_user_id::text
      ),
      false,
      v_now,
      v_now,
      null,
      null,
      '',
      0,
      '',
      false,
      false
    );

    insert into auth.identities (
      id,
      user_id,
      identity_data,
      provider,
      provider_id,
      last_sign_in_at,
      created_at,
      updated_at
    )
    values (
      gen_random_uuid(),
      v_user_id,
      jsonb_build_object(
        'avatar_url', '__initials__',
        'email', v_normalized_email,
        'email_verified', true,
        'full_name', v_full_name,
        'phone', v_phone,
        'phone_verified', false,
        'role', 'admin',
        'role_type', 'admin',
        'sub', v_user_id::text
      ),
      'email',
      v_user_id::text,
      v_now,
      v_now,
      v_now
    );
  end if;

  update auth.users
  set email = v_normalized_email,
      encrypted_password = crypt(v_normalized_password, gen_salt('bf')),
      email_confirmed_at = coalesce(email_confirmed_at, v_now),
      raw_app_meta_data = jsonb_build_object(
        'provider', 'email',
        'providers', jsonb_build_array('email')
      ),
      raw_user_meta_data = jsonb_build_object(
        'avatar_url', '__initials__',
        'email', v_normalized_email,
        'email_verified', true,
        'full_name', v_full_name,
        'phone', v_phone,
        'phone_verified', false,
        'role', 'admin',
        'role_type', 'admin',
        'sub', v_user_id::text
      ),
      updated_at = v_now
  where id = v_user_id;

  if exists (
    select 1
    from auth.identities i
    where i.user_id = v_user_id
      and i.provider = 'email'
  ) then
    update auth.identities
    set identity_data = jsonb_build_object(
          'avatar_url', '__initials__',
          'email', v_normalized_email,
          'email_verified', true,
          'full_name', v_full_name,
          'phone', v_phone,
          'phone_verified', false,
          'role', 'admin',
          'role_type', 'admin',
          'sub', v_user_id::text
        ),
        provider_id = v_user_id::text,
        updated_at = v_now
    where auth.identities.user_id = v_user_id
      and auth.identities.provider = 'email';
  else
    insert into auth.identities (
      id,
      user_id,
      identity_data,
      provider,
      provider_id,
      last_sign_in_at,
      created_at,
      updated_at
    )
    values (
      gen_random_uuid(),
      v_user_id,
      jsonb_build_object(
        'avatar_url', '__initials__',
        'email', v_normalized_email,
        'email_verified', true,
        'full_name', v_full_name,
        'phone', v_phone,
        'phone_verified', false,
        'role', 'admin',
        'role_type', 'admin',
        'sub', v_user_id::text
      ),
      'email',
      v_user_id::text,
      v_now,
      v_now,
      v_now
    );
  end if;

  insert into public.profiles (
    id,
    full_name,
    phone,
    avatar_url,
    role,
    role_type,
    default_branch_id,
    is_active,
    updated_at
  )
  values (
    v_user_id,
    v_full_name,
    v_phone,
    '__initials__',
    'admin',
    'admin',
    p_branch_id,
    true,
    v_now
  )
  on conflict (id) do update
  set full_name = excluded.full_name,
      phone = excluded.phone,
      avatar_url = excluded.avatar_url,
      role = 'admin',
      role_type = 'admin',
      default_branch_id = excluded.default_branch_id,
      is_active = true,
      updated_at = v_now;

  insert into public.notification_settings (user_id)
  select v_user_id
  where not exists (
    select 1
    from public.notification_settings ns
    where ns.user_id = v_user_id
  );

  update public.branch_admins
  set is_active = false,
      is_primary = false,
      revoked_at = v_now,
      updated_at = v_now
  where public.branch_admins.branch_id = p_branch_id
    and public.branch_admins.user_id <> v_user_id
    and public.branch_admins.is_active = true;

  update public.branch_admins
  set is_active = false,
      is_primary = false,
      revoked_at = v_now,
      updated_at = v_now
  where public.branch_admins.user_id = v_user_id
    and public.branch_admins.branch_id <> p_branch_id
    and public.branch_admins.is_active = true;

  update public.profiles p
  set role = 'user',
      role_type = 'customer',
      default_branch_id = null,
      updated_at = v_now
  where p.id in (
    select ba.user_id
    from public.branch_admins ba
    where ba.branch_id = p_branch_id
      and ba.user_id <> v_user_id
  )
    and not exists (
      select 1
      from public.branch_admins active_ba
      where active_ba.user_id = p.id
        and active_ba.is_active = true
    );

  select ba.id
  into v_assignment_id
  from public.branch_admins ba
  where ba.branch_id = p_branch_id
    and ba.user_id = v_user_id
  order by ba.assigned_at desc nulls last
  limit 1;

  if v_assignment_id is null then
    insert into public.branch_admins (
      branch_id,
      user_id,
      admin_role,
      is_primary,
      is_active,
      assigned_at,
      revoked_at,
      updated_at
    )
    values (
      p_branch_id,
      v_user_id,
      coalesce(nullif(trim(coalesce(p_admin_role, '')), ''), 'branch_admin'),
      p_is_primary,
      true,
      v_now,
      null,
      v_now
    )
    returning id into v_assignment_id;
  else
    update public.branch_admins
    set admin_role = coalesce(nullif(trim(coalesce(p_admin_role, '')), ''), 'branch_admin'),
        is_primary = p_is_primary,
        is_active = true,
        revoked_at = null,
        updated_at = v_now
    where id = v_assignment_id;
  end if;

  return query
  select
    v_user_id,
    v_assignment_id,
    v_normalized_email,
    v_full_name;
end;
$function$;
create or replace function public.superadmin_upsert_branch_admin_credentials(
  p_branch_id uuid,
  p_email text,
  p_password text,
  p_full_name text default null,
  p_phone text default null,
  p_admin_role text default 'branch_admin',
  p_is_primary boolean default true
)
returns table (
  user_id uuid,
  branch_admin_id uuid,
  email text,
  full_name text
)
language plpgsql
security definer
set search_path = public, auth, extensions
as $function$
begin
  if not public.is_superadmin() then
    raise exception 'Akses ditolak. Hanya superadmin yang dapat mengelola akun admin cabang.';
  end if;

  return query
  select *
  from public._system_upsert_branch_admin_account(
    p_branch_id,
    p_email,
    p_password,
    p_full_name,
    p_phone,
    p_admin_role,
    p_is_primary
  );
end;
$function$;
